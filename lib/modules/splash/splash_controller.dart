import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/services/auth_session_service.dart';
import '../../core/services/zego_call_service.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/zego_plugin_check.dart';

class SplashController extends GetxController {
  final AuthSessionService _authSession = Get.find<AuthSessionService>();

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    unawaited(prefetchMicrophonePermissionOnLaunch());
    unawaited(warmUpZegoPlugin());
    unawaited(_prefetchZegoEngine());
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _authSession.bootstrapFromSplash();
  }

  Future<void> _prefetchZegoEngine() async {
    try {
      await ZegoCallService.prepareEngine(AppConfig.zegoAppId);
    } catch (e) {
      debugPrint('[Splash] Zego engine pre-warm skipped: $e');
    }
  }
}
