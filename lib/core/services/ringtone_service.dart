import 'package:flutter/foundation.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

import 'storage_service.dart';

class RingtoneService extends GetxService {
  bool _playing = false;
  bool _vibrating = false;

  Future<void> startIncomingRingtone() async {
    if (_playing) return;
    _playing = true;
    try {
      await FlutterRingtonePlayer().play(
        fromAsset: 'assets/sounds/incoming_call.mp3',
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
    } catch (e) {
      debugPrint('[Ringtone] asset play failed: $e');
      try {
        await FlutterRingtonePlayer().play(
          android: AndroidSounds.ringtone,
          ios: IosSounds.bell,
          looping: true,
          volume: 1.0,
          asAlarm: true,
        );
      } catch (fallbackError) {
        debugPrint('[Ringtone] fallback play failed: $fallbackError');
        _playing = false;
      }
    }

    await _startVibrationIfEnabled();
  }

  Future<void> _startVibrationIfEnabled() async {
    if (_vibrating) return;
    if (!Get.isRegistered<StorageService>()) return;
    if (!Get.find<StorageService>().callVibrateEnabled) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) return;

      _vibrating = true;
      await Vibration.vibrate(
        pattern: [0, 800, 400, 800],
        repeat: 0,
      );
    } catch (e) {
      debugPrint('[Vibration] start failed: $e');
      _vibrating = false;
    }
  }

  Future<void> stop() async {
    if (_playing) {
      try {
        await FlutterRingtonePlayer().stop();
      } catch (e) {
        debugPrint('[Ringtone] stop failed: $e');
      } finally {
        _playing = false;
      }
    }

    if (_vibrating) {
      try {
        await Vibration.cancel();
      } catch (e) {
        debugPrint('[Vibration] stop failed: $e');
      } finally {
        _vibrating = false;
      }
    }
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
