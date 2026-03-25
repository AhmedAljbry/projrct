import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../entities/clone_entities.dart';
import '../repositories/iclone_repository.dart';

class ExtractObjectUseCase {
  final ICloneRepository repository;

  ExtractObjectUseCase(this.repository);

  Future<ClonedObject> call({
    required Uint8List imageBytes,
    required List<Offset> points,
    required SelectionMode mode,
  }) {
    return repository.extractObject(
      imageBytes: imageBytes,
      points: points,
      mode: mode,
    );
  }
}

class HarmonizeLayerUseCase {
  final ICloneRepository repository;

  HarmonizeLayerUseCase(this.repository);

  Future<Uint8List> call({
    required Uint8List targetImage,
    required EditLayer layer,
  }) {
    return repository.harmonizeLayer(
      targetImage: targetImage,
      layer: layer,
    );
  }
}

class FinalizeCloneImageUseCase {
  final ICloneRepository repository;

  FinalizeCloneImageUseCase(this.repository);

  Future<Uint8List> call({
    required Uint8List baseImage,
    required List<EditLayer> layers,
  }) {
    return repository.finalizeImage(
      baseImage: baseImage,
      layers: layers,
    );
  }
}
