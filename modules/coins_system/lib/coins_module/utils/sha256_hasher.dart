import 'dart:convert';
import 'dart:typed_data';

class Sha256Hasher {
  const Sha256Hasher();

  String hash(String input) {
    final bytes = Uint8List.fromList(utf8.encode(input));
    final digest = _digest(bytes);
    final buffer = StringBuffer();
    for (final byte in digest) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  Uint8List _digest(Uint8List message) {
    const h0 = 0x6a09e667;
    const h1 = 0xbb67ae85;
    const h2 = 0x3c6ef372;
    const h3 = 0xa54ff53a;
    const h4 = 0x510e527f;
    const h5 = 0x9b05688c;
    const h6 = 0x1f83d9ab;
    const h7 = 0x5be0cd19;

    const k = <int>[
      0x428a2f98,
      0x71374491,
      0xb5c0fbcf,
      0xe9b5dba5,
      0x3956c25b,
      0x59f111f1,
      0x923f82a4,
      0xab1c5ed5,
      0xd807aa98,
      0x12835b01,
      0x243185be,
      0x550c7dc3,
      0x72be5d74,
      0x80deb1fe,
      0x9bdc06a7,
      0xc19bf174,
      0xe49b69c1,
      0xefbe4786,
      0x0fc19dc6,
      0x240ca1cc,
      0x2de92c6f,
      0x4a7484aa,
      0x5cb0a9dc,
      0x76f988da,
      0x983e5152,
      0xa831c66d,
      0xb00327c8,
      0xbf597fc7,
      0xc6e00bf3,
      0xd5a79147,
      0x06ca6351,
      0x14292967,
      0x27b70a85,
      0x2e1b2138,
      0x4d2c6dfc,
      0x53380d13,
      0x650a7354,
      0x766a0abb,
      0x81c2c92e,
      0x92722c85,
      0xa2bfe8a1,
      0xa81a664b,
      0xc24b8b70,
      0xc76c51a3,
      0xd192e819,
      0xd6990624,
      0xf40e3585,
      0x106aa070,
      0x19a4c116,
      0x1e376c08,
      0x2748774c,
      0x34b0bcb5,
      0x391c0cb3,
      0x4ed8aa4a,
      0x5b9cca4f,
      0x682e6ff3,
      0x748f82ee,
      0x78a5636f,
      0x84c87814,
      0x8cc70208,
      0x90befffa,
      0xa4506ceb,
      0xbef9a3f7,
      0xc67178f2,
    ];

    final bitLength = message.length * 8;
    final padLength = ((56 - ((message.length + 1) % 64)) + 64) % 64;
    final padded = Uint8List(message.length + 1 + padLength + 8)
      ..setRange(0, message.length, message)
      ..[message.length] = 0x80;
    final lengthBytes = ByteData(8)..setUint64(0, bitLength);
    padded.setRange(
        padded.length - 8, padded.length, lengthBytes.buffer.asUint8List());

    var a0 = h0;
    var b0 = h1;
    var c0 = h2;
    var d0 = h3;
    var e0 = h4;
    var f0 = h5;
    var g0 = h6;
    var h00 = h7;

    final words = Uint32List(64);
    for (var chunk = 0; chunk < padded.length; chunk += 64) {
      for (var i = 0; i < 16; i++) {
        final offset = chunk + (i * 4);
        words[i] = (padded[offset] << 24) |
            (padded[offset + 1] << 16) |
            (padded[offset + 2] << 8) |
            padded[offset + 3];
      }
      for (var i = 16; i < 64; i++) {
        final s0 = _rotr(words[i - 15], 7) ^
            _rotr(words[i - 15], 18) ^
            (words[i - 15] >> 3);
        final s1 = _rotr(words[i - 2], 17) ^
            _rotr(words[i - 2], 19) ^
            (words[i - 2] >> 10);
        words[i] = _u32(words[i - 16] + s0 + words[i - 7] + s1);
      }

      var a = a0;
      var b = b0;
      var c = c0;
      var d = d0;
      var e = e0;
      var f = f0;
      var g = g0;
      var h = h00;

      for (var i = 0; i < 64; i++) {
        final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
        final ch = (e & f) ^ ((~e) & g);
        final temp1 = _u32(h + s1 + ch + k[i] + words[i]);
        final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
        final maj = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = _u32(s0 + maj);

        h = g;
        g = f;
        f = e;
        e = _u32(d + temp1);
        d = c;
        c = b;
        b = a;
        a = _u32(temp1 + temp2);
      }

      a0 = _u32(a0 + a);
      b0 = _u32(b0 + b);
      c0 = _u32(c0 + c);
      d0 = _u32(d0 + d);
      e0 = _u32(e0 + e);
      f0 = _u32(f0 + f);
      g0 = _u32(g0 + g);
      h00 = _u32(h00 + h);
    }

    final output = ByteData(32)
      ..setUint32(0, a0)
      ..setUint32(4, b0)
      ..setUint32(8, c0)
      ..setUint32(12, d0)
      ..setUint32(16, e0)
      ..setUint32(20, f0)
      ..setUint32(24, g0)
      ..setUint32(28, h00);
    return output.buffer.asUint8List();
  }

  int _rotr(int value, int bits) =>
      _u32((value >> bits) | (value << (32 - bits)));
  int _u32(int value) => value & 0xffffffff;
}
