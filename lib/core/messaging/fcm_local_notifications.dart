import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'fcm_constants.dart';
import 'fcm_payload_mapper.dart';

/// Standalone local notifications for FCM background isolate (no GetX).
class FcmLocalNotifications {
  FcmLocalNotifications._();

  static const _channelId = 'incoming_call';
  static const _notificationId = 2001;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        'Incoming Calls',
        description: 'Incoming voice call alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ),
    );

    _initialized = true;
  }

  static Future<void> showCallInviteIfNeeded(Map<String, dynamic> data) async {
    final type = data[FcmConstants.typeKey]?.toString();
    if (!FcmConstants.isCallInvite(type)) return;

    try {
      await ensureInitialized();

      final callerName = FcmPayloadMapper.callerName(data);
      final payload = jsonEncode(FcmPayloadMapper.toCallArguments(data));

      final android = AndroidNotificationDetails(
        _channelId,
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

      await _plugin.show(
        _notificationId,
        'Incoming Call',
        '$callerName is calling you',
        NotificationDetails(android: android),
        payload: payload,
      );
    } catch (e) {
      debugPrint('[FCM] background local notification failed: $e');
    }
  }
}
