import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'sha256_hasher.dart';

class SignedRequest {
  const SignedRequest({
    required this.action,
    required this.timestamp,
    required this.nonce,
    required this.signature,
    required this.installId,
    required this.installTimestamp,
  });

  final String action;
  final int timestamp;
  final String nonce;
  final String signature;
  final String installId;
  final int installTimestamp;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'action': action,
        'timestamp': timestamp,
        'nonce': nonce,
        'signature': signature,
        'installId': installId,
        'installTimestamp': installTimestamp,
      };
}

class RequestSigner {
  RequestSigner({
    required FlutterSecureStorage storage,
    required Sha256Hasher hasher,
  })  : _storage = storage,
        _hasher = hasher;

  static const _installIdKey = 'coins_module.install_id';
  static const _installTimestampKey = 'coins_module.install_ts';
  static const _clientKeyKey = 'coins_module.client_key';

  final FlutterSecureStorage _storage;
  final Sha256Hasher _hasher;
  final Random _random = Random.secure();

  Future<String> getOrCreateInstallId() async {
    final existing = await _storage.read(key: _installIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final value = _generateToken(24);
    await _storage.write(key: _installIdKey, value: value);
    return value;
  }

  Future<int> getOrCreateInstallTimestamp() async {
    final existing = await _storage.read(key: _installTimestampKey);
    if (existing != null) {
      return int.tryParse(existing) ?? DateTime.now().millisecondsSinceEpoch;
    }
    final value = DateTime.now().millisecondsSinceEpoch;
    await _storage.write(key: _installTimestampKey, value: '$value');
    return value;
  }

  Future<void> saveClientKey(String clientKey) {
    return _storage.write(key: _clientKeyKey, value: clientKey);
  }

  Future<String?> readClientKey() => _storage.read(key: _clientKeyKey);

  Future<SignedRequest> sign({
    required String action,
    required String userId,
    required String deviceHash,
    required Map<String, dynamic> payload,
  }) async {
    final installId = await getOrCreateInstallId();
    final installTimestamp = await getOrCreateInstallTimestamp();
    final clientKey = await readClientKey();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nonce = _generateToken(18);
    final normalizedPayload = _normalize(payload);
    final payloadHash = _hasher.hash(jsonEncode(normalizedPayload));
    final seed = [
      action,
      userId,
      deviceHash,
      installId,
      '$installTimestamp',
      '$timestamp',
      nonce,
      payloadHash,
      clientKey ?? 'bootstrap',
    ].join('|');
    return SignedRequest(
      action: action,
      timestamp: timestamp,
      nonce: nonce,
      signature: _hasher.hash(seed),
      installId: installId,
      installTimestamp: installTimestamp,
    );
  }

  String _generateToken(int length) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List<String>.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  Object? _normalize(Object? value) {
    if (value is Map) {
      final sorted = value.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in sorted) key: _normalize(value[key]),
      };
    }
    if (value is List) {
      return value.map(_normalize).toList(growable: false);
    }
    return value;
  }
}
