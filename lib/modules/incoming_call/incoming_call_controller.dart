import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/messaging/fcm_payload_mapper.dart';
import '../../core/services/api_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/ringtone_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/utils/call_error_message.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/utils/zego_plugin_check.dart';
import '../../routes/app_routes.dart';

class IncomingCallController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final SocketService _socket = Get.find<SocketService>();

  final isProcessing = false.obs;
  late Map<String, dynamic> callData;

  int get callId => JsonParse.toInt(callData['call_id'] ?? callData['id']);

  String get callerName => callData['caller_name']?.toString() ?? 'Caller';
  String? get callerAvatarUrl => callData['caller_avatar_url']?.toString();
  String get roomId => callData['room_id']?.toString() ?? '';
  double get ratePerMinute => JsonParse.toDouble(callData['rate_per_minute']);
  double get hostEarningPerMinute => JsonParse.toDouble(callData['host_earning_per_minute']);
  int get zegoAppId => JsonParse.toInt(callData['zego_app_id']);

  @override
  void onInit() {
    super.onInit();
    final raw = Map<String, dynamic>.from(Get.arguments as Map? ?? {});
    callData = FcmPayloadMapper.toCallArguments(raw);
    unawaited(ensureMicrophonePermission());
    unawaited(warmUpZegoPlugin());
    _attachRemoteEndHandlers();
  }

  void _attachRemoteEndHandlers() {
    _socket.onCallRejected = _onRemoteReject;
    _socket.onCallMissed = _onRemoteMiss;
  }

  void _detachRemoteEndHandlers() {
    if (_socket.onCallRejected == _onRemoteReject) {
      _socket.onCallRejected = null;
    }
    if (_socket.onCallMissed == _onRemoteMiss) {
      _socket.onCallMissed = null;
    }
  }

  void _onRemoteReject(Map<String, dynamic> data) {
    if (JsonParse.toInt(data['call_id']) != callId) return;
    unawaited(_dismissIncoming());
  }

  void _onRemoteMiss(Map<String, dynamic> data) {
    if (JsonParse.toInt(data['call_id']) != callId) return;
    unawaited(_dismissIncoming());
  }

  Future<void> _dismissIncoming() async {
    await _stopRingtone();
    _detachRemoteEndHandlers();
    if (Get.currentRoute == AppRoutes.incomingCall) {
      Get.back();
    }
  }

  Future<void> _stopRingtone() async {
    if (Get.isRegistered<RingtoneService>()) {
      await Get.find<RingtoneService>().stop();
    }
  }

  Future<void> acceptCall() async {
    if (callId <= 0) {
      Get.snackbar('Error', 'Invalid call — call_id missing');
      Get.back();
      return;
    }

    final mic = await requestMicrophonePermission();
    if (mic != MicPermissionOutcome.granted) {
      Get.snackbar('Microphone required', micPermissionMessage(mic));
      if (mic == MicPermissionOutcome.permanentlyDenied) {
        await openMicrophoneSettings();
      }
      return;
    }

    isProcessing.value = true;
    await _stopRingtone();
    _detachRemoteEndHandlers();
    try {
      final response = await _api.post('${ApiConstants.callsPrefix}/$callId/accept');
      final body = response.data as Map<String, dynamic>? ?? {};
      final data = JsonParse.toMap(body['data']);
      if (data == null) {
        Get.snackbar('Call failed', 'Invalid call response');
        Get.back();
        return;
      }

      final token = data['zego_token']?.toString() ?? '';
      final appId = JsonParse.toInt(data['zego_app_id'] ?? zegoAppId);
      final resolvedRoom = data['room_id']?.toString() ?? roomId;
      if (resolvedRoom.isEmpty) {
        Get.snackbar(
          'Call failed',
          'Voice call could not start. Room missing on server.',
        );
        Get.back();
        return;
      }

      if (Get.isRegistered<PresenceService>()) {
        Get.find<PresenceService>().setCallActive(true);
      }

      Get.offNamed(
        AppRoutes.activeCall,
        arguments: {
          'call_id': callId,
          'room_id': resolvedRoom,
          'caller_name': callerName,
          'rate_per_minute': data['rate_per_minute'] ?? ratePerMinute,
          'host_earning_per_minute':
              data['host_earning_per_minute'] ?? hostEarningPerMinute,
          'zego_app_id': appId,
          'zego_token': token,
        },
      );
    } on DioException catch (e) {
      Get.snackbar('Call failed', callErrorMessage(_api.extractError(e)));
      Get.back();
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> rejectCall() async {
    isProcessing.value = true;
    await _stopRingtone();
    _detachRemoteEndHandlers();
    if (callId <= 0) {
      Get.back();
      return;
    }

    try {
      await _api.post('${ApiConstants.callsPrefix}/$callId/reject');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != 404 && status != 400) {
        Get.snackbar('Error', _api.extractError(e));
      }
    } finally {
      isProcessing.value = false;
      if (Get.currentRoute == AppRoutes.incomingCall) {
        Get.back();
      }
    }
  }

  @override
  void onClose() {
    _detachRemoteEndHandlers();
    _stopRingtone();
    super.onClose();
  }
}
