import 'package:coins_system/coins_module/utils/sha256_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sha256 hasher matches known vector', () {
    const hasher = Sha256Hasher();
    expect(
      hasher.hash('abc'),
      'ba7816bf8f01cfea414140de5dae2223'
      'b00361a396177a9cb410ff61f20015ad',
    );
  });
}
