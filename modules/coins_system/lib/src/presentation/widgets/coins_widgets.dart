import 'package:flutter/material.dart';

import '../../domain/entities/coins_models.dart';

class PremiumWalletHeader extends StatelessWidget {
  const PremiumWalletHeader({
    super.key,
    required this.balance,
    required this.userId,
    required this.riskFlags,
  });

  final WalletBalance balance;
  final String userId;
  final List<RiskFlag> riskFlags;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF15243D), Color(0xFF0A0F1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33172139),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0x1AF4D58D),
                  border: Border.all(color: const Color(0x33F4D58D)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.monetization_on_rounded, color: Color(0xFFF4D58D)),
                    SizedBox(width: 8),
                    Text(
                      'Coins Wallet',
                      style: TextStyle(
                        color: Color(0xFFF7E7BE),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                userId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            balance.available.toString(),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Available balance',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              _WalletStatCard(label: 'Reserved', value: balance.reserved.toString()),
              const SizedBox(width: 12),
              _WalletStatCard(label: 'Earned', value: balance.lifetimeEarned.toString()),
              const SizedBox(width: 12),
              _WalletStatCard(label: 'Spent', value: balance.lifetimeSpent.toString()),
            ],
          ),
          if (riskFlags.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: riskFlags
                  .map((RiskFlag riskFlag) => RiskFlagPill(riskFlag: riskFlag))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class CoinPackageGrid extends StatelessWidget {
  const CoinPackageGrid({
    super.key,
    required this.packages,
    required this.onPackageSelected,
  });

  final List<CoinPackage> packages;
  final ValueChanged<CoinPackage> onPackageSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.92,
      ),
      itemCount: packages.length,
      itemBuilder: (BuildContext context, int index) {
        final CoinPackage item = packages[index];
        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => onPackageSelected(item),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: item.isHighlighted
                  ? const LinearGradient(
                      colors: <Color>[Color(0xFFF0D58A), Color(0xFFC29B38)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: <Color>[Color(0xFFF8F9FC), Color(0xFFE8ECF3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (item.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: item.isHighlighted
                            ? Colors.black.withValues(alpha: 0.14)
                            : const Color(0xFF101827),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.badge!,
                        style: TextStyle(
                          color: item.isHighlighted ? Colors.black87 : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    '${item.coins + item.bonusCoins}',
                    style: TextStyle(
                      color: item.isHighlighted ? const Color(0xFF1B1508) : const Color(0xFF101827),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.isHighlighted ? const Color(0xFF32260C) : const Color(0xFF384152),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: item.isHighlighted ? const Color(0xFF463814) : const Color(0xFF6A7282),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          item.priceLabel,
                          style: TextStyle(
                            color: item.isHighlighted ? const Color(0xFF1B1508) : const Color(0xFF101827),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: item.isHighlighted ? const Color(0xFF1B1508) : const Color(0xFF101827),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class PremiumFeatureList extends StatelessWidget {
  const PremiumFeatureList({
    super.key,
    required this.features,
    required this.onSpendRequested,
  });

  final List<PremiumFeature> features;
  final ValueChanged<PremiumFeature> onSpendRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: features
          .map(
            (PremiumFeature item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: const Color(0xFFF4D58D),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF20150D)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: const TextStyle(
                              height: 1.35,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onPressed: () => onSpendRequested(item),
                      child: Text('${item.coinCost} coins'),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class TransactionHistoryList extends StatelessWidget {
  const TransactionHistoryList({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<CoinTransaction> items;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No transactions yet.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        if (index >= items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (index == items.length - 1 && hasMore && !isLoadingMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
        }

        final CoinTransaction item = items[index];
        final bool isCredit = item.direction == CoinTransactionDirection.credit;
        final MaterialLocalizations localizations = MaterialLocalizations.of(context);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isCredit ? const Color(0xFFE4FAEE) : const Color(0xFFFFE8E8),
                ),
                child: Icon(
                  isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: isCredit ? const Color(0xFF0E9F6E) : const Color(0xFFD92D20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${localizations.formatShortDate(item.occurredAt.toLocal())} • ${item.type.name}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '${isCredit ? '+' : '-'}${item.amount}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isCredit ? const Color(0xFF0E9F6E) : const Color(0xFFD92D20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Balance ${item.balanceAfter}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class RiskFlagPill extends StatelessWidget {
  const RiskFlagPill({
    super.key,
    required this.riskFlag,
  });

  final RiskFlag riskFlag;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = switch (riskFlag.severity) {
      RiskSeverity.low => const Color(0x1A53B1FD),
      RiskSeverity.medium => const Color(0x1AF59E0B),
      RiskSeverity.high => const Color(0x1AF04438),
    };
    final Color foregroundColor = switch (riskFlag.severity) {
      RiskSeverity.low => const Color(0xFF1D4ED8),
      RiskSeverity.medium => const Color(0xFFB45309),
      RiskSeverity.high => const Color(0xFFB42318),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        riskFlag.title,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WalletStatCard extends StatelessWidget {
  const _WalletStatCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
