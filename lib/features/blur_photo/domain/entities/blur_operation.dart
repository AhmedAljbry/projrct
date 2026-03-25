import 'package:equatable/equatable.dart';

import 'blur_settings.dart';

/// A single user-initiated edit operation — wraps settings into a version-able
/// object. Designed to be pushed onto an undo stack.
class BlurOperation extends Equatable {
  const BlurOperation({required this.settings, this.id = 0});

  final BlurPhotoSettings settings;

  /// Monotonically increasing version counter for change detection.
  final int id;

  BlurOperation copyWith({BlurPhotoSettings? settings, int? id}) {
    return BlurOperation(
      settings: settings ?? this.settings,
      id: id ?? this.id,
    );
  }

  factory BlurOperation.initial() =>
      const BlurOperation(settings: BlurPhotoSettings(), id: 0);

  @override
  List<Object?> get props => [settings, id];
}
