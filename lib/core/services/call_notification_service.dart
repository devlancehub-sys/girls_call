import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

typedef IncomingCallNotificationTap = void Function(String payload);

/// Android ongoing notification while host is available; high-priority incoming call alerts.
class CallNotificationService extends GetxService {
  static const _availableChannelId = 'host_available';
  static const _incomingChannelId = 'incoming_call';
  static const _availableNotificationId = 1001;
  static const _incomingNotificationId = 2001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  IncomingCallNotificationTap? onIncomingCallTap;

  Future<CallNotificationService> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return this;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _availableChannelId,
          'Host Availability',
          description: 'Shows when you are available for calls',
          importance: Importance.low,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _incomingChannelId,
          'Incoming Calls',
          description: 'Incoming voice call alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;
    return this;
  }

  /// Returns call payload when the app was launched by tapping an incoming-call notification.
  Future<Map<String, dynamic>?> consumeLaunchPayload() async {
    if (!_initialized) return null;

    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;

    final payload = details?.notificationResponse?.payload;
    if (payload == null || payload.isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      debugPrint('[CallNotification] launch payload parse failed: $e');
    }
    return null;
  }

  void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    debugPrint('[CallNotification] tapped');
    onIncomingCallTap?.call(payload);
  }

  Future<void> showAvailableNotification() async {
    if (!_initialized || !Platform.isAndroid) return;

    const android = AndroidNotificationDetails(
      _availableChannelId,
      'Host Availability',
      channelDescription: 'You are available for incoming calls',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      _availableNotificationId,
      'Available for calls',
      'You will receive calls even when the screen is off',
      const NotificationDetails(android: android),
    );
  }

  Future<void> hideAvailableNotification() async {
    if (!_initialized) return;
    await _plugin.cancel(_availableNotificationId);
  }

  Future<void> showIncomingCallNotification({
    required String callerName,
    required String payload,
  }) async {
    if (!_initialized) return;

    final android = AndroidNotificationDetails(
      _incomingChannelId,
      'Incoming Calls',
      channelDescription: 'Incoming voice call alerts',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    await _plugin.show(
      _incomingNotificationId,
      'Incoming Call',
      '$callerName is calling you',
      NotificationDetails(android: android, iOS: ios),
      payload: payload,
    );
  }

  Future<void> cancelIncomingCallNotification() async {
    if (!_initialized) return;
    await _plugin.cancel(_incomingNotificationId);
  }
}
