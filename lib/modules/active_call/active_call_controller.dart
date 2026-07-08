import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/call_session_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/zego_call_service.dart';
import '../../core/utils/parse_utils.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/voice_connect_config.dart';
import '../../routes/app_routes.dart';
import '../dashboard/dashboard_controller.dart';

class ActiveCallController extends GetxController {
  static bool active = false;
  final ApiService _api = Get.find<ApiService>();
  final CallSessionService _callSession = Get.find<CallSessionService>();
  final StorageService _storage = Get.find<StorageService>();
  final PresenceService _presence = Get.find<PresenceService>();
  final SocketService _socket = Get.find<SocketService>();

  final isMuted = false.obs;
  final isSpeakerOn = true.obs;
  final isEnding = false.obs;
  final voiceConnected = false.obs;
  final voiceConnecting = false.obs;
  final voiceAutoRetrying = false.obs;
  final voiceLastError = RxnString();
  final callDuration = 0.obs;

  Timer? _timer;
  int _backgroundRetryGen = 0;
  bool _hasEnded = false;
  int _socketDownSince = 0;

  late int callId;
  late String roomId;
  late String callerName;
  late double ratePerMinute;
  late double hostEarningPerMinute;
  int _zegoAppId = 0;
  String _zegoToken = '';

  String get formattedDuration {
    final minutes = (callDuration.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (callDuration.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void onInit() {
    super.onInit();
    active = true;
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    callId = JsonParse.toInt(args['call_id']);
    roomId = args['room_id']?.toString() ?? '';
    callerName = args['caller_name']?.toString() ?? 'Caller';
    ratePerMinute = JsonParse.toDouble(args['rate_per_minute']);
    hostEarningPerMinute = JsonParse.toDouble(args['host_earning_per_minute']);
    _zegoAppId = JsonParse.toInt(args['zego_app_id']);
    _zegoToken = args['zego_token']?.toString() ?? '';

    _callSession.register(callId, _handleRemoteEnd);
    _presence.setCallActive(true);
    unawaited(_bootstrapCall());
  }

  Future<void> _bootstrapCall() async {
    _startTimer();
    await _connectVoiceWithRetry();
  }

  Future<void> retryVoice() => _connectVoiceWithRetry();

  Future<void> _connectVoiceWithRetry() async {
    if (_hasEnded || voiceConnecting.value) return;

    _stopBackgroundVoiceRetry();
    voiceConnecting.value = true;
    try {
      for (var attempt = 1; attempt <= VoiceConnectConfig.maxAttempts; attempt++) {
        if (_hasEnded) return;

        await Future<void>.delayed(
          Duration(milliseconds: VoiceConnectConfig.delayBeforeAttempt(attempt)),
        );
        if (_hasEnded) return;

        final joined = await _initZego(attempt: attempt);
        if (joined) {
          _stopBackgroundVoiceRetry();
          voiceConnected.value = true;
          debugPrint('[Call Lifecycle] Call connected (Zego joined). CallId: $callId');
          Get.snackbar('[Call Lifecycle]', 'Zego connected! Joined Room: $roomId', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
          voiceLastError.value = null;
          return;
        }
      }

      voiceConnected.value = false;
      _showVoiceSnack(
        'Voice not connected',
        voiceLastError.value ?? 'All auto-retries failed. Tap Retry Voice.',
      );
      _startBackgroundVoiceRetry();
    } finally {
      if (!voiceAutoRetrying.value) {
        voiceConnecting.value = false;
      }
    }
  }

  void _startBackgroundVoiceRetry() {
    final gen = ++_backgroundRetryGen;
    voiceAutoRetrying.value = true;
    voiceConnecting.value = true;
    unawaited(_backgroundVoiceRetryLoop(gen));
  }

  Future<void> _backgroundVoiceRetryLoop(int gen) async {
    while (!_hasEnded && gen == _backgroundRetryGen && !voiceConnected.value) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_hasEnded || gen != _backgroundRetryGen) return;

      final joined = await _initZego(attemptLabel: 'background');
      if (joined && !_hasEnded) {
        voiceConnected.value = true;
        voiceConnecting.value = false;
        voiceAutoRetrying.value = false;
        voiceLastError.value = null;
        return;
      }
    }

    if (gen == _backgroundRetryGen && !_hasEnded) {
      _showVoiceSnack(
        'Voice still failing',
        voiceLastError.value ?? 'Background retries stopped. Tap Retry Voice.',
      );
      voiceConnecting.value = false;
      voiceAutoRetrying.value = false;
    }
  }

  void _stopBackgroundVoiceRetry() {
    _backgroundRetryGen++;
    voiceAutoRetrying.value = false;
  }

  void _showVoiceSnack(String title, String message) {
    final detail = message.trim();
    if (detail.isEmpty) return;
    voiceLastError.value = detail;
    Get.closeAllSnackbars();
    Get.snackbar(
      title,
      detail,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      margin: const EdgeInsets.all(16),
    );
  }

  bool _hasVoiceCredentials() =>
      roomId.isNotEmpty && _zegoToken.isNotEmpty && _zegoAppId > 0;

  Future<bool> _fetchVoiceJoinFromBackend() async {
    if (callId <= 0) return false;
    try {
      final response = await _api.post(ApiConstants.callJoinVoice(callId));
      final body = response.data as Map<String, dynamic>? ?? {};
      final data = JsonParse.toMap(body['data']);
      if (data == null) {
        if (!_hasVoiceCredentials()) {
          _showVoiceSnack('join-voice', 'Server returned empty data');
        }
        return _hasVoiceCredentials();
      }

      roomId = data['room_id']?.toString() ?? roomId;
      _zegoToken = data['zego_token']?.toString() ?? _zegoToken;
      final appId = JsonParse.toInt(data['zego_app_id']);
      if (appId > 0) _zegoAppId = appId;
      final rate = JsonParse.toDouble(data['rate_per_minute']);
      if (rate > 0) ratePerMinute = rate;
      final earning = JsonParse.toDouble(data['host_earning_per_minute']);
      if (earning > 0) hostEarningPerMinute = earning;

      if (!_hasVoiceCredentials()) {
        _showVoiceSnack('join-voice', 'Missing room_id, token, or zego_app_id in response');
      }
      return _hasVoiceCredentials();
    } on DioException catch (e) {
      debugPrint('[ActiveCall] join-voice failed: $e');
      final apiError = _api.extractError(e);
      if (_hasVoiceCredentials()) {
        _showVoiceSnack(
          'join-voice (fallback)',
          'API failed ($apiError) — using accept token. room=$roomId',
        );
        return true;
      }
      _showVoiceSnack('join-voice', apiError);
      return false;
    }
  }

  Future<bool> _initZego({int? attempt, String? attemptLabel}) async {
    final attemptTag = attemptLabel ?? (attempt != null ? 'try $attempt' : 'connect');

    if (!await _fetchVoiceJoinFromBackend()) {
      return false;
    }

    final user = _storage.user;
    final rawId = user?['id'];
    if (rawId == null || rawId.toString().isEmpty || rawId.toString() == '0') {
      _showVoiceSnack('Zego ($attemptTag)', 'User account not loaded. Sign in again.');
      return false;
    }

    final userId = rawId.toString();
    final userName = user?['name']?.toString() ?? 'Host';

    if (_zegoAppId > 0) {
      try {
        await ZegoCallService.prepareEngine(_zegoAppId);
      } catch (e) {
        debugPrint('[ActiveCall] engine pre-warm: $e');
        _showVoiceSnack('Zego engine', e.toString());
        return false;
      }
    }

    try {
      final joined = await ZegoCallService.joinVoiceRoom(
        appId: _zegoAppId,
        roomId: roomId,
        userId: userId,
        userName: userName,
        token: _zegoToken,
      );
      if (joined) {
        Get.snackbar(
          'Voice connected',
          'Room $roomId',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        );
        return true;
      }

      final mic = await requestMicrophonePermission();
      if (mic != MicPermissionOutcome.granted) {
        _showVoiceSnack('Zego ($attemptTag)', micPermissionMessage(mic));
        if (mic == MicPermissionOutcome.permanentlyDenied) {
          await openMicrophoneSettings();
        }
      } else {
        _showVoiceSnack(
          'Zego ($attemptTag)',
          'Could not join voice room. Install release APK (not hot reload). room=$roomId user=$userId',
        );
      }
      return false;
    } catch (e) {
      debugPrint('[ActiveCall] Zego join exception: $e');
      _showVoiceSnack('Zego ($attemptTag)', e.toString());
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    callDuration.value = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value++;
      _ensureSocketDuringCall();
    });
  }

  void _ensureSocketDuringCall() {
    if (_hasEnded) return;
    if (_socket.isConnected) {
      _socketDownSince = 0;
      return;
    }
    _socketDownSince++;
    if (_socketDownSince < 3) return;
    _presence.setCallActive(true);
  }

  Future<void> toggleMute() async {
    if (!voiceConnected.value) return;
    isMuted.value = !isMuted.value;
    await ZegoCallService.setMicrophoneMuted(isMuted.value);
  }

  Future<void> toggleSpeaker() async {
    if (!voiceConnected.value) return;
    isSpeakerOn.value = !isSpeakerOn.value;
    await ZegoCallService.setSpeakerEnabled(isSpeakerOn.value);
  }

  Future<void> endCall({String? message}) async {
    if (isEnding.value || _hasEnded) return;
    isEnding.value = true;
    _stopBackgroundVoiceRetry();

    Map<String, dynamic>? data;
    try {
      debugPrint('[Call Lifecycle] Call ended locally by host. CallId: $callId');
      Get.snackbar('[Call Lifecycle]', 'Call ended locally (Call ID: $callId)', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
      data = await _requestCallEnd();
      if (_hasEnded) return;
      if (data != null) {
        _showEarningMessage(data);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != 404 && status != 400) {
        Get.snackbar('Error', _api.extractError(e));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      if (!_hasEnded) {
        _hasEnded = true;
        _callSession.unregister();
        await _leaveAndExit();
      }
      isEnding.value = false;
      if (message != null && data == null) {
        Get.snackbar('Call ended', message);
      }
    }
  }

  Future<Map<String, dynamic>?> _requestCallEnd() async {
    final res = await _api
        .post('${ApiConstants.callsPrefix}/$callId/end')
        .timeout(const Duration(seconds: 12));
    final body = res.data as Map<String, dynamic>?;
    return JsonParse.toMap(body?['data']);
  }

  void _showEarningMessage(Map<String, dynamic> data) {
    final earning = JsonParse.toDouble(data['host_earning']);
    final minutes = data['billable_minutes'] ?? 1;
    Get.snackbar(
      'Call ended',
      'You earned ₹${earning.toStringAsFixed(2)} ($minutes min)',
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _handleRemoteEnd(Map<String, dynamic> data) async {
    if (_hasEnded) return;
    debugPrint(
      '[Call Lifecycle] Call ended remotely. CallId: ${data['call_id']} reason=${data['reason']}',
    );
    Get.snackbar('[Call Lifecycle]', 'Call ended remotely (Call ID: ${data['call_id']}, Reason: ${data['reason']})', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
    _hasEnded = true;
    _stopBackgroundVoiceRetry();
    _callSession.unregister();

    final earning = JsonParse.toDouble(data['host_earning']);
    if (earning > 0) {
      Get.snackbar(
        'Call ended',
        'You earned ₹${earning.toStringAsFixed(2)}',
        duration: const Duration(seconds: 4),
      );
    }

    await _leaveAndExit();
  }

  Future<void> _leaveAndExit() async {
    _timer?.cancel();
    Get.snackbar('[Call Lifecycle]', 'Zego cleanup (leave room) started', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
    await ZegoCallService.leaveVoiceRoom();
    await _presence.restoreAfterCall();
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboard();
    }
    Get.offAllNamed(AppRoutes.mainShell);
  }

  @override
  void onClose() {
    active = false;
    _timer?.cancel();
    _stopBackgroundVoiceRetry();
    if (_hasEnded) {
      _callSession.unregister();
    }
    super.onClose();
  }
}
