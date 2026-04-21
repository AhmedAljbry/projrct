import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/constants/app_constants.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/profile/domain/services/user_storage_service.dart';

@LazySingleton(as: UserStorageService)
class FirebaseUserStorageService implements UserStorageService {
  FirebaseUserStorageService(this._storage, this._talker);

  final FirebaseStorage _storage;
  final Talker _talker;

  @override
  Future<Either<Failure, String>> uploadProfileImage({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      final path =
          '${AppConstants.profileImagesFolder}/$userId/avatar.$extension';
      final ref = _storage.ref().child(path);
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/$extension',
          customMetadata: {'ownerId': userId},
        ),
      );
      return right(await ref.getDownloadURL());
    } catch (error, stackTrace) {
      _talker.error('Profile image upload failed', error, stackTrace);
      return left(
        const UnknownFailure(
          'Failed to upload profile image.',
          messageKey: 'profile.error.uploadImage',
        ),
      );
    }
  }
}
