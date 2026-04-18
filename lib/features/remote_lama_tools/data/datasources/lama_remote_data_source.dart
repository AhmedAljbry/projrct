import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/failures/lama_failure.dart';

abstract class LamaRemoteDataSource {
  Future<LamaServerHealth> checkHealth();
  Future<LamaCapabilities> getCapabilities();
  Future<String> submitJob(LamaOptions options);
  Future<LamaJobStatus> getJobStatus(String jobId);
  Future<Uint8List> getJobResult(String jobId);
}

class LamaRemoteDataSourceImpl implements LamaRemoteDataSource {
  final String baseUrl;
  final String apiKey;
  final String ownerId;
  final http.Client client;

  LamaRemoteDataSourceImpl({
    required this.baseUrl,
    required this.apiKey,
    required this.client,
    this.ownerId = 'app-user',
  });

  Map<String, String> get _headers => {
        'Accept-Language': 'en',
        'ngrok-skip-browser-warning': '1',
        'x-owner-id': ownerId,
        if (apiKey.isNotEmpty) 'x-api-key': apiKey,
      };

  void _log(String message) {
    debugPrint('[LamaRemoteApi] $message');
  }

  @override
  Future<LamaServerHealth> checkHealth() async {
    final response = await _getWithFallback(
      primaryPath: '/api/v1/health/live',
      fallbackPath: '/health',
      logLabel: 'health',
    );
    final data = _decodeMap(response.body);
    return LamaServerHealth(
      ok: _readBool(data, ['ok', 'healthy', 'live']) ?? true,
      build: _readString(data, ['build', 'version']) ?? 'unknown',
      device: _readString(data, ['device', 'runtime']) ?? 'unknown',
      workers: _readInt(data, ['workers', 'worker_count']) ?? 0,
    );
  }

  @override
  Future<LamaCapabilities> getCapabilities() async {
    try {
      final response = await _getWithFallback(
        primaryPath: '/api/v1/queue/status',
        fallbackPath: '/capabilities',
        logLabel: 'capabilities',
      );
      final data = _decodeMap(response.body);
      final modes = _readModes(data);
      return LamaCapabilities(
        build: _readString(data, ['build', 'version']) ?? 'api-v1',
        supportedModes: modes.isNotEmpty
            ? modes
            : const ['remove_object', 'restore', 'smart_restore'],
      );
    } catch (_) {
      return const LamaCapabilities(
        build: 'fallback',
        supportedModes: ['remove_object', 'restore', 'smart_restore'],
      );
    }
  }

  @override
  Future<String> submitJob(LamaOptions options) async {
    final apiV1Path = options.mode.apiV1JobPath;
    if (apiV1Path != null) {
      try {
        final response = await _sendMultipartRequest(
          path: apiV1Path,
          options: options,
          includeLegacyModeField: false,
          logLabel: 'submit-v1',
        );
        final data = _decodeMap(response.body);
        final jobId = _extractJobId(data);
        if (jobId != null && jobId.isNotEmpty) {
          return jobId;
        }
        throw LamaApiFailure('API v1 response missing job id: ${response.body}');
      } catch (error) {
        _log('API v1 submit fallback for mode=${options.mode.value}: $error');
      }
    }

    final response = await _sendMultipartRequest(
      path: '/submit-task',
      options: options,
      includeLegacyModeField: true,
      logLabel: 'submit-legacy',
    );
    final data = _decodeMap(response.body);
    if (data['ok'] == true && data['job_id'] != null) {
      return data['job_id'].toString();
    }
    throw LamaApiFailure('Failed to submit task: ${data['message'] ?? response.body}');
  }

  @override
  Future<LamaJobStatus> getJobStatus(String jobId) async {
    try {
      final response = await _get('/api/v1/jobs/$jobId', logLabel: 'status-v1');
      final data = _decodeMap(response.body);
      return _parseApiV1JobStatus(data, jobId);
    } catch (error) {
      _log('API v1 status fallback for jobId=$jobId: $error');
    }

    final response = await _get('/status/$jobId', logLabel: 'status-legacy');
    final data = _decodeMap(response.body);
    if (data['ok'] == true) {
      return LamaJobStatus(
        jobId: (data['job_id'] ?? jobId).toString(),
        status: (data['status'] ?? 'unknown').toString(),
        progress: _readInt(data, ['progress']) ?? 0,
        message: (data['message'] ?? '').toString(),
        error: data['error']?.toString(),
      );
    }
    throw LamaApiFailure('Failed to get status: ${data['message'] ?? response.body}');
  }

  @override
  Future<Uint8List> getJobResult(String jobId) async {
    try {
      final response = await _get(
        '/api/v1/jobs/$jobId/result',
        logLabel: 'result-v1',
      );
      if (_isImageResponse(response)) {
        return response.bodyBytes;
      }
    } catch (error) {
      _log('API v1 result fallback for jobId=$jobId: $error');
    }

    final response = await _get('/result/$jobId', logLabel: 'result-legacy');
    if (_isImageResponse(response)) {
      return response.bodyBytes;
    }
    final data = _decodeMap(response.body);
    throw LamaApiFailure(
      'Result endpoint returned json instead of image: ${data['message'] ?? response.body}',
    );
  }

  Future<http.Response> _getWithFallback({
    required String primaryPath,
    required String fallbackPath,
    required String logLabel,
  }) async {
    try {
      return await _get(primaryPath, logLabel: '$logLabel-primary');
    } catch (error) {
      _log('$logLabel fallback: $error');
      return _get(fallbackPath, logLabel: '$logLabel-fallback');
    }
  }

  Future<http.Response> _get(String path, {required String logLabel}) async {
    final uri = Uri.parse('$baseUrl$path');
    _log('GET[$logLabel] $uri');
    final response = await client.get(uri, headers: _headers);
    _log('GET[$logLabel] -> ${response.statusCode} ${response.body}');
    _checkResponse(response);
    return response;
  }

  Future<http.Response> _sendMultipartRequest({
    required String path,
    required LamaOptions options,
    required bool includeLegacyModeField,
    required String logLabel,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    _log(
      'POST[$logLabel] $uri mode=${options.mode.value} image=${options.imageName} (${options.imageBytes.length} bytes) mask=${options.maskName ?? "-"} (${options.maskBytes?.length ?? 0} bytes)',
    );

    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers);

    if (includeLegacyModeField) {
      request.fields['mode'] = options.mode.value;
    }

    request.fields.addAll(options.toFields());
    if (options.optionsJson != null && options.optionsJson!.isNotEmpty) {
      request.fields['options_json'] = jsonEncode(options.optionsJson);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        options.imageBytes,
        filename: options.imageName,
        contentType: MediaType(
          'image',
          options.imageName.endsWith('.png') ? 'png' : 'jpeg',
        ),
      ),
    );

    if (options.maskBytes != null && options.maskName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'mask',
          options.maskBytes!,
          filename: options.maskName!,
          contentType: MediaType('image', 'png'),
        ),
      );
    }

    final streamedResponse = await client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    _log('POST[$logLabel] -> ${response.statusCode} ${response.body}');
    _checkResponse(response);
    return response;
  }

  LamaJobStatus _parseApiV1JobStatus(Map<String, dynamic> data, String fallbackJobId) {
    final nestedJob = data['job'];
    final jobData = nestedJob is Map<String, dynamic> ? nestedJob : data;
    final status = _readString(jobData, ['status', 'state']) ?? 'unknown';
    final message = _readString(jobData, ['message', 'detail']) ?? '';
    final error = _readString(jobData, ['error', 'failure_reason']);
    return LamaJobStatus(
      jobId: _extractJobId(jobData) ?? fallbackJobId,
      status: status,
      progress: _readInt(jobData, ['progress', 'percent']) ?? 0,
      message: message,
      error: error,
    );
  }

  String? _extractJobId(Map<String, dynamic> data) {
    final value = data['job_id'] ?? data['jobId'] ?? data['id'];
    return value?.toString();
  }

  List<String> _readModes(Map<String, dynamic> data) {
    final dynamic value = data['modes'] ?? data['supported_modes'];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  bool _isImageResponse(http.Response response) {
    return response.headers['content-type']?.contains('image') ?? false;
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const LamaApiFailure('Expected JSON object response');
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        return value.toString();
      }
    }
    return null;
  }

  int? _readInt(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is bool) {
        return value;
      }
      if (value is String) {
        if (value.toLowerCase() == 'true') {
          return true;
        }
        if (value.toLowerCase() == 'false') {
          return false;
        }
      }
    }
    return null;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == 429) {
      throw const LamaRateLimitFailure('Too many requests');
    }
    if (response.statusCode == 503) {
      throw const LamaServerBusyFailure('Server busy');
    }
    if (response.statusCode == 422) {
      throw LamaValidationFailure('Validation error: ${response.body}');
    }
    throw LamaApiFailure('HTTP ${response.statusCode}: ${response.body}');
  }
}
