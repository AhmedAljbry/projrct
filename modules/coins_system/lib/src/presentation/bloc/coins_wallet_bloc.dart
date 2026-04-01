import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/failure.dart';
import '../../domain/entities/coins_models.dart';
import '../../domain/usecases/get_transaction_history_use_case.dart';
import '../../domain/usecases/get_wallet_overview_use_case.dart';
import '../../domain/usecases/spend_coins_use_case.dart';

const Object _coinsWalletUnset = Object();

enum CoinsWalletStatus {
  initial,
  loading,
  success,
  failure,
}

@immutable
abstract class CoinsWalletEvent {
  const CoinsWalletEvent();
}

class CoinsWalletStarted extends CoinsWalletEvent {
  const CoinsWalletStarted(this.userId);

  final String userId;
}

class CoinsWalletRefreshed extends CoinsWalletEvent {
  const CoinsWalletRefreshed();
}

class CoinsWalletHistoryRequested extends CoinsWalletEvent {
  const CoinsWalletHistoryRequested();
}

class CoinsWalletPremiumFeatureRequested extends CoinsWalletEvent {
  const CoinsWalletPremiumFeatureRequested(this.command);

  final SpendCoinsCommand command;
}

@immutable
class CoinsWalletState {
  const CoinsWalletState({
    required this.status,
    this.userId,
    this.overview,
    this.history = const <CoinTransaction>[],
    this.nextCursor,
    this.hasMoreHistory = false,
    this.isLoadingMore = false,
    this.failure,
    this.transientMessage,
  });

  factory CoinsWalletState.initial() => const CoinsWalletState(
        status: CoinsWalletStatus.initial,
      );

  final CoinsWalletStatus status;
  final String? userId;
  final WalletOverview? overview;
  final List<CoinTransaction> history;
  final String? nextCursor;
  final bool hasMoreHistory;
  final bool isLoadingMore;
  final Failure? failure;
  final String? transientMessage;

  CoinsWalletState copyWith({
    CoinsWalletStatus? status,
    String? userId,
    Object? overview = _coinsWalletUnset,
    List<CoinTransaction>? history,
    Object? nextCursor = _coinsWalletUnset,
    bool? hasMoreHistory,
    bool? isLoadingMore,
    Object? failure = _coinsWalletUnset,
    Object? transientMessage = _coinsWalletUnset,
  }) {
    return CoinsWalletState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      overview: overview == _coinsWalletUnset ? this.overview : overview as WalletOverview?,
      history: history ?? this.history,
      nextCursor: nextCursor == _coinsWalletUnset ? this.nextCursor : nextCursor as String?,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: failure == _coinsWalletUnset ? this.failure : failure as Failure?,
      transientMessage: transientMessage == _coinsWalletUnset
          ? this.transientMessage
          : transientMessage as String?,
    );
  }
}

@injectable
class CoinsWalletBloc extends Bloc<CoinsWalletEvent, CoinsWalletState> {
  CoinsWalletBloc(
    this._getWalletOverviewUseCase,
    this._getTransactionHistoryUseCase,
    this._spendCoinsUseCase,
  ) : super(CoinsWalletState.initial()) {
    on<CoinsWalletStarted>(_onStarted);
    on<CoinsWalletRefreshed>(_onRefreshed);
    on<CoinsWalletHistoryRequested>(_onHistoryRequested);
    on<CoinsWalletPremiumFeatureRequested>(_onPremiumFeatureRequested);
  }

  final GetWalletOverviewUseCase _getWalletOverviewUseCase;
  final GetTransactionHistoryUseCase _getTransactionHistoryUseCase;
  final SpendCoinsUseCase _spendCoinsUseCase;

  Future<void> _onStarted(
    CoinsWalletStarted event,
    Emitter<CoinsWalletState> emit,
  ) async {
    await _loadWallet(event.userId, emit);
  }

  Future<void> _onRefreshed(
    CoinsWalletRefreshed event,
    Emitter<CoinsWalletState> emit,
  ) async {
    final String? userId = state.userId;
    if (userId == null) {
      return;
    }
    await _loadWallet(userId, emit);
  }

  Future<void> _onHistoryRequested(
    CoinsWalletHistoryRequested event,
    Emitter<CoinsWalletState> emit,
  ) async {
    final String? userId = state.userId;
    if (userId == null || state.isLoadingMore || !state.hasMoreHistory) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingMore: true,
        failure: null,
        transientMessage: null,
      ),
    );

    final result = await _getTransactionHistoryUseCase(
      TransactionHistoryQuery(
        userId: userId,
        cursor: state.nextCursor,
        limit: 20,
      ),
    );

    result.fold(
      (Failure failure) {
        emit(
          state.copyWith(
            isLoadingMore: false,
            failure: failure,
            transientMessage: failure.message,
          ),
        );
      },
      (TransactionPage page) {
        emit(
          state.copyWith(
            status: CoinsWalletStatus.success,
            history: <CoinTransaction>[...state.history, ...page.items],
            nextCursor: page.nextCursor,
            hasMoreHistory: page.hasMore,
            isLoadingMore: false,
            failure: null,
          ),
        );
      },
    );
  }

  Future<void> _onPremiumFeatureRequested(
    CoinsWalletPremiumFeatureRequested event,
    Emitter<CoinsWalletState> emit,
  ) async {
    final WalletOverview? overview = state.overview;
    if (overview == null) {
      return;
    }

    final result = await _spendCoinsUseCase(event.command);
    result.fold(
      (Failure failure) {
        emit(
          state.copyWith(
            status: CoinsWalletStatus.failure,
            failure: failure,
            transientMessage: failure.message,
          ),
        );
      },
      (LedgerMutationResult mutation) {
        final List<CoinTransaction> updatedRecentTransactions = <CoinTransaction>[
          mutation.transaction,
          ...overview.recentTransactions.where(
            (CoinTransaction item) => item.id != mutation.transaction.id,
          ),
        ].take(8).toList();

        emit(
          state.copyWith(
            status: CoinsWalletStatus.success,
            overview: overview.copyWith(
              balance: mutation.walletBalance,
              recentTransactions: updatedRecentTransactions,
            ),
            history: <CoinTransaction>[
              mutation.transaction,
              ...state.history.where(
                (CoinTransaction item) => item.id != mutation.transaction.id,
              ),
            ],
            failure: null,
            transientMessage: mutation.message ??
                (mutation.reviewStatus == RewardReviewStatus.pendingReview
                    ? 'Spend request submitted for review.'
                    : 'Premium feature unlocked successfully.'),
          ),
        );
      },
    );
  }

  Future<void> _loadWallet(
    String userId,
    Emitter<CoinsWalletState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CoinsWalletStatus.loading,
        userId: userId,
        failure: null,
        transientMessage: null,
      ),
    );

    final overviewResult = await _getWalletOverviewUseCase(userId);
    await overviewResult.fold(
      (Failure failure) async {
        emit(
          state.copyWith(
            status: CoinsWalletStatus.failure,
            failure: failure,
            transientMessage: failure.message,
            overview: null,
          ),
        );
      },
      (WalletOverview overview) async {
        final historyResult = await _getTransactionHistoryUseCase(
          TransactionHistoryQuery(userId: userId, limit: 20),
        );

        historyResult.fold(
          (Failure failure) {
            emit(
              state.copyWith(
                status: CoinsWalletStatus.success,
                overview: overview,
                history: overview.recentTransactions,
                nextCursor: null,
                hasMoreHistory: false,
                isLoadingMore: false,
                failure: null,
                transientMessage: failure.message,
              ),
            );
          },
          (TransactionPage page) {
            emit(
              state.copyWith(
                status: CoinsWalletStatus.success,
                overview: overview,
                history: page.items,
                nextCursor: page.nextCursor,
                hasMoreHistory: page.hasMore,
                isLoadingMore: false,
                failure: null,
              ),
            );
          },
        );
      },
    );
  }
}
