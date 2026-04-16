import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../models/coin_transaction.dart';
import '../../../models/coins_user.dart';
import '../../../models/reward_result.dart';
import '../../../utils/request_signer.dart';
import '../../device/data/device_fingerprint_data_source.dart';
import '../domain/coins_repository.dart';

class FirestoreCoinsRepository implements CoinsRepository {
  FirestoreCoinsRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required DeviceFingerprintDataSource deviceDataSource,
    required RequestSigner requestSigner,
  })  : _firestore = firestore,
        _functions = functions,
        _deviceDataSource = deviceDataSource,
        _requestSigner = requestSigner;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final DeviceFingerprintDataSource _deviceDataSource;
  final RequestSigner _requestSigner;

  @override
  Future<RewardResult> claimAdReward(String userId) async {
    final fingerprint = await _deviceDataSource.createFingerprint();
    final request = await _requestSigner.sign(
      action: 'rewardAd',
      userId: userId,
      deviceHash: fingerprint.deviceHash,
      payload: <String, dynamic>{
        'deviceHash': fingerprint.deviceHash,
        'fingerprintSignature': fingerprint.fingerprintSignature,
      },
    );
    final callable = _functions.httpsCallable('rewardAd');
    final response = await callable.call(<String, dynamic>{
      'deviceHash': fingerprint.deviceHash,
      'fingerprintSignature': fingerprint.fingerprintSignature,
      'request': request.toJson(),
    });
    final data = Map<String, dynamic>.from(response.data as Map);
    return RewardResult(
      success: data['success'] == true,
      coinsAdded: (data['coinsAdded'] as num?)?.toInt() ?? 0,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      message: data['message']?.toString() ?? '',
    );
  }

  @override
  Future<List<CoinTransaction>> getTransactions(String userId,
      {int limit = 20}) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CoinTransaction.fromMap(doc.id, doc.data()))
        .toList(growable: false);
  }

  @override
  Future<CoinsUser> getWallet(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).get();
    return CoinsUser.fromMap(userId, snapshot.data());
  }

  @override
  Stream<CoinsUser> watchWallet(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map(
          (snapshot) => CoinsUser.fromMap(userId, snapshot.data()),
        );
  }
}
