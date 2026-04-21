import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/constants/app_constants.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/entities/auth_user.dart';
import 'package:untitled2/features/profile/data/models/user_profile_dto.dart';
import 'package:untitled2/features/profile/domain/entities/user_profile.dart';
import 'package:untitled2/features/profile/domain/repositories/user_profile_repository.dart';

@LazySingleton(as: UserProfileRepository)
class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository(this._firestore, this._talker);

  final FirebaseFirestore _firestore;
  final Talker _talker;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  @override
  Future<Either<Failure, Unit>> upsertProfile(AuthUser user) async {
    try {
      final now = DateTime.now();
      final ref = _usersCollection.doc(user.id);
      final snapshot = await ref.get();
      final createdAt = snapshot.data()?['createdAt'] is Timestamp
          ? (snapshot.data()!['createdAt'] as Timestamp).toDate()
          : now;
      final dto = UserProfileDto(
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        createdAt: createdAt,
        updatedAt: now,
      );
      await ref.set(dto.toJson(), SetOptions(merge: true));
      return right(unit);
    } catch (error, stackTrace) {
      _talker.error('Failed to upsert user profile', error, stackTrace);
      return left(
        const UnknownFailure(
          'Failed to save user profile.',
          messageKey: 'profile.error.save',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, UserProfile?>> getProfile(String userId) async {
    try {
      final snapshot = await _usersCollection.doc(userId).get();
      final data = snapshot.data();
      if (data == null) {
        return right(null);
      }
      return right(UserProfileDto.fromJson(data).toDomain());
    } catch (error, stackTrace) {
      _talker.error('Failed to fetch user profile', error, stackTrace);
      return left(
        const UnknownFailure(
          'Failed to fetch user profile.',
          messageKey: 'profile.error.fetch',
        ),
      );
    }
  }

  @override
  Stream<Either<Failure, UserProfile?>> watchProfile(String userId) async* {
    try {
      yield* _usersCollection.doc(userId).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data == null) {
          return right(null);
        }
        return right(UserProfileDto.fromJson(data).toDomain());
      });
    } catch (error, stackTrace) {
      _talker.error('Failed to watch user profile', error, stackTrace);
      yield left(
        const UnknownFailure(
          'Failed to watch user profile.',
          messageKey: 'profile.error.fetch',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> saveFcmToken({
    required String userId,
    required String token,
  }) {
    return _updateFields(userId: userId, data: {'fcmToken': token});
  }

  @override
  Future<Either<Failure, Unit>> updatePhotoUrl({
    required String userId,
    required String photoUrl,
  }) {
    return _updateFields(userId: userId, data: {'photoUrl': photoUrl});
  }

  Future<Either<Failure, Unit>> _updateFields({
    required String userId,
    required Map<String, Object?> data,
  }) async {
    try {
      await _usersCollection.doc(userId).set(
        {
          ...data,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        },
        SetOptions(merge: true),
      );
      return right(unit);
    } catch (error, stackTrace) {
      _talker.error('Failed to update user profile', error, stackTrace);
      return left(
        const UnknownFailure(
          'Failed to update user profile.',
          messageKey: 'profile.error.save',
        ),
      );
    }
  }
}
