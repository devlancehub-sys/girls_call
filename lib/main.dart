import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/config/app_config.dart';
import 'core/messaging/fcm_background_handler.dart';
import 'core/services/zego_call_service.dart';
import 'core/services/api_service.dart';
import 'core/services/auth_session_service.dart';
import 'core/services/call_notification_service.dart';
import 'core/services/call_session_service.dart';
import 'core/services/device_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/host_availability_service.dart';
import 'core/services/presence_service.dart';
import 'core/services/ringtone_service.dart';
import 'core/services/socket_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundMessageHandler);

  await Get.putAsync(() => StorageService().init());
  await Get.putAsync(() => ApiService().init());
  await Get.putAsync(() => DeviceService().init());
  Get.put(SocketService());
  Get.put(CallSessionService());
  await Get.putAsync(() => CallNotificationService().init());
  await Get.putAsync(() => HostAvailabilityService().init());
  await Get.putAsync(() => PresenceService().init());
  Get.put(AuthSessionService());
  Get.put(RingtoneService());

  try {
    await Get.putAsync(() => FcmService().init());
  } catch (e) {
    debugPrint('[Main] FCM service init failed: $e');
  }

  runApp(const LoveCallGirlsApp());

  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await ZegoCallService.prepareEngine(AppConfig.zegoAppId);
      debugPrint('[Main] Zego native SDK ready (post-frame)');
    } catch (e, st) {
      debugPrint('[Main] Zego post-frame init failed (will retry on call): $e\n$st');
    }
  });
}

class LoveCallGirlsApp extends StatelessWidget {
  const LoveCallGirlsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Love Call Girls',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
