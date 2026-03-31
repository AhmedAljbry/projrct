import 'dart:typed_data';

import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_result.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_transfer_settings.dart';
import 'package:untitled2/features/style_transfer/domain/usecases/apply_style_use_case.dart';

class BatchApplyUseCase {
  const BatchApplyUseCase(this._applyStyleUseCase);

  final ApplyStyleUseCase _applyStyleUseCase;

  Future<List<StyleTransferResult>> call({
    required List<Uint8List> targetImages,
    required StyleProfile styleProfile,
    required StyleTransferSettings settings,
    Uint8List? referenceBytes,
  }) async {
    final results = <StyleTransferResult>[];
    for (final image in targetImages) {
      final result = await _applyStyleUseCase(
        targetBytes: image,
        styleProfile: styleProfile,
        settings: settings,
        referenceBytes: referenceBytes,
      );
      results.add(result);
    }
    return results;
  }
}
