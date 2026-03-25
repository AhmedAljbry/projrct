import 'dart:typed_data';
import 'dart:ui' as ui;
import 'mask_layer.dart';

class MaskEngine {
  final int width;
  final int height;
  
  final List<MaskLayer> _layers = [];
  int _activeLayerIndex = 0;

  MaskEngine({required this.width, required this.height}) {
    // start with a base layer
    _layers.add(MaskLayer(width: width, height: height));
  }

  List<MaskLayer> get layers => _layers;
  MaskLayer get activeLayer => _layers[_activeLayerIndex];

  void addLayer() {
    _layers.add(MaskLayer(width: width, height: height));
    _activeLayerIndex = _layers.length - 1;
  }

  void setActiveLayer(int index) {
    if (index >= 0 && index < _layers.length) {
      _activeLayerIndex = index;
    }
  }

  void invertActiveLayer() {
    activeLayer.invert();
  }

  void clearActiveLayer() {
    activeLayer.clear();
  }

  // To be used by flutter's custom painter or pixel blending pipeline
  Future<ui.Image> generateCompositeMask() async {
    // Generate a composite from the buffers based on blend modes
    // For simplicity of this high-level engine code, we will construct a single Uint8List
    // and convert it into a Flutter ui.Image.
    
    final compositeBuffer = Uint8List(width * height * 4); // RGBA format

    for (int i = 0; i < width * height; i++) {
      double alpha = 0.0;
      
      for (final layer in _layers) {
        if (!layer.isVisible) continue;
        
        double val = (layer.buffer[i] / 255.0) * layer.opacity;

        switch (layer.blendMode) {
          case MaskBlendMode.add:
            alpha = (alpha + val).clamp(0.0, 1.0);
            break;
          case MaskBlendMode.subtract:
            alpha = (alpha - val).clamp(0.0, 1.0);
            break;
          case MaskBlendMode.multiply:
            alpha = alpha * val;
            break;
          case MaskBlendMode.screen:
            alpha = 1.0 - (1.0 - alpha) * (1.0 - val);
            break;
          case MaskBlendMode.overlap:
            alpha = (alpha > 0.0 && val > 0.0) ? 1.0 : 0.0;
            break;
        }
      }

      int a = (alpha * 255).toInt().clamp(0, 255);
      // Grayscale outputs: R=a, G=a, B=a, A=a
      int baseIdx = i * 4;
      compositeBuffer[baseIdx] = a;       // R
      compositeBuffer[baseIdx + 1] = a;   // G
      compositeBuffer[baseIdx + 2] = a;   // B
      compositeBuffer[baseIdx + 3] = a;   // A
    }

    final ui.ImmutableBuffer immutableBuffer =
        await ui.ImmutableBuffer.fromUint8List(compositeBuffer);
    
    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      immutableBuffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    
    return frameInfo.image;
  }
}
