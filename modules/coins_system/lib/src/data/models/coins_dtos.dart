import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/coins_models.dart';

part 'coins_dtos.freezed.dart';
part 'coins_dtos.g.dart';

@freezed
class WalletBalanceDto with _$WalletBalanceDto {
  const WalletBalanceDto._();

  const factory WalletBalanceDto({
    @Default(0) int available,
    @Default(0) int reserved,
    @Default(0) int lifetimeEarned,
    @Default(0) int lifetimeSpent,
    required DateTime updatedAt,
  }) = _WalletBalanceDto;

  WalletBalance toDomain() => WalletBalance(
        available: available,
        reserved: reserved,
        lifetimeEarned: lifetimeEarned,
        lifetimeSpent: lifetimeSpent,
        updatedAt: updatedAt,
      );

  factory WalletBalanceDto.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceDtoFromJson(json);
}

@freezed
class CoinPackageDto with _$CoinPackageDto {
  const CoinPackageDto._();

  const factory CoinPackageDto({
    required String sku,
    required String title,
    required String subtitle,
    required int coins,
    @Default(0) int bonusCoins,
    required String priceLabel,
    required int priceMicros,
    required String currencyCode,
    required String productId,
    @Default(false) bool isHighlighted,
    String? badge,
  }) = _CoinPackageDto;

  CoinPackage toDomain() => CoinPackage(
        sku: sku,
        title: title,
        subtitle: subtitle,
        coins: coins,
        bonusCoins: bonusCoins,
        priceLabel: priceLabel,
        priceMicros: priceMicros,
        currencyCode: currencyCode,
        productId: productId,
        isHighlighted: isHighlighted,
        badge: badge,
      );

  factory CoinPackageDto.fromJson(Map<String, dynamic> json) =>
      _$CoinPackageDtoFromJson(json);
}

@freezed
class PremiumFeatureDto with _$PremiumFeatureDto {
  const PremiumFeatureDto._();

  const factory PremiumFeatureDto({
    required String featureId,
    required String title,
    required String description,
    required int coinCost,
    required String category,
    @Default(false) bool isLimitedTime,
  }) = _PremiumFeatureDto;

  PremiumFeature toDomain() => PremiumFeature(
        featureId: featureId,
        title: title,
        description: description,
        coinCost: coinCost,
        category: category,
        isLimitedTime: isLimitedTime,
      );

  factory PremiumFeatureDto.fromJson(Map<String, dynamic> json) =>
      _$PremiumFeatureDtoFromJson(json);
}

@freezed
class RiskFlagDto with _$RiskFlagDto {
  const RiskFlagDto._();

  const factory RiskFlagDto({
    required String code,
    required String title,
    required String description,
    required RiskSeverity severity,
    @Default(false) bool blocksPayout,
  }) = _RiskFlagDto;

  RiskFlag toDomain() => RiskFlag(
        code: code,
        title: title,
        description: description,
        severity: severity,
        blocksPayout: blocksPayout,
      );

  factory RiskFlagDto.fromJson(Map<String, dynamic> json) =>
      _$RiskFlagDtoFromJson(json);
}

@freezed
class CoinTransactionDto with _$CoinTransactionDto {
  const CoinTransactionDto._();

  const factory CoinTransactionDto({
    required String id,
    required String userId,
    required CoinTransactionDirection direction,
    required CoinTransactionType type,
    required LedgerEntryStatus status,
    required int amount,
    required int balanceAfter,
    required String title,
    required String referenceId,
    required DateTime occurredAt,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _CoinTransactionDto;

  CoinTransaction toDomain() => CoinTransaction(
        id: id,
        userId: userId,
        direction: direction,
        type: type,
        status: status,
        amount: amount,
        balanceAfter: balanceAfter,
        title: title,
        referenceId: referenceId,
        occurredAt: occurredAt,
        metadata: metadata,
      );

  factory CoinTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$CoinTransactionDtoFromJson(json);
}

@freezed
class TransactionPageDto with _$TransactionPageDto {
  const TransactionPageDto._();

  const factory TransactionPageDto({
    @Default(<CoinTransactionDto>[]) List<CoinTransactionDto> items,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _TransactionPageDto;

  TransactionPage toDomain() => TransactionPage(
        items: items.map((CoinTransactionDto item) => item.toDomain()).toList(),
        nextCursor: nextCursor,
        hasMore: hasMore,
      );

  factory TransactionPageDto.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageDtoFromJson(json);
}

@freezed
class WalletOverviewDto with _$WalletOverviewDto {
  const WalletOverviewDto._();

  const factory WalletOverviewDto({
    required String userId,
    required WalletBalanceDto balance,
    @Default(<CoinPackageDto>[]) List<CoinPackageDto> packages,
    @Default(<PremiumFeatureDto>[]) List<PremiumFeatureDto> premiumFeatures,
    @Default(<CoinTransactionDto>[]) List<CoinTransactionDto> recentTransactions,
    @Default(<RiskFlagDto>[]) List<RiskFlagDto> riskFlags,
  }) = _WalletOverviewDto;

  WalletOverview toDomain() => WalletOverview(
        userId: userId,
        balance: balance.toDomain(),
        packages: packages.map((CoinPackageDto item) => item.toDomain()).toList(),
        premiumFeatures: premiumFeatures
            .map((PremiumFeatureDto item) => item.toDomain())
            .toList(),
        recentTransactions: recentTransactions
            .map((CoinTransactionDto item) => item.toDomain())
            .toList(),
        riskFlags: riskFlags.map((RiskFlagDto item) => item.toDomain()).toList(),
      );

  factory WalletOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$WalletOverviewDtoFromJson(json);
}

@freezed
class LedgerMutationResultDto with _$LedgerMutationResultDto {
  const LedgerMutationResultDto._();

  const factory LedgerMutationResultDto({
    required WalletBalanceDto walletBalance,
    required CoinTransactionDto transaction,
    required RewardReviewStatus reviewStatus,
    required String idempotencyKey,
    @Default(true) bool shouldRefreshHistory,
    String? message,
  }) = _LedgerMutationResultDto;

  LedgerMutationResult toDomain() => LedgerMutationResult(
        walletBalance: walletBalance.toDomain(),
        transaction: transaction.toDomain(),
        reviewStatus: reviewStatus,
        idempotencyKey: idempotencyKey,
        shouldRefreshHistory: shouldRefreshHistory,
        message: message,
      );

  factory LedgerMutationResultDto.fromJson(Map<String, dynamic> json) =>
      _$LedgerMutationResultDtoFromJson(json);
}

@freezed
class TaskRewardClaimRequestDto with _$TaskRewardClaimRequestDto {
  const factory TaskRewardClaimRequestDto({
    required String userId,
    required String taskId,
    required String completionId,
    required int rewardAmount,
    required DateTime completedAt,
    required String serverProof,
    required String deviceAttestationToken,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _TaskRewardClaimRequestDto;

  factory TaskRewardClaimRequestDto.fromDomain(TaskRewardClaim claim) =>
      TaskRewardClaimRequestDto(
        userId: claim.userId,
        taskId: claim.taskId,
        completionId: claim.completionId,
        rewardAmount: claim.rewardAmount,
        completedAt: claim.completedAt,
        serverProof: claim.serverProof,
        deviceAttestationToken: claim.deviceAttestationToken,
        metadata: claim.metadata,
      );

  factory TaskRewardClaimRequestDto.fromJson(Map<String, dynamic> json) =>
      _$TaskRewardClaimRequestDtoFromJson(json);
}

@freezed
class RewardedAdClaimRequestDto with _$RewardedAdClaimRequestDto {
  const factory RewardedAdClaimRequestDto({
    required String userId,
    required String adUnitId,
    required AdNetworkType adNetwork,
    required String sessionId,
    required String networkTransactionId,
    required String rewardNonce,
    required int rewardAmount,
    required int watchedMillis,
    required DateTime completedAt,
    required String serverSideVerificationToken,
    required String deviceAttestationToken,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _RewardedAdClaimRequestDto;

  factory RewardedAdClaimRequestDto.fromDomain(RewardedAdClaim claim) =>
      RewardedAdClaimRequestDto(
        userId: claim.userId,
        adUnitId: claim.adUnitId,
        adNetwork: claim.adNetwork,
        sessionId: claim.sessionId,
        networkTransactionId: claim.networkTransactionId,
        rewardNonce: claim.rewardNonce,
        rewardAmount: claim.rewardAmount,
        watchedMillis: claim.watchedMillis,
        completedAt: claim.completedAt,
        serverSideVerificationToken: claim.serverSideVerificationToken,
        deviceAttestationToken: claim.deviceAttestationToken,
        metadata: claim.metadata,
      );

  factory RewardedAdClaimRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RewardedAdClaimRequestDtoFromJson(json);
}

@freezed
class PurchaseVerificationRequestDto with _$PurchaseVerificationRequestDto {
  const factory PurchaseVerificationRequestDto({
    required String userId,
    required String packageSku,
    required String productId,
    required StoreProvider store,
    required String transactionId,
    required String purchaseToken,
    required String signedPayload,
    required int priceMicros,
    required String currencyCode,
    required DateTime completedAt,
    required String deviceAttestationToken,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _PurchaseVerificationRequestDto;

  factory PurchaseVerificationRequestDto.fromDomain(
    PurchaseVerificationRequest request,
  ) =>
      PurchaseVerificationRequestDto(
        userId: request.userId,
        packageSku: request.packageSku,
        productId: request.productId,
        store: request.store,
        transactionId: request.transactionId,
        purchaseToken: request.purchaseToken,
        signedPayload: request.signedPayload,
        priceMicros: request.priceMicros,
        currencyCode: request.currencyCode,
        completedAt: request.completedAt,
        deviceAttestationToken: request.deviceAttestationToken,
        metadata: request.metadata,
      );

  factory PurchaseVerificationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PurchaseVerificationRequestDtoFromJson(json);
}

@freezed
class SpendCoinsRequestDto with _$SpendCoinsRequestDto {
  const factory SpendCoinsRequestDto({
    required String userId,
    required String featureId,
    required String referenceId,
    required int amount,
    required String idempotencyKey,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _SpendCoinsRequestDto;

  factory SpendCoinsRequestDto.fromDomain(SpendCoinsCommand command) =>
      SpendCoinsRequestDto(
        userId: command.userId,
        featureId: command.featureId,
        referenceId: command.referenceId,
        amount: command.amount,
        idempotencyKey: command.resolvedIdempotencyKey,
        metadata: command.metadata,
      );

  factory SpendCoinsRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SpendCoinsRequestDtoFromJson(json);
}
