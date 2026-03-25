import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../entities/clone_entities.dart';

abstract class ICloneRepository {
  Future<ClonedObject> extractObject({
    required Uint8List imageBytes,
    required List<Offset> points,
    required SelectionMode mode,
  });

  Future<Uint8List> harmonizeLayer({
    required Uint8List targetImage,
    required EditLayer layer,
  });

  Future<Uint8List> finalizeImage({
    required Uint8List baseImage,
    required List<EditLayer> layers,
  });
}

enum SelectionMode {
  smart,
  brush,
  lasso,
  rectangle,
}
