import 'dart:typed_data';

import 'package:untitled2/inpainting/data/inpainting_api.dart';
import 'package:untitled2/inpainting/domain/inpainting_failure.dart';

import '../../../core/network/api_exceptions.dart';

import 'inpainting_models.dart';

/// ══════════════════════════════════════════════════════════════
///  InpaintingRepository
///
///  Thin adapter between InpaintingBloc and InpaintingApi.
///  • Passes optional apiKey / lang to every API call.
///  • Maps ApiException → InpaintingFailure for the Bloc layer.
/// ══════════════════════════════════════════════════════════════
class InpaintingRepository {
  final InpaintingApi api;
  final String? apiKey;
  final String? lang;

  const InpaintingRepository(this.api, {this.apiKey, this.lang});

  // ── Submit ─────────────────────────────────────────────────
  Future<SubmitJobResponse> submitJob({
    required Uint8List image,
    required Uint8List mask,
  }) async {
    try {
      return await api.submitJob(
        image: image,
        mask: mask,
        apiKey: apiKey,
        lang: lang,
      );
    } catch (e) {
      throw _map(e);
    }
  }

  // ── Status ─────────────────────────────────────────────────
  Future<JobStatusResponse> getStatus(String jobId) async {
    try {
      return await api.getStatus(jobId, apiKey: apiKey, lang: lang);
    } catch (e) {
      throw _map(e);
    }
  }

  // ── Download ───────────────────────────────────────────────
  Future<Uint8List> downloadResult(
      String jobId, {
        Uint8List? sentImageBytes,
      }) async {
    try {
      return await api.resultBytes(
        jobId,
        apiKey: apiKey,
        lang: lang,
        sentImageBytes: sentImageBytes,
      );
    } catch (e) {
      throw _map(e);
    }
  }

  // ── Cancel (never throws) ──────────────────────────────────
  Future<void> cancelJob(String jobId) =>
      api.cancelJob(jobId, apiKey: apiKey, lang: lang);

  // ── Retry ──────────────────────────────────────────────────
  Future<SubmitJobResponse> retryJob(String jobId) async {
    try {
      return await api.retryJob(jobId, apiKey: apiKey, lang: lang);
    } catch (e) {
      throw _map(e);
    }
  }

  // ── Error mapping ──────────────────────────────────────────
  InpaintingFailure _map(Object e) {
    if (e is InpaintingFailure) return e;

    if (e is ApiException) {
      return switch (e.statusCode) {
        400 => const InpaintingFailure(code: 'bad_request',  messageKey: 'bad_request'),
        401 => const InpaintingFailure(code: 'unauthorized', messageKey: 'unauthorized'),
        403 => const InpaintingFailure(code: 'forbidden',    messageKey: 'forbidden'),
        404 => const InpaintingFailure(code: 'not_found',    messageKey: 'not_found'),
        408 => const InpaintingFailure(code: 'timeout',      messageKey: 'timeout'),
        429 => const InpaintingFailure(code: 'rate_limited', messageKey: 'rate_limited'),
        500 => const InpaintingFailure(code: 'server_error', messageKey: 'server_error'),
        503 => const InpaintingFailure(code: 'unavailable',  messageKey: 'unavailable'),
        _   => const InpaintingFailure(code: 'unknown',      messageKey: 'failed'),
      };
    }

    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('timedout')) {
      return const InpaintingFailure(code: 'timeout', messageKey: 'timeout');
    }
    if (msg.contains('socket') || msg.contains('connection')) {
      return const InpaintingFailure(code: 'network', messageKey: 'network_error');
    }
    return const InpaintingFailure(code: 'unknown', messageKey: 'failed');
  }
}
