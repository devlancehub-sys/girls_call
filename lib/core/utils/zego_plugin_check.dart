import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

Future<bool> isZegoPluginAvailable() async {
  if (kIsWeb) return false;

  try {
    final version = await ZegoExpressEngine.getVersion();
    debugPrint('[Zego] plugin probe ok sdk=$version');
    return version.isNotEmpty;
  } on MissingPluginException catch (e) {
    debugPrint('[Zego] plugin probe MissingPluginException: $e');
    return false;
  }
}

Future<void> warmUpZegoPlugin() async {
  try {
    final version = await ZegoExpressEngine.getVersion();
    debugPrint('[Zego] plugin warm-up ok, sdk=$version');
  } on MissingPluginException catch (e) {
    debugPrint(
      '[Zego] plugin warm-up MissingPluginException: $e — '
      'Release APK may need proguard-rules.pro keeping im.zego.** (see android/app/proguard-rules.pro).',
    );
  } catch (e) {
    debugPrint('[Zego] plugin warm-up note: $e');
  }
}

String zegoPluginMissingMessage() =>
    'Zego native plugin not attached. Uninstall app, run flutter clean, '
    'build release APK, reinstall. Do not test with hot restart.';
