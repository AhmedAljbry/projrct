import 'dart:typed_data';

enum MaskBlendMode { add, subtract, multiply, screen, overlap }

class MaskLayer {
  final int width;
  final int height;
  
  // High-precision grayscale memory mask.
  // 0 is transparent, 255 is fully opaque.
  late Uint8List buffer;
  
  bool isVisible = true;
  double opacity = 1.0;
  MaskBlendMode blendMode = MaskBlendMode.add;

  MaskLayer({required this.width, required this.height}) {
    buffer = Uint8List(width * height);
    _clearBuffer(0);
  }

  void _clearBuffer(int value) {
    for (int i = 0; i < buffer.length; i++) {
        buffer[i] = value;
    }
  }

  void clear() => _clearBuffer(0);
  void fill() => _clearBuffer(255);
  void invert() {
    for (int i = 0; i < buffer.length; i++) {
        buffer[i] = 255 - buffer[i];
    }
  }
}
