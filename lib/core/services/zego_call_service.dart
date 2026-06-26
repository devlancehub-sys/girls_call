import '../utils/mic_permission.dart';
import '../zego/zego_voice_state_machine.dart';

/// ZEGOCLOUD voice via [zego_express_engine] — backend token from POST /calls/:id/join-voice.
class ZegoCallService {
  ZegoCallService._();

  static final ZegoVoiceEngine _engine = ZegoVoiceEngine();

  static ZegoVoicePhase get phase => _engine.phase;

  static Future<void> prepareEngine(int appId, {bool force = false}) =>
      _engine.ensureEngine(appId, force: force);

  static Future<bool> joinVoiceRoom({
    required int appId,
    required String roomId,
    required String userId,
    required String userName,
    required String token,
  }) async {
    if (appId <= 0 || token.isEmpty) return false;

    final micOutcome = await requestMicrophonePermission();
    if (micOutcome != MicPermissionOutcome.granted) return false;

    final result = await _engine.joinCall(
      appId: appId,
      roomId: roomId,
      userId: userId,
      userName: userName,
      token: token,
    );
    return result.success;
  }

  static Future<void> setMicrophoneMuted(bool muted) => _engine.setMicrophoneMuted(muted);

  static Future<void> setSpeakerEnabled(bool enabled) => _engine.setSpeakerEnabled(enabled);

  static Future<void> leaveVoiceRoom() => _engine.leaveCall();
}
