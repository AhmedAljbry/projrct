import 'package:flutter/material.dart';
import 'retouch_mode.dart';
import 'brush_settings.dart';

abstract class RetouchOperation {
  final String id;
  final RetouchMode mode;
  final BrushSettings settings;

  RetouchOperation({
    required this.id,
    required this.mode,
    required this.settings,
  });
}

class StrokeOperation extends RetouchOperation {
  final List<Offset> path;
  final Offset? sourceAnchor; // Where the clone/heal started from
  final Offset? targetAnchor; // Where the stroke started
  final SourceAlignmentMode alignmentMode;

  StrokeOperation({
    required super.id,
    required super.mode,
    required super.settings,
    required this.path,
    required this.sourceAnchor,
    required this.targetAnchor,
    this.alignmentMode = SourceAlignmentMode.aligned,
  });
}

class PatchOperation extends RetouchOperation {
  final List<Offset> sourceRegion; // Outline of the patch source
  final Offset targetPosition; // Top-left or center of where patch is placed
  
  PatchOperation({
    required super.id,
    required super.mode,
    required super.settings,
    required this.sourceRegion,
    required this.targetPosition,
  });
}

class EraseOperation extends RetouchOperation {
  final List<Offset> path;

  EraseOperation({
    required super.id,
    required super.mode,
    required super.settings,
    required this.path,
  });
}
