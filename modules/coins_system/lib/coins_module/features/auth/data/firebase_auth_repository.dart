import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../models/coins_user.dart';
import '../../../utils/module_logger.dart';
import '../../../utils/request_signer.dart';
import '../../device/data/device_fingerprint_data_source.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFunctions functions,
    required DeviceFingerprintDataSource deviceDataSource,
    required RequestSigner requestSigner,
    required ModuleLogger logger,
    required String serverClientId,
  })  : _firebaseAuth = firebaseAuth,
        _functions = functions,
        _deviceDataSource = deviceDataSource,
        _requestSigner = requestSigner,
        _logger = logger,
        _googleSignIn = GoogleSignIn(serverClientId: serverClientId);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFunctions _functions;
  final DeviceFingerprintDataSource _deviceDataSource;
  final RequestSigner _requestSigner;
  final ModuleLogger _logger;
  final GoogleSignIn _googleSignIn;

  @override
  String? currentUserId() => _firebaseAuth.currentUser?.uid;

  @override
  Future<CoinsUser?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      return null;
    }

    final fingerprint = await _deviceDataSource.createFingerprint();
    final request = await _requestSigner.sign(
      action: 'registerUser',
      userId: firebaseUser.uid,
      deviceHash: fingerprint.deviceHash,
      payload: <String, dynamic>{
        'deviceHash': fingerprint.deviceHash,
        'fingerprintSignature': fingerprint.fingerprintSignature,
        'installTimestamp': fingerprint.installTimestamp,
      },
    );

    final callable = _functions.httpsCallable('registerUser');
    final response = await callable.call(<String, dynamic>{
      'deviceHash': fingerprint.deviceHash,
      'fingerprintSignature': fingerprint.fingerprintSignature,
      'installTimestamp': fingerprint.installTimestamp,
      'installId': fingerprint.installId,
      'request': request.toJson(),
      'attributes': fingerprint.attributes,
    });

    final data = Map<String, dynamic>.from(response.data as Map);
    final clientKey = data['clientKey']?.toString();
    if (clientKey != null && clientKey.isNotEmpty) {
      await _requestSigner.saveClientKey(clientKey);
    }

    _logger.info('User registered for coins module: ${firebaseUser.uid}');
    return CoinsUser.fromMap(firebaseUser.uid,
        Map<String, dynamic>.from(data['user'] as Map? ?? const {}));
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
