import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/constants/app_constants.dart';
import 'package:untitled2/core/services/messaging/push_route_intent.dart';
import 'package:untitled2/features/profile/domain/repositories/user_profile_repository.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

@lazySingleton
class PushNotificationService {
  PushNotificationService(
    this._messaging,
    this._userProfileRepository,
    this._talker,
  );

  final FirebaseMessaging _messaging;
  final UserProfileRepository _userProfileRepository;
  final Talker _talker;
  final StreamController<PushRouteIntent> _routeController =
      StreamController<PushRouteIntent>.broadcast();

  Stream<PushRouteIntent> get routeIntents => _routeController.stream;

  Future<void> initialize({required String? userId}) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _listenOpenAppMessages();
    await _cacheToken(userId);
    _messaging.onTokenRefresh.listen((token) {
      if (userId != null && token.isNotEmpty) {
        _userProfileRepository.saveFcmToken(userId: userId, token: token);
      }
    });
    FirebaseMessaging.onMessage.listen((message) {
      _talker.info('Foreground notification: ${message.messageId}');
    });
  }

  Future<void> _requestPermission() async {
    if (kIsWeb) {
      return;
    }
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (error, stackTrace) {
      _talker.warning('FCM permission request failed', error, stackTrace);
    }
  }

  Future<void> _listenOpenAppMessages() async {
    FirebaseMessaging.onMessageOpenedApp.listen(_emitRouteIntent);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _emitRouteIntent(initialMessage);
    }
  }

  Future<void> _cacheToken(String? userId) async {
    if (userId == null) {
      return;
    }
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _userProfileRepository.saveFcmToken(userId: userId, token: token);
  }

  void _emitRouteIntent(RemoteMessage message) {
    final route = message.data[AppConstants.notificationRouteKey];
    if (route is! String || route.isEmpty) {
      return;
    }
    _routeController.add(
      PushRouteIntent(
        route: route,
        screenName: message.data[AppConstants.notificationScreenKey] as String?,
      ),
    );
  }
}
