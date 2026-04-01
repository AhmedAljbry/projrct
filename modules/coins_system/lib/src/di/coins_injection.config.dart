// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/security/anti_fraud_policy.dart' as _i413;
import '../core/security/local_claim_guard.dart' as _i877;
import '../data/remote/coins_api_service.dart' as _i322;
import '../data/remote/coins_remote_data_source.dart' as _i375;
import '../data/repositories/coins_repository_impl.dart' as _i973;
import '../domain/repositories/coins_repository.dart' as _i9;
import '../domain/usecases/claim_rewarded_ad_use_case.dart' as _i833;
import '../domain/usecases/claim_task_reward_use_case.dart' as _i389;
import '../domain/usecases/get_transaction_history_use_case.dart' as _i704;
import '../domain/usecases/get_wallet_overview_use_case.dart' as _i147;
import '../domain/usecases/spend_coins_use_case.dart' as _i1055;
import '../domain/usecases/verify_coin_purchase_use_case.dart' as _i493;
import '../presentation/bloc/coins_wallet_bloc.dart' as _i777;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt initCoinsLocator({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i375.CoinsRemoteDataSource>(
        () => _i375.CoinsRemoteDataSourceImpl(gh<_i322.CoinsApiService>()));
    gh.lazySingleton<_i877.LocalClaimGuard>(
        () => _i877.InMemoryLocalClaimGuard());
    gh.lazySingleton<_i9.CoinsRepository>(
        () => _i973.CoinsRepositoryImpl(gh<_i375.CoinsRemoteDataSource>()));
    gh.factory<_i833.ClaimRewardedAdUseCase>(() => _i833.ClaimRewardedAdUseCase(
          gh<_i9.CoinsRepository>(),
          gh<_i413.AntiFraudPolicy>(),
          gh<_i877.LocalClaimGuard>(),
        ));
    gh.factory<_i389.ClaimTaskRewardUseCase>(() => _i389.ClaimTaskRewardUseCase(
          gh<_i9.CoinsRepository>(),
          gh<_i413.AntiFraudPolicy>(),
          gh<_i877.LocalClaimGuard>(),
        ));
    gh.factory<_i1055.SpendCoinsUseCase>(() => _i1055.SpendCoinsUseCase(
          gh<_i9.CoinsRepository>(),
          gh<_i413.AntiFraudPolicy>(),
          gh<_i877.LocalClaimGuard>(),
        ));
    gh.factory<_i493.VerifyCoinPurchaseUseCase>(
        () => _i493.VerifyCoinPurchaseUseCase(
              gh<_i9.CoinsRepository>(),
              gh<_i413.AntiFraudPolicy>(),
              gh<_i877.LocalClaimGuard>(),
            ));
    gh.factory<_i704.GetTransactionHistoryUseCase>(
        () => _i704.GetTransactionHistoryUseCase(gh<_i9.CoinsRepository>()));
    gh.factory<_i147.GetWalletOverviewUseCase>(
        () => _i147.GetWalletOverviewUseCase(gh<_i9.CoinsRepository>()));
    gh.factory<_i777.CoinsWalletBloc>(() => _i777.CoinsWalletBloc(
          gh<_i147.GetWalletOverviewUseCase>(),
          gh<_i704.GetTransactionHistoryUseCase>(),
          gh<_i1055.SpendCoinsUseCase>(),
        ));
    return this;
  }
}
