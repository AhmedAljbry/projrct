import 'dart:math';
import 'dart:typed_data';

class BytesStats {
  final int len;
  final int minV;
  final int maxV;
  final double mean;
  final int nonZero;
  final double nonZeroPct;

  BytesStats(this.len, this.minV, this.maxV, this.mean, this.nonZero, this.nonZeroPct);

  @override
  String toString() =>
      'len=$len min=$minV max=$maxV mean=${mean.toStringAsFixed(2)} nonZero=$nonZero (${nonZeroPct.toStringAsFixed(2)}%)';
}

BytesStats statsOf(Uint8List b) {
  if (b.isEmpty) return BytesStats(0, 0, 0, 0, 0, 0);
  int minV = 255, maxV = 0, nonZero = 0;
  int sum = 0;
  for (final v in b) {
    final iv = v & 0xFF;
    minV = min(minV, iv);
    maxV = max(maxV, iv);
    sum += iv;
    if (iv != 0) nonZero++;
  }
  final mean = sum / b.length;
  final nonZeroPct = (nonZero / b.length) * 100.0;
  return BytesStats(b.length, minV, maxV, mean, nonZero, nonZeroPct);
}