import 'package:freezed_annotation/freezed_annotation.dart';

part 'coins_models.freezed.dart';
part 'coins_models.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum CoinTransactionDirection {
  credit,
  debit,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum CoinTransactionType {
  taskReward,
  rewardedAd,
  purchase,
  premiumSpend,
  dailyReward,
  referralBonus,
  promoCode,
  bonus,
  adjustment,
  reversal,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum LedgerEntryStatus {
  pending,
  settled,
  reversed,
  held,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum RewardReviewStatus {
  approved,
  pendingReview,
  rejected,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum RiskSeverity {
  low,
  medium,
  high,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum AdNetworkType {
  admob,
  appLovin,
  ironSource,
  unityAds,
  custom,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum StoreProvider {
  googlePlay,
  appStore,
  stripe,
  web,
}

@freezed
class WalletBalance with _$WalletBalance {
  const factory WalletBalance({
    @Default(0) int available,
    @Default(0) int reserved,
    @Default(0) int lifetimeEarned,
    @Default(0) int lifetimeSpent,
    required DateTime updatedAt,
  }) = _WalletBalance;

  factory WalletBalance.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceFromJson(json);
}

@freezed
class CoinPackage with _$CoinPackage {
  const factory CoinPackage({
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
  }) = _CoinPackage;

  factory CoinPackage.fromJson(Map<String, dynamic> json) =>
      _$CoinPackageFromJson(json);
}

@freezed
class PremiumFeature with _$PremiumFeature {
  const factory PremiumFeature({
    required String featureId,
    required String title,
    required String description,
    required int coinCost,
    required String category,
    @Default(false) bool isLimitedTime,
  }) = _PremiumFeature;

  factory PremiumFeature.fromJson(Map<String, dynamic> json) =>
      _$PremiumFeatureFromJson(json);
}

@freezed
class RiskFlag with _$RiskFlag {
  const factory RiskFlag({
    required String code,
    required String title,
    required String description,
    required RiskSeverity severity,
    @Default(false) bool blocksPayout,
  }) = _RiskFlag;

  factory RiskFlag.fromJson(Map<String, dynamic> json) =>
      _$RiskFlagFromJson(json);
}

@freezed
class CoinTransaction with _$CoinTransaction {
  const factory CoinTransaction({
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
  }) = _CoinTransaction;

  factory CoinTransaction.fromJson(Map<String, dynamic> json) =>
      _$CoinTransactionFromJson(json);
}

@freezed
class TransactionPage with _$TransactionPage {
  const factory TransactionPage({
    @Default(<CoinTransaction>[]) List<CoinTransaction> items,
    String? nextCursor,
    @Default(false) bool hasMore,
  }) = _TransactionPage;

  factory TransactionPage.fromJson(Map<String, dynamic> json) =>
      _$TransactionPageFromJson(json);
}

@freezed
class WalletOverview with _$WalletOverview {
  const factory WalletOverview({
    required String userId,
    required WalletBalance balance,
    @Default(<CoinPackage>[]) List<CoinPackage> packages,
    @Default(<PremiumFeature>[]) List<PremiumFeature> premiumFeatures,
    @Default(<CoinTransaction>[]) List<CoinTransaction> recentTransactions,
    @Default(<RiskFlag>[]) List<RiskFlag> riskFlags,
  }) = _WalletOverview;

  factory WalletOverview.fromJson(Map<String, dynamic> json) =>
      _$WalletOverviewFromJson(json);
}

@freezed
class TransactionHistoryQuery with _$TransactionHistoryQuery {
  const factory TransactionHistoryQuery({
    required String userId,
    String? cursor,
    @Default(20) int limit,
  }) = _TransactionHistoryQuery;

  factory TransactionHistoryQuery.fromJson(Map<String, dynamic> json) =>
      _$TransactionHistoryQueryFromJson(json);
}

@freezed
class TaskRewardClaim with _$TaskRewardClaim {
  const TaskRewardClaim._();

  const factory TaskRewardClaim({
    required String userId,
    required String taskId,
    required String completionId,
    required int rewardAmount,
    required DateTime completedAt,
    required String serverProof,
    required String deviceAttestationToken,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _TaskRewardClaim;

  String get idempotencyKey => '$userId:$taskId:$completionId';

  factory TaskRewardClaim.fromJson(Map<String, dynamic> json) =>
      _$TaskRewardClaimFromJson(json);
}

@freezed
class RewardedAdClaim with _$RewardedAdClaim {
  const RewardedAdClaim._();

  const factory RewardedAdClaim({
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
  }) = _RewardedAdClaim;

  String get idempotencyKey => '$userId:${adNetwork.name}:$networkTransactionId';

  factory RewardedAdClaim.fromJson(Map<String, dynamic> json) =>
      _$RewardedAdClaimFromJson(json);
}

@freezed
class PurchaseVerificationRequest with _$PurchaseVerificationRequest {
  const PurchaseVerificationRequest._();

  const factory PurchaseVerificationRequest({
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
  }) = _PurchaseVerificationRequest;

  String get idempotencyKey => '$userId:${store.name}:$transactionId';

  factory PurchaseVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$PurchaseVerificationRequestFromJson(json);
}

@freezed
class SpendCoinsCommand with _$SpendCoinsCommand {
  const SpendCoinsCommand._();

  const factory SpendCoinsCommand({
    required String userId,
    required String featureId,
    required String referenceId,
    required int amount,
    required int currentAvailableBalance,
    @Default('') String idempotencyKey,
    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _SpendCoinsCommand;

  String get resolvedIdempotencyKey =>
      idempotencyKey.isNotEmpty ? idempotencyKey : '$userId:$featureId:$referenceId';

  factory SpendCoinsCommand.fromJson(Map<String, dynamic> json) =>
      _$SpendCoinsCommandFromJson(json);
}

@freezed
class LedgerMutationResult with _$LedgerMutationResult {
  const factory LedgerMutationResult({
    required WalletBalance walletBalance,
    required CoinTransaction transaction,
    required RewardReviewStatus reviewStatus,
    required String idempotencyKey,
    @Default(true) bool shouldRefreshHistory,
    String? message,
  }) = _LedgerMutationResult;

  factory LedgerMutationResult.fromJson(Map<String, dynamic> json) =>
      _$LedgerMutationResultFromJson(json);
}
