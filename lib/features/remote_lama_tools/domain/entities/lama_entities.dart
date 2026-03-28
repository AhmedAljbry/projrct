import 'dart:typed_data';

enum LamaTaskMode {
  healRegion,
  repairDamage,
  expandCanvas,
  cleanEdges,
}

extension LamaTaskModeExtension on LamaTaskMode {
  String get value {
    switch (this) {
      case LamaTaskMode.healRegion:
        return 'heal_region';
      case LamaTaskMode.repairDamage:
        return 'repair_damage';
      case LamaTaskMode.expandCanvas:
        return 'expand_canvas';
      case LamaTaskMode.cleanEdges:
        return 'clean_edges';
    }
  }
}

class LamaJobStatus {
  final String jobId;
  final String status;
  final int progress;
  final String message;
  final String? error;

  const LamaJobStatus({
    required this.jobId,
    required this.status,
    required this.progress,
    required this.message,
    this.error,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

abstract class LamaOptions {
  final Uint8List imageBytes;
  final String imageName;
  final Uint8List? maskBytes;
  final String? maskName;
  final LamaTaskMode mode;

  const LamaOptions({
    required this.imageBytes,
    required this.imageName,
    this.maskBytes,
    this.maskName,
    required this.mode,
  });

  Map<String, String> toFields();
}

class HealRegionOptions extends LamaOptions {
  final int healRadius;

  const HealRegionOptions({
    required super.imageBytes,
    required super.imageName,
    required super.maskBytes,
    required super.maskName,
    this.healRadius = 0,
  }) : super(mode: LamaTaskMode.healRegion);

  @override
  Map<String, String> toFields() => {
    'heal_radius': healRadius.toString(),
  };
}

class RepairDamageOptions extends LamaOptions {
  const RepairDamageOptions({
    required super.imageBytes,
    required super.imageName,
    required super.maskBytes,
    required super.maskName,
  }) : super(mode: LamaTaskMode.repairDamage);

  @override
  Map<String, String> toFields() => {};
}

class ExpandCanvasOptions extends LamaOptions {
  final int left;
  final int top;
  final int right;
  final int bottom;
  final String anchor;

  const ExpandCanvasOptions({
    required super.imageBytes,
    required super.imageName,
    super.maskBytes, // Optional guidance mask
    super.maskName,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.anchor = 'center',
  }) : super(mode: LamaTaskMode.expandCanvas);

  @override
  Map<String, String> toFields() => {
    'expand_left': left.toString(),
    'expand_top': top.toString(),
    'expand_right': right.toString(),
    'expand_bottom': bottom.toString(),
    'anchor': anchor,
  };
}

class CleanEdgesOptions extends LamaOptions {
  final int edgeRadius;

  const CleanEdgesOptions({
    required super.imageBytes,
    required super.imageName,
    required super.maskBytes,
    required super.maskName,
    this.edgeRadius = 4,
  }) : super(mode: LamaTaskMode.cleanEdges);

  @override
  Map<String, String> toFields() => {
    'edge_radius': edgeRadius.toString(),
  };
}

class LamaServerHealth {
  final bool ok;
  final String build;
  final String device;
  final int workers;

  const LamaServerHealth({
    required this.ok,
    required this.build,
    required this.device,
    required this.workers,
  });
}

class LamaCapabilities {
  final String build;
  final List<String> supportedModes;

  const LamaCapabilities({
    required this.build,
    required this.supportedModes,
  });
}
