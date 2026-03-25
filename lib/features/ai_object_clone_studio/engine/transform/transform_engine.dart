import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import '../../domain/entities/clone_entities.dart';

class TransformEngine {
  static Matrix4 getMatrix(TransformState state, Size objectSize) {
    final Matrix4 matrix = Matrix4.identity();

    // 1. Move to position
    matrix.translate(state.position.dx, state.position.dy);

    // 2. Rotate around center
    matrix.rotateZ(state.rotation);

    // 3. Scale and Flip
    double scaleX = state.scale * (state.flipX ? -1.0 : 1.0);
    double scaleY = state.scale * (state.flipY ? -1.0 : 1.0);
    matrix.scale(scaleX, scaleY);

    // 4. Center the object in the transformation
    matrix.translate(-objectSize.width / 2, -objectSize.height / 2);

    return matrix;
  }

  static Rect getTransformedBounds(TransformState state, Size objectSize) {
    final matrix = getMatrix(state, objectSize);
    
    final points = [
      const Offset(0, 0),
      Offset(objectSize.width, 0),
      Offset(objectSize.width, objectSize.height),
      Offset(0, objectSize.height),
    ];

    final transformedPoints = points.map((p) {
      final vec = matrix.transform3(vm.Vector3(p.dx, p.dy, 0));
      return Offset(vec.x, vec.y);
    }).toList();

    double minX = transformedPoints.map((p) => p.dx).reduce(math.min);
    double maxX = transformedPoints.map((p) => p.dx).reduce(math.max);
    double minY = transformedPoints.map((p) => p.dy).reduce(math.min);
    double maxY = transformedPoints.map((p) => p.dy).reduce(math.max);

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
