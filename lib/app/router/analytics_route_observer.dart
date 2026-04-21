import 'package:flutter/widgets.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/analytics/app_analytics_event.dart';

class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AppAnalytics _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _log(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _log(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _log(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) {
      return;
    }
    _analytics.log(
      AppAnalyticsEvent.screenView(
        screenName: name,
        screenClass: route.runtimeType.toString(),
      ),
    );
  }
}
