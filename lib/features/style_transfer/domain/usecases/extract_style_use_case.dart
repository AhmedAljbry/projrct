import 'dart:typed_data';

import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/repositories/style_transfer_repository.dart';

class ExtractStyleUseCase {
  const ExtractStyleUseCase(this._repository);

  final StyleTransferRepository _repository;

  Future<StyleProfile> call({
    required Uint8List referenceBytes,
    String? name,
  }) {
    return _repository.extractStyle(referenceBytes: referenceBytes, name: name);
  }
}
