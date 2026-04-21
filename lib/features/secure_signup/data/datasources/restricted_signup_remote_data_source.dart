import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:untitled2/core/network/api_exceptions.dart';
import 'package:untitled2/features/secure_signup/data/models/request_device_override_api_request.dart';
import 'package:untitled2/features/secure_signup/data/models/restricted_signup_api_request.dart';
import 'package:untitled2/features/secure_signup/data/models/restricted_signup_api_response.dart';

abstract class RestrictedSignupRemoteDataSource {
  Future<RestrictedSignupApiResponse> completeSignup({
    required RestrictedSignupApiRequest request,
    required String authToken,
    required String appCheckToken,
  });

  Future<void> requestOverride({
    required RequestDeviceOverrideApiRequest request,
    required String authToken,
    required String appCheckToken,
  });
}

class RestrictedSignupRemoteDataSourceImpl
    implements RestrictedSignupRemoteDataSource {
  RestrictedSignupRemoteDataSourceImpl({
    required String baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/$'), ''),
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  @override
  Future<RestrictedSignupApiResponse> completeSignup({
    required RestrictedSignupApiRequest request,
    required String authToken,
    required String appCheckToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/signup/complete'),
      headers: _headers(authToken: authToken, appCheckToken: appCheckToken),
      body: jsonEncode(request.toJson()),
    );
    return _parseSignupResponse(response);
  }

  @override
  Future<void> requestOverride({
    required RequestDeviceOverrideApiRequest request,
    required String authToken,
    required String appCheckToken,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/signup/request-override'),
      headers: _headers(authToken: authToken, appCheckToken: appCheckToken),
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toApiException(response);
    }
  }

  Map<String, String> _headers({
    required String authToken,
    required String appCheckToken,
  }) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $authToken',
      'X-Firebase-AppCheck': appCheckToken,
    };
  }

  RestrictedSignupApiResponse _parseSignupResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _toApiException(response);
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return RestrictedSignupApiResponse.fromJson(decoded);
  }

  ApiException _toApiException(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final error = decoded['error'] as Map<String, dynamic>? ?? decoded;
      return ApiException(
        error['message'] as String? ?? 'Unexpected API failure.',
        statusCode: response.statusCode,
      );
    } catch (_) {
      return ApiException(
        'Unexpected API failure.',
        statusCode: response.statusCode,
      );
    }
  }
}
