import 'package:flutter/foundation.dart';

class RenderIsolates {

  static Future<T> runHeavyTask<T, P>(P param, Future<T> Function(P) task) async {
     return await compute(task, param);
  }

  // Example worker to process brush paths or masks in background
  static Future<Uint8List> computeMaskBlur(Map<String, dynamic> params) async {
    final Uint8List buffer = params['buffer'];
    final double sigma = params['sigma'];
    final int width = params['width'];
    
    // Do heavy math here
    // For now we just return the buffer
    return buffer;
  }
}
