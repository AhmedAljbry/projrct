import 'package:flutter/material.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';

// ── Media type enum ────────────────────────────────────────────────────────────
// Flexible system: plug in image / video / lottie later without changing
// the card's structure.
enum CardMediaType { image, video, lottie, none }

// ── Reusable premium feature card ─────────────────────────────────────────────

class FeatureCardWidget extends StatefulWidget {
  const FeatureCardWidget({
    super.key,
    required this.title,
    required this.gradient,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.mediaType = CardMediaType.none,
    this.mediaSource,
    this.isNew = false,
    this.isFeatured = false,
    this.accentColor,
  });

  /// Primary label shown in bold at the bottom of the card.
  final String title;

  /// Optional tagline rendered below the title.
  final String? subtitle;

  /// Background gradient used when no real media is available.
  final LinearGradient gradient;

  /// The media approach for the card background.
  final CardMediaType mediaType;

  /// Path/URL for image, video, or lottie (nullable – placeholder used when null).
  final String? mediaSource;

  /// Small icon displayed in the top-right corner.
  final IconData? icon;

  /// Navigation / action callback – unchanged from original logic.
  final VoidCallback onTap;

  /// Shows a "NEW" badge on the card.
  final bool isNew;

  /// Featured cards are taller and slightly different styled.
  final bool isFeatured;

  /// Optional accent colour used for the CTA button glow.
  final Color? accentColor;

  @override
  State<FeatureCardWidget> createState() => _FeatureCardWidgetState();
}

class _FeatureCardWidgetState extends State<FeatureCardWidget>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // Shimmer animation for placeholder mode
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  // ── Height ────────────────────────────────────────────────────────────────

  double get _height => widget.isFeatured ? 200.0 : 156.0;

  // ── Accent color ──────────────────────────────────────────────────────────

  Color get _accent =>
      widget.accentColor ??
      (widget.gradient.colors.isNotEmpty
          ? widget.gradient.colors.first
          : const Color(0xFF56E39F));

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.962 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: _buildCard(context),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: _pressed
            ? []
            : [
                // Colour-matched glow
                BoxShadow(
                  color: _accent.withValues(alpha: 0.28),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
                // Deep shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // ── Layer 1: Background (placeholder gradient + animated shimmer) ──
            _buildBackground(),

            // ── Layer 2: Dark gradient overlay (bottom → top) ─────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.28),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),

            // ── Layer 3: Subtle top-left gloss ────────────────────────────────
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Layer 4: Glass border ─────────────────────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1.2,
                  ),
                ),
              ),
            ),

            // ── Layer 5: Content ──────────────────────────────────────────────
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: badges + icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (widget.isFeatured) _buildBadge('FEATURED', _accent),
                            if (widget.isFeatured && widget.isNew)
                              const SizedBox(width: 6),
                            if (widget.isNew) _buildBadge('NEW', const Color(0xFF56E39F)),
                          ],
                        ),
                        if (widget.icon != null) _buildIconChip(),
                      ],
                    ),

                    const Spacer(),

                    // Title + subtitle
                    if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildCtaButton(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Background placeholder ─────────────────────────────────────────────────

  Widget _buildBackground() {
    // For now: animated gradient shimmer as premium placeholder.
    // Later: swap with Image.asset / Image.network / Lottie based on mediaType.
    if (widget.mediaType == CardMediaType.image && widget.mediaSource != null) {
      return Positioned.fill(
        child: Image.asset(
          widget.mediaSource!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gradientPlaceholder(),
        ),
      );
    }

    return Positioned.fill(child: _gradientPlaceholder());
  }

  Widget _gradientPlaceholder() {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        final t = _shimmer.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient.colors,
              begin: Alignment.lerp(
                    widget.gradient.begin as Alignment,
                    Alignment.bottomRight,
                    t * 0.25,
                  ) ??
                  widget.gradient.begin,
              end: Alignment.lerp(
                    widget.gradient.end as Alignment,
                    Alignment.topLeft,
                    t * 0.25,
                  ) ??
                  widget.gradient.end,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.04 + t * 0.05),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08 + t * 0.05),
                ],
                begin: Alignment(-1 + t * 1.5, -0.5),
                end: Alignment(1 - t * 0.5, 1),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildIconChip() {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.18),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Icon(widget.icon!, color: Colors.white, size: 18),
    );
  }

  Widget _buildCtaButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _pressed
            ? _accent.withValues(alpha: 0.80)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: _pressed ? 0.0 : 0.22),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        context.tr.startCta,
        style: TextStyle(
          color: _pressed ? Colors.black : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
