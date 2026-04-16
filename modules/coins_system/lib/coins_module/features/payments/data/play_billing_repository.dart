import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../models/product_offer.dart';
import '../../../models/reward_result.dart';
import '../../../utils/request_signer.dart';
import '../../device/data/device_fingerprint_data_source.dart';
import '../domain/payments_repository.dart';

class PlayBillingRepository implements PaymentsRepository {
  PlayBillingRepository({
    required InAppPurchase inAppPurchase,
    required FirebaseFunctions functions,
    required FirebaseAuth auth,
    required DeviceFingerprintDataSource deviceDataSource,
    required RequestSigner requestSigner,
    required Map<String, int> productCoins,
    required String packageName,
  })  : _inAppPurchase = inAppPurchase,
        _functions = functions,
        _auth = auth,
        _deviceDataSource = deviceDataSource,
        _requestSigner = requestSigner,
        _productCoins = productCoins,
        _packageName = packageName;

  final InAppPurchase _inAppPurchase;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final DeviceFingerprintDataSource _deviceDataSource;
  final RequestSigner _requestSigner;
  final Map<String, int> _productCoins;
  final String _packageName;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<RewardResult>? _purchaseCompleter;

  @override
  Future<List<ProductOffer>> loadProducts() async {
    final response =
        await _inAppPurchase.queryProductDetails(_productCoins.keys.toSet());
    return response.productDetails
        .map(
          (product) => ProductOffer(
            productId: product.id,
            title: product.title,
            description: product.description,
            priceLabel: product.price,
            coins: _productCoins[product.id] ?? 0,
            rawPrice: product.rawPrice,
            currencyCode: product.currencyCode,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<RewardResult> buyProduct(String productId) async {
    final response =
        await _inAppPurchase.queryProductDetails(<String>{productId});
    if (response.productDetails.isEmpty) {
      return RewardResult.safe('Product not found');
    }
    _subscription ??= _inAppPurchase.purchaseStream.listen(_onPurchaseUpdates);
    _purchaseCompleter = Completer<RewardResult>();
    final product = response.productDetails.first;
    final started = await _inAppPurchase.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: true,
    );
    if (!started) {
      return RewardResult.safe('Purchase could not start');
    }
    return _purchaseCompleter!.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () => RewardResult.safe('Purchase verification timed out'),
    );
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.complete(
              RewardResult.safe(purchase.error?.message ?? 'Purchase error'));
        }
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final userId = _auth.currentUser?.uid;
        if (userId == null) {
          if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
            _purchaseCompleter!
                .complete(RewardResult.safe('User not authenticated'));
          }
          continue;
        }
        final fingerprint = await _deviceDataSource.createFingerprint();
        final request = await _requestSigner.sign(
          action: 'verifyPurchase',
          userId: userId,
          deviceHash: fingerprint.deviceHash,
          payload: <String, dynamic>{
            'productId': purchase.productID,
            'purchaseToken': purchase.verificationData.serverVerificationData,
            'source': purchase.verificationData.source,
          },
        );
        final callable = _functions.httpsCallable('verifyPurchase');
        final result = await callable.call(<String, dynamic>{
          'productId': purchase.productID,
          'purchaseToken': purchase.verificationData.serverVerificationData,
          'source': purchase.verificationData.source,
          'packageName': _packageName,
          'deviceHash': fingerprint.deviceHash,
          'fingerprintSignature': fingerprint.fingerprintSignature,
          'request': request.toJson(),
        });
        final data = Map<String, dynamic>.from(result.data as Map);
        if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
          _purchaseCompleter!.complete(
            RewardResult(
              success: data['success'] == true,
              coinsAdded: (data['coinsAdded'] as num?)?.toInt() ?? 0,
              balance: (data['balance'] as num?)?.toInt() ?? 0,
              message: data['message']?.toString() ?? '',
            ),
          );
        }
      }
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
