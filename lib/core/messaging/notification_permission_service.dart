import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests notification permission on Android 13+ and iOS.
class NotificationPermissionService {
  NotificationPermissionService._();

  static Future<bool> requestIfNeeded() async {
    try {
      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance
            .requestPermission(alert: true, badge: true, sound: true)
            .timeout(const Duration(seconds: 8));
        final status = settings.authorizationStatus;
        return status == AuthorizationStatus.authorized ||
            status == AuthorizationStatus.provisional;
      }

      if (Platform.isAndroid) {
        final sdkInt = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
        if (sdkInt >= 33) {
          final status = await Permission.notification.request();
          if (!status.isGranted) {
            debugPrint('[FCM] POST_NOTIFICATIONS denied: $status');
            return false;
          }
        }

        final settings = await FirebaseMessaging.instance
            .requestPermission()
            .timeout(const Duration(seconds: 5));
        debugPrint(
          '[FCM] Android messaging permission: ${settings.authorizationStatus}',
        );
        return true;
      }

      return true;
    } catch (e) {
      debugPrint('[FCM] permission request failed: $e');
      return false;
    }
  }
}
