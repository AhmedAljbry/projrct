import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AiSelectionType { face, sky, subject, background }

class AiSelectionEngine {
  
  // Future implementation of actual TFLite / MLKit Vision APIs
  // For now, this acts as the interface returning a mask or path
  Future<List<Offset>> detectRegion(AiSelectionType type, Uint8List imageBytes, int width, int height) async {
    // Simulate ML heavy processing
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Returns dummy points for simulated area.
    return [
      Offset(width * 0.2, height * 0.2),
      Offset(width * 0.8, height * 0.2),
      Offset(width * 0.8, height * 0.8),
      Offset(width * 0.2, height * 0.8),
    ];
  }

  Future<Uint8List> generateSegmentationMask(AiSelectionType type, Uint8List imageBytes, int width, int height) async {
    // Return a dummy 0..255 mask array for the entire image
    await Future.delayed(const Duration(milliseconds: 800));
    final buffer = Uint8List(width * height);
    for (int i = 0; i < buffer.length; i++) {
       // Mock 50% opacity mask selected
       buffer[i] = 128;
    }
    return buffer;
  }
}
