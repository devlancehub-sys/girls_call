import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import 'fcm_constants.dart';
import 'fcm_local_notifications.dart';

/// Top-level handler for data messages when the app is backgrounded or terminated.
@pragma('vm:entry-point')
Future<void> fcmBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final type = message.data[FcmConstants.typeKey]?.toString();
  debugPrint('[FCM] background message type=$type id=${message.messageId}');

  if (!FcmConstants.isCallInvite(type)) return;

  // System shows the tray notification when [notification] is present; for
  // data-only payloads we must raise a local notification ourselves.
  if (message.notification == null) {
    await FcmLocalNotifications.showCallInviteIfNeeded(message.data);
  }
}
