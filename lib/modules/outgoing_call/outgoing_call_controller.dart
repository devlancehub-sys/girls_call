import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/utils/parse_utils.dart';
import '../../routes/app_routes.dart';

class OutgoingCallController extends GetxController {
  final SocketService _socket = Get.find<SocketService>();
  final ApiService _api = Get.find<ApiService>();

  late Map<String, dynamic> callData;
  final status = 'ringing'.obs;
  Timer? _timeout;

  int get callId => JsonParse.toInt(callData['call_id']);

  String get partnerName =>
      callData['caller_name']?.toString() ?? callData['name']?.toString() ?? 'User';

  @override
  void onInit() {
    super.onInit();
    callData = Map<String, dynamic>.from(Get.arguments as Map? ?? {});
    _attachHandlers();
    _timeout = Timer(const Duration(seconds: 45), () {
      if (status.value == 'ringing') {
        Get.snackbar('No answer', 'User did not pick up');
        Get.back();
      }
    });
  }

  void _attachHandlers() {
    _socket.onCallAccepted = _onCallAccepted;
    _socket.onCallRejected = _onCallRejected;
    _socket.onCallMissed = _onCallMissed;
  }

  void _detachHandlers() {
    if (_socket.onCallAccepted == _onCallAccepted) _socket.onCallAccepted = null;
    if (_socket.onCallRejected == _onCallRejected) _socket.onCallRejected = null;
    if (_socket.onCallMissed == _onCallMissed) _socket.onCallMissed = null;
  }

  bool _matchesCall(Map<String, dynamic> data) =>
      JsonParse.toInt(data['call_id']) == callId;

  void _onCallAccepted(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;

    final resolvedRoom = data['room_id']?.toString() ?? callData['room_id']?.toString() ?? '';
    if (resolvedRoom.isEmpty) {
      _timeout?.cancel();
      Get.snackbar('Call failed', 'Voice call could not start. Room missing.');
      Get.back();
      return;
    }

    final appId = JsonParse.toInt(data['zego_app_id'] ?? callData['zego_app_id']);
    final token = data['zego_token']?.toString() ?? '';

    status.value = 'connected';
    _timeout?.cancel();
    _detachHandlers();
    if (Get.isRegistered<PresenceService>()) {
      Get.find<PresenceService>().setCallActive(true);
    }
    Get.offNamed(
      AppRoutes.activeCall,
      arguments: {
        'call_id': callId,
        'room_id': resolvedRoom,
        'caller_name': partnerName,
        'rate_per_minute': callData['rate_per_minute'],
        'host_earning_per_minute': data['host_earning_per_minute'],
        'zego_app_id': appId,
        'zego_token': token,
      },
    );
  }

  void _onCallRejected(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;
    _timeout?.cancel();
    Get.snackbar('Declined', 'Call was rejected');
    Get.back();
  }

  void _onCallMissed(Map<String, dynamic> data) {
    if (!_matchesCall(data)) return;
    _timeout?.cancel();
    Get.snackbar('No answer', 'User did not pick up');
    Get.back();
  }

  Future<void> cancel() async {
    _detachHandlers();
    if (callId > 0) {
      try {
        await _api.post('${ApiConstants.callsPrefix}/$callId/reject');
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        if (status != 404 && status != 400) {
          Get.snackbar('Cancel failed', _api.extractError(e));
        }
      }
    }
    if (Get.currentRoute == AppRoutes.outgoingCall) {
      Get.back();
    }
  }

  @override
  void onClose() {
    _timeout?.cancel();
    _detachHandlers();
    super.onClose();
  }
}
