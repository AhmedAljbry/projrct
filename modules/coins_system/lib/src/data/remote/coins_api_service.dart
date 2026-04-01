import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/coins_dtos.dart';

part 'coins_api_service.g.dart';

@RestApi()
abstract class CoinsApiService {
  factory CoinsApiService(Dio dio, {String baseUrl}) = _CoinsApiService;

  @GET('/v1/coins/wallets/{userId}')
  Future<WalletOverviewDto> getWalletOverview(
    @Path('userId') String userId,
  );

  @GET('/v1/coins/wallets/{userId}/transactions')
  Future<TransactionPageDto> getTransactionHistory(
    @Path('userId') String userId,
    @Query('cursor') String? cursor,
    @Query('limit') int limit,
  );

  @POST('/v1/coins/rewards/tasks/claim')
  Future<LedgerMutationResultDto> claimTaskReward(
    @Body() Map<String, dynamic> body,
    @Header('X-Idempotency-Key') String idempotencyKey,
  );

  @POST('/v1/coins/rewards/ads/claim')
  Future<LedgerMutationResultDto> claimRewardedAd(
    @Body() Map<String, dynamic> body,
    @Header('X-Idempotency-Key') String idempotencyKey,
  );

  @POST('/v1/coins/purchases/verify')
  Future<LedgerMutationResultDto> verifyPurchase(
    @Body() Map<String, dynamic> body,
    @Header('X-Idempotency-Key') String idempotencyKey,
  );

  @POST('/v1/coins/spend')
  Future<LedgerMutationResultDto> spendCoins(
    @Body() Map<String, dynamic> body,
    @Header('X-Idempotency-Key') String idempotencyKey,
  );
}
