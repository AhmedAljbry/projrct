/*
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '../../data/inpainting_repository.dart';
import '../../domain/inpainting_failure.dart';
import '../../domain/inpainting_status.dart';

class InpaintingController extends ChangeNotifier {
  final InpaintingRepository repo;

  InpaintingStatus status = InpaintingStatus.idle;
  InpaintingFailure? failure;
  Uint8List? resultBytes;

  bool _cancelled = false;
  bool get isBusy =>
      status == InpaintingStatus.submitting ||
          status == InpaintingStatus.polling ||
          status == InpaintingStatus.downloading;

  InpaintingController(this.repo);

  void cancel() {
    _cancelled = true;
    status = InpaintingStatus.cancelled;
    notifyListeners();
  }

  Future<void> start({
    required Uint8List image,
    required Uint8List mask,
    Duration pollInterval = const Duration(seconds: 2),
    Duration maxWait = const Duration(seconds: 120),
  }) async {
    _cancelled = false;
    failure = null;
    resultBytes = null;

    status = InpaintingStatus.submitting;
    notifyListeners();

    try {
      status = InpaintingStatus.polling;
      notifyListeners();

      final jobId = await repo.runJob(
        image: image,
        mask: mask,
        pollInterval: pollInterval,
        maxWait: maxWait,
        isCancelled: () => _cancelled,
      );

      status = InpaintingStatus.downloading;
      notifyListeners();

      resultBytes = await repo.downloadResult(jobId);
      status = InpaintingStatus.completed;
      notifyListeners();
    } on InpaintingFailure catch (f) {
      failure = f;
      status = f.code == 'timeout' ? InpaintingStatus.timeout : InpaintingStatus.failed;
      notifyListeners();
    } catch (_) {
      failure = const InpaintingFailure(code: 'unknown', messageKey: 'processing_failed');
      status = InpaintingStatus.failed;
      notifyListeners();
    }
  }
}*/
