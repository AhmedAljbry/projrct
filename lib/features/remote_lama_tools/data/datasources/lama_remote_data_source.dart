import 'dart:convert';
import 'dart:typed_data';

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
  final http.Client client;

  LamaRemoteDataSourceImpl({
    required this.baseUrl,
    required this.apiKey,
    required this.client,
  });

  Map<String, String> get _headers => {
        'x-api-key': apiKey,
        'Accept-Language': 'en',
        'ngrok-skip-browser-warning': '1',
      };

  @override
  Future<LamaServerHealth> checkHealth() async {
    final response = await client.get(
      Uri.parse('$baseUrl/health'),
      headers: _headers,
    );
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return LamaServerHealth(
      ok: data['ok'] ?? false,
      build: data['build'] ?? 'unknown',
      device: data['device'] ?? 'unknown',
      workers: data['workers'] ?? 0,
    );
  }

  @override
  Future<LamaCapabilities> getCapabilities() async {
    final response = await client.get(
      Uri.parse('$baseUrl/capabilities'),
      headers: _headers,
    );
    _checkResponse(response);
    final data = jsonDecode(response.body);
    return LamaCapabilities(
      build: data['build'] ?? 'unknown',
      supportedModes: List<String>.from(data['modes'] ?? []),
    );
  }

  @override
  Future<String> submitJob(LamaOptions options) async {
    final uri = Uri.parse('$baseUrl/submit-task');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_headers)
      ..fields['mode'] = options.mode.value;

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

    _checkResponse(response);

    final data = jsonDecode(response.body);
    if (data['ok'] == true && data['job_id'] != null) {
      return data['job_id'];
    }
    throw LamaApiFailure('Failed to submit task: ${data['message']}');
  }

  @override
  Future<LamaJobStatus> getJobStatus(String jobId) async {
    final uri = Uri.parse('$baseUrl/status/$jobId');
    final response = await client.get(uri, headers: _headers);
    _checkResponse(response);
    final data = jsonDecode(response.body);
    if (data['ok'] == true) {
      return LamaJobStatus(
        jobId: data['job_id'] ?? jobId,
        status: data['status'] ?? 'unknown',
        progress: data['progress'] ?? 0,
        message: data['message'] ?? '',
        error: data['error'],
      );
    }
    throw LamaApiFailure('Failed to get status: ${data['message']}');
  }

  @override
  Future<Uint8List> getJobResult(String jobId) async {
    final uri = Uri.parse('$baseUrl/result/$jobId');
    final response = await client.get(uri, headers: _headers);

    _checkResponse(response);

    if (response.headers['content-type']?.contains('image') ?? false) {
      return response.bodyBytes;
    }
    final data = jsonDecode(response.body);
    throw LamaApiFailure(
      'Result endpoint returned json instead of image: ${data['message']}',
    );
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
