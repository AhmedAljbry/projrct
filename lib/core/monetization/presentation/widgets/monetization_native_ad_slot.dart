import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:untitled2/core/monetization/services/ad_inventory_manager.dart';
import 'package:untitled2/core/monetization/services/monetization_remote_config_service.dart';

class MonetizationNativeAdSlot extends StatefulWidget {
  const MonetizationNativeAdSlot({
    super.key,
    required this.adInventoryManager,
    required this.remoteConfigService,
    this.factoryId = _defaultFactoryId,
    this.height = 112,
    this.margin = const EdgeInsets.symmetric(vertical: 12),
  });

  final AdInventoryManager adInventoryManager;
  final MonetizationRemoteConfigService remoteConfigService;
  final String factoryId;
  final double height;
  final EdgeInsets margin;

  @override
  State<MonetizationNativeAdSlot> createState() =>
      _MonetizationNativeAdSlotState();

  static const String _defaultFactoryId = String.fromEnvironment(
    'ADMOB_NATIVE_FACTORY_ID',
    defaultValue: '',
  );
}

class _MonetizationNativeAdSlotState extends State<MonetizationNativeAdSlot> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _shouldRender = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final config = widget.remoteConfigService.current;
    final adUnitId = widget.adInventoryManager.nativeAdUnitId;
    if (!config.enableNativeAds || adUnitId == null || widget.factoryId.isEmpty) {
      return;
    }
    setState(() {
      _shouldRender = true;
    });
    final ad = NativeAd(
      adUnitId: adUnitId,
      factoryId: widget.factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
      ),
    );
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRender) {
      return const SizedBox.shrink();
    }
    if (!_isLoaded || _nativeAd == null) {
      return Container(
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Sponsored content area',
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      height: widget.height,
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
