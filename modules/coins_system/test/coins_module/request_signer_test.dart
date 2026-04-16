import 'package:coins_system/coins_module/utils/request_signer.dart';
import 'package:coins_system/coins_module/utils/sha256_hasher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends FlutterSecureStorage {
  static final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    MacOsOptions? mOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    MacOsOptions? mOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

void main() {
  test('request signer persists install identity', () async {
    final signer = RequestSigner(
      storage: _MemoryStorage(),
      hasher: const Sha256Hasher(),
    );

    final installId1 = await signer.getOrCreateInstallId();
    final installId2 = await signer.getOrCreateInstallId();
    expect(installId1, installId2);
  });
}
