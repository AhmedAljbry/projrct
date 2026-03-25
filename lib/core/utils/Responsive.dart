// responsive_utils.dart — Responsive Layout Helpers
import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, desktop }

class Responsive {
  static DeviceType of(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w >= 1100) return DeviceType.desktop;
    if (w >= 600)  return DeviceType.tablet;
    return DeviceType.phone;
  }

  static bool isPhone(BuildContext context)   => of(context) == DeviceType.phone;
  static bool isTablet(BuildContext context)  => of(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => of(context) == DeviceType.desktop;

  /// Responsive value: phone / tablet / desktop
  static T value<T>(BuildContext context, {required T phone, T? tablet, T? desktop}) {
    switch (of(context)) {
      case DeviceType.desktop: return desktop ?? tablet ?? phone;
      case DeviceType.tablet:  return tablet ?? phone;
      case DeviceType.phone:   return phone;
    }
  }

  static double fontSize(BuildContext context, {required double phone, double? tablet, double? desktop}) =>
      value(context, phone: phone, tablet: tablet, desktop: desktop);

  static EdgeInsets padding(BuildContext context) {
    return value(context,
      phone:   const EdgeInsets.symmetric(horizontal: 16),
      tablet:  const EdgeInsets.symmetric(horizontal: 32),
      desktop: const EdgeInsets.symmetric(horizontal: 64),
    );
  }

  static double canvasMaxWidth(BuildContext context) {
    return value(context, phone: double.infinity, tablet: 520.0, desktop: 640.0);
  }

  static double bottomPanelHeight(BuildContext context) {
    return value(context, phone: 310.0, tablet: 340.0, desktop: 360.0);
  }

  static int filterGridCrossAxis(BuildContext context) {
    return value(context, phone: 0, tablet: 0, desktop: 0); // 0 = horizontal list
  }
}

/// Layout builder helper widget
class ResponsiveLayout extends StatelessWidget {
  final Widget phone;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 1100 && desktop != null) return desktop!;
      if (constraints.maxWidth >= 600  && tablet  != null) return tablet!;
      return phone;
    });
  }
}
