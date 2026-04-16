import '../../../models/coins_user.dart';

abstract class AuthRepository {
  Future<CoinsUser?> signInWithGoogle();
  Future<void> signOut();
  String? currentUserId();
}
