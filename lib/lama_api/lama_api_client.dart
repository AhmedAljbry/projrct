import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'lama_exceptions.dart';
import 'lama_models.dart';

/// A robust, high-performance API client for the LaMa Pro Queue API.
/// This client provides both raw task submission endpoints, as well as
/// high-level async polling to wait for processing completely on the background.
class LamaApiClient {
  final String baseUrl;
  final String apiKey;
  final http.Client _client;

  LamaApiClient({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'x-api-key': apiKey,
        // Language can be adjusted if you want arabic translations in messages
        'Accept-Language': 'en', 
      };

  /// Disposes of the underlying HTTP client. Close this when the client
  /// is no longer needed.
  void dispose() {
    _client.close();
  }

  /// Sends a raw task to the server and returns the internal `jobId`.
  Future<String> submitTask({
    required Uint8List imageBytes,
    required String imageName,
    Uint8List? maskBytes,
    String? maskName,
    required LamaTaskMode mode,
    Map<String, dynamic>? optionsJson,
    ExpandOptions? expandOptions,
    int? healRadius,
    int? edgeRadius,
  }) async {
    final uri = Uri.parse('$baseUrl/submit-task');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['mode'] = mode.value;

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName,
        contentType: MediaType('image', imageName.endsWith('.png') ? 'png' : 'jpeg'),
      ),
    );

    if (maskBytes != null && maskName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'mask',
          maskBytes,
          filename: maskName,
          contentType: MediaType('image', 'png'), // mask is strongly typed as PNG typically
        ),
      );
    }

    if (optionsJson != null) {
      request.fields['options_json'] = jsonEncode(optionsJson);
    }
    if (expandOptions != null && mode == LamaTaskMode.expandCanvas) {
      request.fields['expand_left'] = expandOptions.left.toString();
      request.fields['expand_top'] = expandOptions.top.toString();
      request.fields['expand_right'] = expandOptions.right.toString();
      request.fields['expand_bottom'] = expandOptions.bottom.toString();
      request.fields['anchor'] = expandOptions.anchor;
    }
    if (healRadius != null && mode == LamaTaskMode.healRegion) {
      request.fields['heal_radius'] = healRadius.toString();
    }
    if (edgeRadius != null && mode == LamaTaskMode.cleanEdges) {
      request.fields['edge_radius'] = edgeRadius.toString();
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    _checkResponseForErrors(response);

    final data = jsonDecode(response.body);
    if (data['ok'] == true && data['job_id'] != null) {
      return data['job_id'];
    } else {
      throw LamaExceptions('Failed to submit task: ${data['message'] ?? response.body}');
    }
  }

  /// Get the current status and progress of a job by ID.
  Future<LamaJobStatus> getStatus(String jobId) async {
    final uri = Uri.parse('$baseUrl/status/$jobId');
    final response = await _client.get(uri, headers: _headers);

    _checkResponseForErrors(response);

    final data = jsonDecode(response.body);
    if (data['ok'] == true) {
      return LamaJobStatus.fromJson(data);
    } else {
      throw LamaExceptions('Failed to get status: ${data['message']}');
    }
  }

  /// Internal method to fetch the final result image once processing is complete.
  Future<Uint8List> _fetchResult(String jobId) async {
    final uri = Uri.parse('$baseUrl/result/$jobId');
    final response = await _client.get(uri, headers: _headers);

    _checkResponseForErrors(response);

    if (response.headers['content-type']?.contains('image') ?? false) {
      return response.bodyBytes;
    } else {
       final data = jsonDecode(response.body);
       throw LamaExceptions('Result endpoint returned json instead of image: ${data['message']}');
    }
  }

  /// High level wrapper: Submits a photo task and continuously polls until completion.
  /// Throws if it times out or if the server crashes.
  /// Callbacks for visual progress reporting via [onProgress].
  Future<Uint8List> processTaskAndWait({
    required Uint8List imageBytes,
    required String imageName,
    Uint8List? maskBytes,
    String? maskName,
    required LamaTaskMode mode,
    ExpandOptions? expandOptions,
    int? healRadius,
    int? edgeRadius,
    Duration pollInterval = const Duration(seconds: 2),
    Duration timeout = const Duration(minutes: 5),
    void Function(LamaJobStatus status)? onProgress,
  }) async {
    final jobId = await submitTask(
      imageBytes: imageBytes,
      imageName: imageName,
      maskBytes: maskBytes,
      maskName: maskName,
      mode: mode,
      expandOptions: expandOptions,
      healRadius: healRadius,
      edgeRadius: edgeRadius,
    );

    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(pollInterval);
      final status = await getStatus(jobId);
      
      if (onProgress != null) {
        onProgress(status);
      }

      if (status.isCompleted) {
        return await _fetchResult(jobId);
      } else if (status.isFailed) {
        throw LamaExceptions('Job failed: ${status.error ?? status.message}');
      }
      // If queued or processing, we continue looping natively
    }

    throw LamaExceptions('Polling timeout reached for job $jobId');
  }

  void _checkResponseForErrors(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 429) {
      throw LamaRateLimitException();
    }
    if (response.statusCode == 503) {
      throw LamaServerBusyException('Server busy (503)', 503);
    }
    if (response.statusCode == 413) {
      throw LamaExceptions('File too large (413)', 413);
    }
    throw LamaExceptions('HTTP error ${response.statusCode}: ${response.body}', response.statusCode);
  }

  // =========================================================================
  // Highly-Typed Convenience Wrappers for the Requested Powerful Features
  // =========================================================================

  /// Expands canvas to add margins around the image.
  Future<Uint8List> expandCanvas({
    required Uint8List imageBytes,
    required String imageName,
    Uint8List? maskBytes,
    String? maskName,
    required ExpandOptions expandOptions,
    void Function(LamaJobStatus status)? onProgress,
  }) {
    return processTaskAndWait(
      imageBytes: imageBytes,
      imageName: imageName,
      maskBytes: maskBytes,
      maskName: maskName,
      mode: LamaTaskMode.expandCanvas,
      expandOptions: expandOptions,
      onProgress: onProgress,
    );
  }

  /// Small targeted heals, optionally expanded heavily by setting a radius.
  Future<Uint8List> healRegion({
    required Uint8List imageBytes,
    required String imageName,
    required Uint8List maskBytes,
    required String maskName,
    int healRadius = 0,
    void Function(LamaJobStatus status)? onProgress,
  }) {
    return processTaskAndWait(
      imageBytes: imageBytes,
      imageName: imageName,
      maskBytes: maskBytes,
      maskName: maskName,
      mode: LamaTaskMode.healRegion,
      healRadius: healRadius,
      onProgress: onProgress,
    );
  }

  /// Complex repairs of corrupted/damaged zones
  Future<Uint8List> repairDamage({
    required Uint8List imageBytes,
    required String imageName,
    required Uint8List maskBytes,
    required String maskName,
    void Function(LamaJobStatus status)? onProgress,
  }) {
    return processTaskAndWait(
      imageBytes: imageBytes,
      imageName: imageName,
      maskBytes: maskBytes,
      maskName: maskName,
      mode: LamaTaskMode.repairDamage,
      onProgress: onProgress,
    );
  }

  /// A second pass to clean and smooth out edges over a masked selection
  Future<Uint8List> cleanEdges({
    required Uint8List imageBytes,
    required String imageName,
    required Uint8List maskBytes,
    required String maskName,
    int edgeRadius = 4,
    void Function(LamaJobStatus status)? onProgress,
  }) {
    return processTaskAndWait(
      imageBytes: imageBytes,
      imageName: imageName,
      maskBytes: maskBytes,
      maskName: maskName,
      mode: LamaTaskMode.cleanEdges,
      edgeRadius: edgeRadius,
      onProgress: onProgress,
    );
  }

}
