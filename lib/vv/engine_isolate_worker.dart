import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/blemish_removal_engine.dart';
import 'package:untitled2/vv/dart_blemish_engine.dart';
import 'package:untitled2/vv/healing_region.dart';
import 'package:untitled2/vv/mask_data.dart';

enum _IsolateMessageType { heal, applyAll, dispose, progress }

class _IsolateRequest {
  final _IsolateMessageType type;
  final String requestId;
  final TransferableTypedData? imagePixels;
  final int? imageWidth;
  final int? imageHeight;
  final List<Map<String, dynamic>>? operationsJson;
  final String? qualityMode;

  const _IsolateRequest({
    required this.type,
    required this.requestId,
    this.imagePixels,
    this.imageWidth,
    this.imageHeight,
    this.operationsJson,
    this.qualityMode,
  });
}

class _IsolateResponse {
  final String requestId;
  final bool success;
  final TransferableTypedData? resultPixels;
  final Map<String, dynamic>? healedBounds;
  final double? confidence;
  final int? processingMs;
  final String? errorCode;
  final String? errorMessage;
  final int? progressCompleted;
  final int? progressTotal;

  const _IsolateResponse({
    required this.requestId,
    required this.success,
    this.resultPixels,
    this.healedBounds,
    this.confidence,
    this.processingMs,
    this.errorCode,
    this.errorMessage,
    this.progressCompleted,
    this.progressTotal,
  });
}

void _isolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  final engine = DartBlemishEngine();

  receivePort.listen((message) async {
    if (message is! _IsolateRequest) return;
    final req = message;

    switch (req.type) {
      case _IsolateMessageType.heal:
        await _handleHeal(req, mainSendPort, engine);
        break;
      case _IsolateMessageType.applyAll:
        await _handleApplyAll(req, mainSendPort, engine);
        break;
      case _IsolateMessageType.dispose:
        await engine.dispose();
        receivePort.close();
        break;
      case _IsolateMessageType.progress:
        break;
    }
  });
}

Future<void> _handleHeal(
  _IsolateRequest req,
  SendPort sendPort,
  DartBlemishEngine engine,
) async {
  try {
    final op = BlemishOperation.fromJson(req.operationsJson!.first);
    final imagePixels = req.imagePixels!.materialize().asUint8List();
    final mode = req.qualityMode == 'finalQuality'
        ? EngineQualityMode.finalQuality
        : EngineQualityMode.preview;

    final result = await engine.heal(
      imagePixels: imagePixels,
      imageWidth: req.imageWidth!,
      imageHeight: req.imageHeight!,
      operation: op,
      mode: mode,
    );

    if (result.isSuccess) {
      final h = result.healed!;
      sendPort.send(_IsolateResponse(
        requestId: req.requestId,
        success: true,
        resultPixels: TransferableTypedData.fromList([h.healedPixels]),
        healedBounds: h.bounds.toJson(),
        confidence: h.confidence,
        processingMs: h.processingTime.inMilliseconds,
      ));
      return;
    }

    sendPort.send(_IsolateResponse(
      requestId: req.requestId,
      success: false,
      errorCode: result.error!.code,
      errorMessage: result.error!.message,
    ));
  } catch (e) {
    sendPort.send(_IsolateResponse(
      requestId: req.requestId,
      success: false,
      errorCode: 'ISOLATE_ERROR',
      errorMessage: e.toString(),
    ));
  }
}

Future<void> _handleApplyAll(
  _IsolateRequest req,
  SendPort sendPort,
  DartBlemishEngine engine,
) async {
  try {
    final imagePixels = req.imagePixels!.materialize().asUint8List();
    final ops = req.operationsJson!
        .map((j) => BlemishOperation.fromJson(j))
        .toList();
    final mode = req.qualityMode == 'finalQuality'
        ? EngineQualityMode.finalQuality
        : EngineQualityMode.preview;

    final resultPixels = await engine.applyAll(
      imagePixels: imagePixels,
      imageWidth: req.imageWidth!,
      imageHeight: req.imageHeight!,
      operations: ops,
      mode: mode,
      onProgress: (completed, total) {
        sendPort.send(_IsolateResponse(
          requestId: req.requestId,
          success: true,
          progressCompleted: completed,
          progressTotal: total,
        ));
      },
    );

    sendPort.send(_IsolateResponse(
      requestId: req.requestId,
      success: true,
      resultPixels: TransferableTypedData.fromList([resultPixels]),
    ));
  } catch (e) {
    sendPort.send(_IsolateResponse(
      requestId: req.requestId,
      success: false,
      errorCode: 'APPLY_ALL_ERROR',
      errorMessage: e.toString(),
    ));
  }
}

class EngineIsolateWorker {
  Isolate? _isolate;
  SendPort? _workerPort;
  ReceivePort? _receivePort;
  final _pendingRequests = <String, Completer<_IsolateResponse>>{};
  final _progressCallbacks = <String, void Function(int, int)>{};
  bool _ready = false;

  Future<void> start() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, _receivePort!.sendPort);

    final completer = Completer<SendPort>();

    _receivePort!.listen((message) {
      if (!completer.isCompleted && message is SendPort) {
        completer.complete(message);
        return;
      }

      if (message is _IsolateResponse) {
        final isProgressOnly = message.progressCompleted != null &&
            message.progressTotal != null &&
            message.resultPixels == null &&
            message.errorCode == null;

        if (isProgressOnly) {
          _progressCallbacks[message.requestId]
              ?.call(message.progressCompleted!, message.progressTotal!);
          return;
        }

        if (message.progressCompleted != null &&
            message.progressTotal != null &&
            message.resultPixels != null) {
          _progressCallbacks[message.requestId]
              ?.call(message.progressCompleted!, message.progressTotal!);
        }

        _progressCallbacks.remove(message.requestId);
        _pendingRequests.remove(message.requestId)?.complete(message);
      }
    });

    _workerPort = await completer.future;
    _ready = true;
  }

  Future<EngineResult> heal({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required BlemishOperation operation,
    EngineQualityMode mode = EngineQualityMode.preview,
  }) async {
    _assertReady();
    final id = _newRequestId();
    final completer = Completer<_IsolateResponse>();
    _pendingRequests[id] = completer;

    _workerPort!.send(_IsolateRequest(
      type: _IsolateMessageType.heal,
      requestId: id,
      imagePixels: TransferableTypedData.fromList([imagePixels]),
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      operationsJson: [operation.toJson()],
      qualityMode: mode.name,
    ));

    final response = await completer.future;
    return _parseHealResponse(response);
  }

  Future<Uint8List> applyAll({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required List<BlemishOperation> operations,
    EngineQualityMode mode = EngineQualityMode.finalQuality,
    void Function(int completed, int total)? onProgress,
  }) async {
    _assertReady();
    final id = _newRequestId();
    final completer = Completer<_IsolateResponse>();
    _pendingRequests[id] = completer;
    if (onProgress != null) {
      _progressCallbacks[id] = onProgress;
    }

    _workerPort!.send(_IsolateRequest(
      type: _IsolateMessageType.applyAll,
      requestId: id,
      imagePixels: TransferableTypedData.fromList([imagePixels]),
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      operationsJson: operations.map((o) => o.toJson()).toList(),
      qualityMode: mode.name,
    ));

    final response = await completer.future;
    _progressCallbacks.remove(id);
    if (!response.success) {
      throw Exception('applyAll failed: ${response.errorMessage}');
    }
    return response.resultPixels!.materialize().asUint8List();
  }

  Future<void> dispose() async {
    _ready = false;
    _workerPort?.send(_IsolateRequest(
      type: _IsolateMessageType.dispose,
      requestId: 'dispose',
    ));
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _receivePort?.close();
  }

  int _reqCounter = 0;
  String _newRequestId() => 'req_${++_reqCounter}_${DateTime.now().millisecondsSinceEpoch}';

  void _assertReady() {
    if (!_ready) throw StateError('EngineIsolateWorker not started. Call start() first.');
  }

  EngineResult _parseHealResponse(_IsolateResponse r) {
    if (!r.success) {
      return EngineResult.failure(EngineError(
        code: r.errorCode ?? 'UNKNOWN',
        message: r.errorMessage ?? 'Unknown error',
      ));
    }

    final bounds = MaskBounds.fromJson(r.healedBounds!);
    return EngineResult.success(HealedRegion(
      bounds: bounds,
      healedPixels: r.resultPixels!.materialize().asUint8List(),
      confidence: r.confidence ?? 0.5,
      processingTime: Duration(milliseconds: r.processingMs ?? 0),
    ));
  }
}
