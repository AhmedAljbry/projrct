// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coins_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletBalanceImpl _$$WalletBalanceImplFromJson(Map<String, dynamic> json) =>
    _$WalletBalanceImpl(
      available: (json['available'] as num?)?.toInt() ?? 0,
      reserved: (json['reserved'] as num?)?.toInt() ?? 0,
      lifetimeEarned: (json['lifetimeEarned'] as num?)?.toInt() ?? 0,
      lifetimeSpent: (json['lifetimeSpent'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$WalletBalanceImplToJson(_$WalletBalanceImpl instance) =>
    <String, dynamic>{
      'available': instance.available,
      'reserved': instance.reserved,
      'lifetimeEarned': instance.lifetimeEarned,
      'lifetimeSpent': instance.lifetimeSpent,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$CoinPackageImpl _$$CoinPackageImplFromJson(Map<String, dynamic> json) =>
    _$CoinPackageImpl(
      sku: json['sku'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      coins: (json['coins'] as num).toInt(),
      bonusCoins: (json['bonusCoins'] as num?)?.toInt() ?? 0,
      priceLabel: json['priceLabel'] as String,
      priceMicros: (json['priceMicros'] as num).toInt(),
      currencyCode: json['currencyCode'] as String,
      productId: json['productId'] as String,
      isHighlighted: json['isHighlighted'] as bool? ?? false,
      badge: json['badge'] as String?,
    );

Map<String, dynamic> _$$CoinPackageImplToJson(_$CoinPackageImpl instance) =>
    <String, dynamic>{
      'sku': instance.sku,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'coins': instance.coins,
      'bonusCoins': instance.bonusCoins,
      'priceLabel': instance.priceLabel,
      'priceMicros': instance.priceMicros,
      'currencyCode': instance.currencyCode,
      'productId': instance.productId,
      'isHighlighted': instance.isHighlighted,
      'badge': instance.badge,
    };

_$PremiumFeatureImpl _$$PremiumFeatureImplFromJson(Map<String, dynamic> json) =>
    _$PremiumFeatureImpl(
      featureId: json['featureId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      coinCost: (json['coinCost'] as num).toInt(),
      category: json['category'] as String,
      isLimitedTime: json['isLimitedTime'] as bool? ?? false,
    );

Map<String, dynamic> _$$PremiumFeatureImplToJson(
        _$PremiumFeatureImpl instance) =>
    <String, dynamic>{
      'featureId': instance.featureId,
      'title': instance.title,
      'description': instance.description,
      'coinCost': instance.coinCost,
      'category': instance.category,
      'isLimitedTime': instance.isLimitedTime,
    };

_$RiskFlagImpl _$$RiskFlagImplFromJson(Map<String, dynamic> json) =>
    _$RiskFlagImpl(
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: $enumDecode(_$RiskSeverityEnumMap, json['severity']),
      blocksPayout: json['blocksPayout'] as bool? ?? false,
    );

Map<String, dynamic> _$$RiskFlagImplToJson(_$RiskFlagImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'title': instance.title,
      'description': instance.description,
      'severity': _$RiskSeverityEnumMap[instance.severity]!,
      'blocksPayout': instance.blocksPayout,
    };

const _$RiskSeverityEnumMap = {
  RiskSeverity.low: 'low',
  RiskSeverity.medium: 'medium',
  RiskSeverity.high: 'high',
};

_$CoinTransactionImpl _$$CoinTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$CoinTransactionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      direction:
          $enumDecode(_$CoinTransactionDirectionEnumMap, json['direction']),
      type: $enumDecode(_$CoinTransactionTypeEnumMap, json['type']),
      status: $enumDecode(_$LedgerEntryStatusEnumMap, json['status']),
      amount: (json['amount'] as num).toInt(),
      balanceAfter: (json['balanceAfter'] as num).toInt(),
      title: json['title'] as String,
      referenceId: json['referenceId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$CoinTransactionImplToJson(
        _$CoinTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'direction': _$CoinTransactionDirectionEnumMap[instance.direction]!,
      'type': _$CoinTransactionTypeEnumMap[instance.type]!,
      'status': _$LedgerEntryStatusEnumMap[instance.status]!,
      'amount': instance.amount,
      'balanceAfter': instance.balanceAfter,
      'title': instance.title,
      'referenceId': instance.referenceId,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$CoinTransactionDirectionEnumMap = {
  CoinTransactionDirection.credit: 'credit',
  CoinTransactionDirection.debit: 'debit',
};

const _$CoinTransactionTypeEnumMap = {
  CoinTransactionType.taskReward: 'task_reward',
  CoinTransactionType.rewardedAd: 'rewarded_ad',
  CoinTransactionType.purchase: 'purchase',
  CoinTransactionType.premiumSpend: 'premium_spend',
  CoinTransactionType.dailyReward: 'daily_reward',
  CoinTransactionType.referralBonus: 'referral_bonus',
  CoinTransactionType.promoCode: 'promo_code',
  CoinTransactionType.bonus: 'bonus',
  CoinTransactionType.adjustment: 'adjustment',
  CoinTransactionType.reversal: 'reversal',
};

const _$LedgerEntryStatusEnumMap = {
  LedgerEntryStatus.pending: 'pending',
  LedgerEntryStatus.settled: 'settled',
  LedgerEntryStatus.reversed: 'reversed',
  LedgerEntryStatus.held: 'held',
};

_$TransactionPageImpl _$$TransactionPageImplFromJson(
        Map<String, dynamic> json) =>
    _$TransactionPageImpl(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CoinTransaction>[],
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );

Map<String, dynamic> _$$TransactionPageImplToJson(
        _$TransactionPageImpl instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
      'hasMore': instance.hasMore,
    };

_$WalletOverviewImpl _$$WalletOverviewImplFromJson(Map<String, dynamic> json) =>
    _$WalletOverviewImpl(
      userId: json['userId'] as String,
      balance: WalletBalance.fromJson(json['balance'] as Map<String, dynamic>),
      packages: (json['packages'] as List<dynamic>?)
              ?.map((e) => CoinPackage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CoinPackage>[],
      premiumFeatures: (json['premiumFeatures'] as List<dynamic>?)
              ?.map((e) => PremiumFeature.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PremiumFeature>[],
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CoinTransaction>[],
      riskFlags: (json['riskFlags'] as List<dynamic>?)
              ?.map((e) => RiskFlag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RiskFlag>[],
    );

Map<String, dynamic> _$$WalletOverviewImplToJson(
        _$WalletOverviewImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'balance': instance.balance,
      'packages': instance.packages,
      'premiumFeatures': instance.premiumFeatures,
      'recentTransactions': instance.recentTransactions,
      'riskFlags': instance.riskFlags,
    };

_$TransactionHistoryQueryImpl _$$TransactionHistoryQueryImplFromJson(
        Map<String, dynamic> json) =>
    _$TransactionHistoryQueryImpl(
      userId: json['userId'] as String,
      cursor: json['cursor'] as String?,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$$TransactionHistoryQueryImplToJson(
        _$TransactionHistoryQueryImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'cursor': instance.cursor,
      'limit': instance.limit,
    };

_$TaskRewardClaimImpl _$$TaskRewardClaimImplFromJson(
        Map<String, dynamic> json) =>
    _$TaskRewardClaimImpl(
      userId: json['userId'] as String,
      taskId: json['taskId'] as String,
      completionId: json['completionId'] as String,
      rewardAmount: (json['rewardAmount'] as num).toInt(),
      completedAt: DateTime.parse(json['completedAt'] as String),
      serverProof: json['serverProof'] as String,
      deviceAttestationToken: json['deviceAttestationToken'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$TaskRewardClaimImplToJson(
        _$TaskRewardClaimImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'taskId': instance.taskId,
      'completionId': instance.completionId,
      'rewardAmount': instance.rewardAmount,
      'completedAt': instance.completedAt.toIso8601String(),
      'serverProof': instance.serverProof,
      'deviceAttestationToken': instance.deviceAttestationToken,
      'metadata': instance.metadata,
    };

_$RewardedAdClaimImpl _$$RewardedAdClaimImplFromJson(
        Map<String, dynamic> json) =>
    _$RewardedAdClaimImpl(
      userId: json['userId'] as String,
      adUnitId: json['adUnitId'] as String,
      adNetwork: $enumDecode(_$AdNetworkTypeEnumMap, json['adNetwork']),
      sessionId: json['sessionId'] as String,
      networkTransactionId: json['networkTransactionId'] as String,
      rewardNonce: json['rewardNonce'] as String,
      rewardAmount: (json['rewardAmount'] as num).toInt(),
      watchedMillis: (json['watchedMillis'] as num).toInt(),
      completedAt: DateTime.parse(json['completedAt'] as String),
      serverSideVerificationToken:
          json['serverSideVerificationToken'] as String,
      deviceAttestationToken: json['deviceAttestationToken'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$RewardedAdClaimImplToJson(
        _$RewardedAdClaimImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'adUnitId': instance.adUnitId,
      'adNetwork': _$AdNetworkTypeEnumMap[instance.adNetwork]!,
      'sessionId': instance.sessionId,
      'networkTransactionId': instance.networkTransactionId,
      'rewardNonce': instance.rewardNonce,
      'rewardAmount': instance.rewardAmount,
      'watchedMillis': instance.watchedMillis,
      'completedAt': instance.completedAt.toIso8601String(),
      'serverSideVerificationToken': instance.serverSideVerificationToken,
      'deviceAttestationToken': instance.deviceAttestationToken,
      'metadata': instance.metadata,
    };

const _$AdNetworkTypeEnumMap = {
  AdNetworkType.admob: 'admob',
  AdNetworkType.appLovin: 'app_lovin',
  AdNetworkType.ironSource: 'iron_source',
  AdNetworkType.unityAds: 'unity_ads',
  AdNetworkType.custom: 'custom',
};

_$PurchaseVerificationRequestImpl _$$PurchaseVerificationRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$PurchaseVerificationRequestImpl(
      userId: json['userId'] as String,
      packageSku: json['packageSku'] as String,
      productId: json['productId'] as String,
      store: $enumDecode(_$StoreProviderEnumMap, json['store']),
      transactionId: json['transactionId'] as String,
      purchaseToken: json['purchaseToken'] as String,
      signedPayload: json['signedPayload'] as String,
      priceMicros: (json['priceMicros'] as num).toInt(),
      currencyCode: json['currencyCode'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      deviceAttestationToken: json['deviceAttestationToken'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$PurchaseVerificationRequestImplToJson(
        _$PurchaseVerificationRequestImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'packageSku': instance.packageSku,
      'productId': instance.productId,
      'store': _$StoreProviderEnumMap[instance.store]!,
      'transactionId': instance.transactionId,
      'purchaseToken': instance.purchaseToken,
      'signedPayload': instance.signedPayload,
      'priceMicros': instance.priceMicros,
      'currencyCode': instance.currencyCode,
      'completedAt': instance.completedAt.toIso8601String(),
      'deviceAttestationToken': instance.deviceAttestationToken,
      'metadata': instance.metadata,
    };

const _$StoreProviderEnumMap = {
  StoreProvider.googlePlay: 'google_play',
  StoreProvider.appStore: 'app_store',
  StoreProvider.stripe: 'stripe',
  StoreProvider.web: 'web',
};

_$SpendCoinsCommandImpl _$$SpendCoinsCommandImplFromJson(
        Map<String, dynamic> json) =>
    _$SpendCoinsCommandImpl(
      userId: json['userId'] as String,
      featureId: json['featureId'] as String,
      referenceId: json['referenceId'] as String,
      amount: (json['amount'] as num).toInt(),
      currentAvailableBalance: (json['currentAvailableBalance'] as num).toInt(),
      idempotencyKey: json['idempotencyKey'] as String? ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    );

Map<String, dynamic> _$$SpendCoinsCommandImplToJson(
        _$SpendCoinsCommandImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'featureId': instance.featureId,
      'referenceId': instance.referenceId,
      'amount': instance.amount,
      'currentAvailableBalance': instance.currentAvailableBalance,
      'idempotencyKey': instance.idempotencyKey,
      'metadata': instance.metadata,
    };

_$LedgerMutationResultImpl _$$LedgerMutationResultImplFromJson(
        Map<String, dynamic> json) =>
    _$LedgerMutationResultImpl(
      walletBalance:
          WalletBalance.fromJson(json['walletBalance'] as Map<String, dynamic>),
      transaction:
          CoinTransaction.fromJson(json['transaction'] as Map<String, dynamic>),
      reviewStatus:
          $enumDecode(_$RewardReviewStatusEnumMap, json['reviewStatus']),
      idempotencyKey: json['idempotencyKey'] as String,
      shouldRefreshHistory: json['shouldRefreshHistory'] as bool? ?? true,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$$LedgerMutationResultImplToJson(
        _$LedgerMutationResultImpl instance) =>
    <String, dynamic>{
      'walletBalance': instance.walletBalance,
      'transaction': instance.transaction,
      'reviewStatus': _$RewardReviewStatusEnumMap[instance.reviewStatus]!,
      'idempotencyKey': instance.idempotencyKey,
      'shouldRefreshHistory': instance.shouldRefreshHistory,
      'message': instance.message,
    };

const _$RewardReviewStatusEnumMap = {
  RewardReviewStatus.approved: 'approved',
  RewardReviewStatus.pendingReview: 'pending_review',
  RewardReviewStatus.rejected: 'rejected',
};
