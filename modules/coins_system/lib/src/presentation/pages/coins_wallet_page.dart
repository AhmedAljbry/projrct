import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../di/coins_injection.dart';
import '../../domain/entities/coins_models.dart';
import '../bloc/coins_wallet_bloc.dart';
import '../widgets/coins_widgets.dart';

class CoinsWalletPage extends StatefulWidget {
  const CoinsWalletPage({
    super.key,
    required this.userId,
    this.bloc,
    this.onPackageSelected,
  });

  final String userId;
  final CoinsWalletBloc? bloc;
  final ValueChanged<CoinPackage>? onPackageSelected;

  @override
  State<CoinsWalletPage> createState() => _CoinsWalletPageState();
}

class _CoinsWalletPageState extends State<CoinsWalletPage> {
  late final CoinsWalletBloc _bloc;
  late final bool _ownsBloc;

  @override
  void initState() {
    super.initState();
    _ownsBloc = widget.bloc == null;
    _bloc = widget.bloc ?? coinsLocator<CoinsWalletBloc>();
    _bloc.add(CoinsWalletStarted(widget.userId));
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoinsWalletBloc>.value(
      value: _bloc,
      child: BlocListener<CoinsWalletBloc, CoinsWalletState>(
        listenWhen: (CoinsWalletState previous, CoinsWalletState current) =>
            previous.transientMessage != current.transientMessage &&
            current.transientMessage != null,
        listener: (BuildContext context, CoinsWalletState state) {
          final String message = state.transientMessage!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F7FB),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Coins Wallet',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: <Widget>[
                IconButton(
                  onPressed: () => _bloc.add(const CoinsWalletRefreshed()),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const TabBar(
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: Color(0xFF111827),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Color(0xFF6B7280),
                    tabs: <Widget>[
                      Tab(text: 'Overview'),
                      Tab(text: 'Store'),
                      Tab(text: 'History'),
                    ],
                  ),
                ),
              ),
            ),
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFFF4F7FB), Color(0xFFE9EEF8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                top: false,
                child: BlocBuilder<CoinsWalletBloc, CoinsWalletState>(
                  builder: (BuildContext context, CoinsWalletState state) {
                    if (state.overview == null &&
                        (state.status == CoinsWalletStatus.initial ||
                            state.status == CoinsWalletStatus.loading)) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.overview == null &&
                        state.status == CoinsWalletStatus.failure) {
                      return _ErrorState(
                        message: state.failure?.message ?? 'Unable to load wallet.',
                        onRetry: () => _bloc.add(const CoinsWalletRefreshed()),
                      );
                    }

                    final WalletOverview? overview = state.overview;
                    if (overview == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return TabBarView(
                      children: <Widget>[
                        _OverviewTab(
                          overview: overview,
                          onSpendRequested: (PremiumFeature feature) => _bloc.add(
                            CoinsWalletPremiumFeatureRequested(
                              SpendCoinsCommand(
                                userId: widget.userId,
                                featureId: feature.featureId,
                                referenceId:
                                    '${feature.featureId}:${DateTime.now().millisecondsSinceEpoch}',
                                amount: feature.coinCost,
                                currentAvailableBalance: overview.balance.available,
                              ),
                            ),
                          ),
                        ),
                        _StoreTab(
                          overview: overview,
                          onPackageSelected: (CoinPackage package) {
                            if (widget.onPackageSelected != null) {
                              widget.onPackageSelected!(package);
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Package "${package.title}" selected. Hook your billing flow here.',
                                ),
                              ),
                            );
                          },
                        ),
                        TransactionHistoryList(
                          items: state.history,
                          hasMore: state.hasMoreHistory,
                          isLoadingMore: state.isLoadingMore,
                          onLoadMore: () =>
                              _bloc.add(const CoinsWalletHistoryRequested()),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.overview,
    required this.onSpendRequested,
  });

  final WalletOverview overview;
  final ValueChanged<PremiumFeature> onSpendRequested;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PremiumWalletHeader(
            balance: overview.balance,
            userId: overview.userId,
            riskFlags: overview.riskFlags,
          ),
          const SizedBox(height: 24),
          const Text(
            'Premium features',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101827),
            ),
          ),
          const SizedBox(height: 14),
          PremiumFeatureList(
            features: overview.premiumFeatures,
            onSpendRequested: onSpendRequested,
          ),
        ],
      ),
    );
  }
}

class _StoreTab extends StatelessWidget {
  const _StoreTab({
    required this.overview,
    required this.onPackageSelected,
  });

  final WalletOverview overview;
  final ValueChanged<CoinPackage> onPackageSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PremiumWalletHeader(
            balance: overview.balance,
            userId: overview.userId,
            riskFlags: overview.riskFlags,
          ),
          const SizedBox(height: 24),
          const Text(
            'Coin packages',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Offer localized pricing and keep server-side SKU verification authoritative.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          CoinPackageGrid(
            packages: overview.packages,
            onPackageSelected: onPackageSelected,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline_rounded, size: 44, color: Color(0xFFD92D20)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF101827),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
