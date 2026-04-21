import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:untitled2/core/error/failure.dart';

abstract class UserStorageService {
  Future<Either<Failure, String>> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    required String extension,
  });
}
