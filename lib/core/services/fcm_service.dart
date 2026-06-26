import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../messaging/fcm_constants.dart';
import '../messaging/fcm_payload_mapper.dart';
import 'call_notification_service.dart';
import 'ringtone_service.dart';

class FcmService extends GetxService {
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedAppSub;

  Future<FcmService> init() async {
    if (Get.isRegistered<CallNotificationService>()) {
      Get.find<CallNotificationService>().onIncomingCallTap = _onLocalNotificationTap;
      final pending = await Get.find<CallNotificationService>().consumeLaunchPayload();
      if (pending != null) {
        _handleCallInvite(pending);
      }
    }

    _foregroundSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleRemoteMessage(initial);
    }

    return this;
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] foreground: ${message.data}');
    _handleRemoteMessage(message);
  }

  void _onMessageOpened(RemoteMessage message) {
    debugPrint('[FCM] opened from tray: ${message.data}');
    _handleRemoteMessage(message);
  }

  void _onLocalNotificationTap(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _handleCallInvite(decoded);
      }
    } catch (e) {
      debugPrint('[FCM] invalid notification payload: $e');
    }
  }

  void _handleRemoteMessage(RemoteMessage message) {
    final type = message.data[FcmConstants.typeKey]?.toString();
    if (!FcmConstants.isCallInvite(type)) return;
    _handleCallInvite(FcmPayloadMapper.toCallArguments(message.data));
  }

  void _handleCallInvite(Map<String, dynamic> callData) {
    if (_isOnCallScreen()) return;

    final callerName = FcmPayloadMapper.callerName(callData);

    if (Get.isRegistered<CallNotificationService>()) {
      Get.find<CallNotificationService>().showIncomingCallNotification(
        callerName: callerName,
        payload: jsonEncode(callData),
      );
    }

    if (Get.isRegistered<RingtoneService>()) {
      Get.find<RingtoneService>().startIncomingRingtone();
    }

    Get.toNamed(AppRoutes.incomingCall, arguments: callData);
  }

  bool _isOnCallScreen() {
    final route = Get.currentRoute;
    return route == AppRoutes.incomingCall ||
        route == AppRoutes.activeCall ||
        route == AppRoutes.outgoingCall;
  }

  @override
  void onClose() {
    _foregroundSub?.cancel();
    _openedAppSub?.cancel();
    super.onClose();
  }
}
