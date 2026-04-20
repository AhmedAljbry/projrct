import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

import '../../../core/network/api_exceptions.dart';
import 'inpainting_models.dart';

/// ══════════════════════════════════════════════════════════════
///  InpaintingApi
///
///  Low-level HTTP layer for the LaMa inpainting backend.
///  All public methods return strongly-typed domain objects.
///  No method is missing — every method the repository calls exists here.
///
///  Methods:
///   • submitJob  → SubmitJobResponse
///   • getStatus  → JobStatusResponse
///   • resultBytes→ Uint8List
///   • cancelJob  → void  (never throws)
///   • retryJob   → SubmitJobResponse
/// ══════════════════════════════════════════════════════════════
class InpaintingApi {
  final String baseUrl;
  final String? ownerId;
  final bool diagnostics; // log hashes + dimension checks
  final bool deepMaskValidation; // decode PNG and validate before upload

  InpaintingApi({
    required this.baseUrl,
    this.ownerId,
    this.diagnostics = true,
    this.deepMaskValidation = true,
  });

  // ────────────────────────────────────────────────────────────
  // 1. Submit Job
  // ────────────────────────────────────────────────────────────
  Future<SubmitJobResponse> submitJob({
    required Uint8List image,
    required Uint8List mask,
    String? apiKey,
    String? lang,
  }) async {
    debugPrint('══════════════ [SUBMIT] ══════════════');
    debugPrint('  URL   : $baseUrl/submit-job');
    debugPrint('  image : ${image.length} bytes');
    debugPrint('  mask  : ${mask.length} bytes');

    if (diagnostics) {
      debugPrint('  image hash : ${_hash(image)}');
      debugPrint('  mask  hash : ${_hash(mask)}');
    }

    if (deepMaskValidation) {
      _validateForLama(image: image, mask: mask);
    }

    try {
      return await _submitApiV1(
        image: image,
        mask: mask,
        apiKey: apiKey,
        lang: lang,
      );
    } catch (e) {
      debugPrint('[SUBMIT] API v1 fallback to legacy submit: $e');
    }

    return _submitLegacy(
      image: image,
      mask: mask,
      apiKey: apiKey,
      lang: lang,
    );
  }

  Future<SubmitJobResponse> _submitApiV1({
    required Uint8List image,
    required Uint8List mask,
    String? apiKey,
    String? lang,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/jobs/remove-object'),
    );
    _addHeaders(req.headers, apiKey: apiKey, lang: lang);

    req.files.add(http.MultipartFile.fromBytes(
      'image',
      image,
      filename: 'original.png',
      contentType: MediaType('image', 'png'),
    ));
    req.files.add(http.MultipartFile.fromBytes(
      'mask',
      mask,
      filename: 'mask.png',
      contentType: MediaType('image', 'png'),
    ));

    final streamed = await req.send().timeout(const Duration(seconds: 120));
    final body = await streamed.stream.bytesToString();

    debugPrint('[SUBMIT][v1] status=${streamed.statusCode} body=$body');

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw ApiException(
        _detail(body) ?? 'Submit failed (${streamed.statusCode})',
        statusCode: streamed.statusCode,
      );
    }

    final json = _decodeMap(body);
    final nestedJob = json['job'];
    final jobMap = nestedJob is Map<String, dynamic> ? nestedJob : json;
    final jobId = _readString(jobMap, ['job_id', 'jobId', 'id'])?.trim();
    if (jobId == null || jobId.isEmpty) {
      throw ApiException('Response missing job_id: $body');
    }

    return SubmitJobResponse(
      jobId: jobId,
      position: _readInt(jobMap, ['position', 'queue_position']),
      message: _readString(jobMap, ['message', 'detail']),
    );
  }

  Future<SubmitJobResponse> _submitLegacy({
    required Uint8List image,
    required Uint8List mask,
    String? apiKey,
    String? lang,
  }) async {

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/submit-job'),
    );
    _addHeaders(req.headers, apiKey: apiKey, lang: lang);

    req.files.add(http.MultipartFile.fromBytes(
      'image', image,
      filename: 'original.png',
      contentType: MediaType('image', 'png'),
    ));
    req.files.add(http.MultipartFile.fromBytes(
      'mask', mask,
      filename: 'mask.png',
      contentType: MediaType('image', 'png'),
    ));

    try {
      final streamed = await req.send().timeout(const Duration(seconds: 120));
      final body = await streamed.stream.bytesToString();

      debugPrint('  status : ${streamed.statusCode}');
      debugPrint('  body   : $body');

      if (streamed.statusCode != 200) {
        throw ApiException(
          _detail(body) ?? 'Submit failed (${streamed.statusCode})',
          statusCode: streamed.statusCode,
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final jobId = (json['job_id'] as String?)?.trim();
      if (jobId == null || jobId.isEmpty) {
        throw ApiException('Response missing job_id: $body');
      }

      debugPrint('  jobId  : $jobId');
      debugPrint('══════════════════════════════════════');

      return SubmitJobResponse(
        jobId: jobId,
        position: json['position'] as int?,
        message: json['message'] as String?,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('submitJob error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // 2. Get Status
  // ────────────────────────────────────────────────────────────
  Future<JobStatusResponse> getStatus(
      String jobId, {
        String? apiKey,
        String? lang,
      }) async {
    try {
      try {
        final res = await http
            .get(
          Uri.parse('$baseUrl/api/v1/jobs/$jobId'),
          headers: _headers(apiKey: apiKey, lang: lang),
        )
            .timeout(const Duration(seconds: 30));

        debugPrint('[STATUS][v1] ${res.statusCode} ${res.body}');
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final json = _decodeMap(res.body);
          final nestedJob = json['job'];
          final jobMap = nestedJob is Map<String, dynamic> ? nestedJob : json;
          final status = _normalizeStatus(
            _readString(jobMap, ['status', 'state']) ?? 'unknown',
          );
          return JobStatusResponse(
            status: status,
            stage: _readString(jobMap, ['stage', 'status', 'state']) ?? status,
            progress: _readInt(jobMap, ['progress', 'percent']) ?? 0,
            message: _readString(jobMap, ['message', 'detail']) ?? '',
            position: _readInt(jobMap, ['position', 'queue_position']),
          );
        }
      } catch (e) {
        debugPrint('[STATUS] API v1 fallback to legacy status: $e');
      }

      debugPrint('[STATUS] jobId=$jobId');
      final res = await http
          .get(
        Uri.parse('$baseUrl/status/$jobId'),
        headers: _headers(apiKey: apiKey, lang: lang),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint('[STATUS] ${res.statusCode}  ${res.body}');

      if (res.statusCode != 200) {
        throw ApiException('Status failed: ${res.body}',
            statusCode: res.statusCode);
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final status = _normalizeStatus((json['status'] as String?) ?? 'unknown');

      return JobStatusResponse(
        status: status,
        stage: (json['stage'] as String?) ?? status,
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        message: (json['message'] as String?) ?? '',
        position: json['position'] as int?,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('getStatus error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // 3. Download Result
  // ────────────────────────────────────────────────────────────
  Future<Uint8List> resultBytes(
      String jobId, {
        String? apiKey,
        String? lang,
        Uint8List? sentImageBytes,
      }) async {
    try {
      try {
        final v1Res = await http
            .get(
          Uri.parse('$baseUrl/api/v1/jobs/$jobId/result'),
          headers: _headers(apiKey: apiKey, lang: lang, accept: '*/*'),
        )
            .timeout(const Duration(seconds: 120));

        debugPrint('[RESULT][v1] ${v1Res.statusCode} ${v1Res.bodyBytes.length} bytes');
        if (v1Res.statusCode >= 200 &&
            v1Res.statusCode < 300 &&
            _isImageResponse(v1Res)) {
          return v1Res.bodyBytes;
        }
      } catch (e) {
        debugPrint('[RESULT] API v1 fallback to legacy result: $e');
      }

      debugPrint('[RESULT] jobId=$jobId');
      final res = await http
          .get(
        Uri.parse('$baseUrl/result/$jobId'),
        headers: _headers(apiKey: apiKey, lang: lang, accept: '*/*'),
      )
          .timeout(const Duration(seconds: 120));

      debugPrint(
          '[RESULT] ${res.statusCode}  ${res.bodyBytes.length} bytes');

      if (res.statusCode != 200) {
        throw ApiException('Result download failed: ${res.body}',
            statusCode: res.statusCode);
      }

      if (diagnostics && sentImageBytes != null) {
        final inH = _hash(sentImageBytes);
        final outH = _hash(res.bodyBytes);
        if (inH == outH) {
          debugPrint('⚠️ [RESULT] Output == Input hash — '
              'server returned original image unchanged. '
              'Mask was probably empty or invalid.');
        } else {
          debugPrint('✅ [RESULT] Output differs from input (inpainting applied).');
        }
      }

      return res.bodyBytes;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('resultBytes error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // 4. Cancel Job   (never throws — UI must not break on failure)
  // ────────────────────────────────────────────────────────────
  Future<void> cancelJob(
      String jobId, {
        String? apiKey,
        String? lang,
      }) async {
    try {
      debugPrint('[CANCEL] jobId=$jobId');
      final res = await http
          .post(
        Uri.parse('$baseUrl/cancel/$jobId'),
        headers: _headers(apiKey: apiKey, lang: lang),
      )
          .timeout(const Duration(seconds: 15));
      debugPrint('[CANCEL] ${res.statusCode}');
      // 404 = job already finished → treat as success
    } catch (e) {
      debugPrint('[CANCEL] ignored error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // 5. Retry Job
  // ────────────────────────────────────────────────────────────
  Future<SubmitJobResponse> retryJob(
      String jobId, {
        String? apiKey,
        String? lang,
      }) async {
    try {
      debugPrint('[RETRY] jobId=$jobId');
      final res = await http
          .post(
        Uri.parse('$baseUrl/retry/$jobId'),
        headers: _headers(apiKey: apiKey, lang: lang),
      )
          .timeout(const Duration(seconds: 30));

      debugPrint('[RETRY] ${res.statusCode}  ${res.body}');

      if (res.statusCode != 200) {
        throw ApiException('Retry failed: ${res.body}',
            statusCode: res.statusCode);
      }

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final newId = ((json['job_id'] ?? json['jobId']) as String?)?.trim() ?? jobId;
      return SubmitJobResponse(
        jobId: newId,
        position: json['position'] as int?,
        message: json['message'] as String?,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('retryJob error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // Validation
  // ────────────────────────────────────────────────────────────
  void _validateForLama({
    required Uint8List image,
    required Uint8List mask,
  }) {
    try {
      final imgDec = img.decodePng(image);
      final mskDec = img.decodePng(mask);

      if (imgDec == null || mskDec == null) {
        debugPrint('⚠️ [VALIDATE] Could not decode image or mask for validation.');
        return;
      }

      // Dimensions must match
      if (imgDec.width != mskDec.width || imgDec.height != mskDec.height) {
        debugPrint('🚨 [VALIDATE] DIMENSION MISMATCH: '
            'image=${imgDec.width}×${imgDec.height}  '
            'mask=${mskDec.width}×${mskDec.height}. '
            'LaMa REQUIRES identical sizes!');
      } else {
        debugPrint('✅ [VALIDATE] Dimensions match: ${imgDec.width}×${imgDec.height}');
      }

      // Non-zero coverage
      final stats = _pixelStats(mskDec);
      debugPrint('  mask stats: $stats');

      if (stats.nonZeroPct < 0.05) {
        debugPrint('🚨 [VALIDATE] Mask is effectively EMPTY '
            '(${stats.nonZeroPct.toStringAsFixed(3)}% non-zero). '
            'LaMa will return the original image unchanged!');
      } else if (stats.maxV < 200) {
        debugPrint('⚠️ [VALIDATE] Mask has no pure-white pixels (max=${stats.maxV}). '
            'LaMa prefers binary 0/255. Run prepareMaskForLama() first.');
      } else {
        debugPrint('✅ [VALIDATE] Mask coverage: '
            '${stats.nonZeroPct.toStringAsFixed(2)}%  max=${stats.maxV}');
      }
    } catch (e) {
      debugPrint('⚠️ [VALIDATE] Error (non-fatal): $e');
    }
  }

  // ────────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────────

  Map<String, String> _headers({
    String? apiKey,
    String? lang,
    String accept = 'application/json',
  }) =>
      {
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'FlutterApp/1.0',
        'Accept': accept,
        if (apiKey != null && apiKey.isNotEmpty) 'x-api-key': apiKey,
        if (ownerId != null && ownerId!.isNotEmpty) 'x-owner-id': ownerId!,
        if (lang != null && lang.isNotEmpty) 'Accept-Language': lang,
      };

  void _addHeaders(
      Map<String, String> target, {
        String? apiKey,
        String? lang,
      }) =>
      target.addAll(_headers(apiKey: apiKey, lang: lang));

  String? _detail(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['detail']?.toString();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const ApiException('Expected JSON object response');
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

  String _normalizeStatus(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'queued':
      case 'pending':
        return 'queued';
      case 'processing':
      case 'running':
      case 'in_progress':
        return 'processing';
      case 'completed':
      case 'complete':
      case 'success':
      case 'succeeded':
      case 'done':
        return 'completed';
      case 'failed':
      case 'error':
        return 'failed';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return rawStatus.trim().toLowerCase();
    }
  }

  bool _isImageResponse(http.Response response) {
    return response.headers['content-type']?.contains('image') ?? false;
  }

  _PixStats _pixelStats(img.Image im) {
    final w = im.width, h = im.height;
    final total = w * h;
    int nonZero = 0, minV = 255, maxV = 0, sum = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = im.getPixel(x, y);
        final v = ((p.r + p.g + p.b) / 3).round().clamp(0, 255);
        if (v > 0) nonZero++;
        if (v < minV) minV = v;
        if (v > maxV) maxV = v;
        sum += v;
      }
    }
    return _PixStats(
      total: total,
      minV: minV,
      maxV: maxV,
      mean: sum / total,
      nonZero: nonZero,
      nonZeroPct: (nonZero / total) * 100.0,
    );
  }

  /// FNV-1a 64-bit hash — diagnostic only, not cryptographic.
  String _hash(Uint8List bytes) {
    const int offset = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    int h = offset;
    for (final b in bytes) {
      h ^= (b & 0xff);
      h = (h * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(16, '0');
  }
}

class _PixStats {
  final int total, minV, maxV, nonZero;
  final double mean, nonZeroPct;
  const _PixStats({
    required this.total,
    required this.minV,
    required this.maxV,
    required this.mean,
    required this.nonZero,
    required this.nonZeroPct,
  });

  @override
  String toString() =>
      'total=$total min=$minV max=$maxV '
          'mean=${mean.toStringAsFixed(1)} '
          'nonZero=$nonZero (${nonZeroPct.toStringAsFixed(2)}%)';
}
