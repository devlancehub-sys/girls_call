import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';
import 'call_notification_service.dart';
import 'presence_service.dart';
import 'socket_service.dart';

enum HostStatus { offline, available, busy }

/// Manages host availability (available / busy / offline) via backend API.
class HostAvailabilityService extends GetxService {
  final ApiService _api = Get.find<ApiService>();
  final SocketService _socket = Get.find<SocketService>();

  final hostStatus = HostStatus.offline.obs;
  final consecutiveMissedCalls = 0.obs;
  final onlineDurationSeconds = 0.obs;
  final isSyncing = false.obs;

  bool get isAvailable => hostStatus.value == HostStatus.available;
  bool get isBusy => hostStatus.value == HostStatus.busy;

  Future<HostAvailabilityService> init() async {
    return this;
  }

  Future<void> refresh() async {
    try {
      final response = await _api.get(ApiConstants.hostAvailability);
      _applyResponse(response.data['data']);
    } catch (e) {
      debugPrint('[HostAvailability] refresh failed: $e');
    }
  }

  Future<bool> setAvailable(bool enabled) async {
    final status = enabled ? 'available' : 'busy';
    return setStatus(status);
  }

  Future<bool> setStatus(String status) async {
    isSyncing.value = true;
    try {
      final response = await _api.put(
        ApiConstants.hostAvailability,
        data: {'status': status},
      );
      _applyResponse(response.data['data']);

      if (status == 'available') {
        await Get.find<PresenceService>().goAvailable();
      } else if (status == 'busy') {
        await Get.find<PresenceService>().goBusy();
      } else {
        await Get.find<PresenceService>().goOffline();
      }

      return true;
    } on DioException catch (e) {
      Get.snackbar('Status', Get.find<ApiService>().extractError(e));
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> goOffline() async {
    try {
      await _api.put(ApiConstants.hostAvailability, data: {'status': 'offline'});
    } catch (_) {}
    _applyLocalStatus(HostStatus.offline);
    await Get.find<PresenceService>().goOffline();
  }

  void _applyResponse(dynamic raw) {
    if (raw is! Map) return;
    final statusStr = raw['host_status']?.toString() ?? 'offline';
    hostStatus.value = _parseStatus(statusStr);
    consecutiveMissedCalls.value = int.tryParse('${raw['consecutive_missed_calls']}') ?? 0;
    onlineDurationSeconds.value =
        int.tryParse('${raw['online_duration_seconds']}') ?? 0;

    if (hostStatus.value == HostStatus.available) {
      Get.find<CallNotificationService>().showAvailableNotification();
    } else {
      Get.find<CallNotificationService>().hideAvailableNotification();
    }
  }

  void _applyLocalStatus(HostStatus status) {
    hostStatus.value = status;
    if (status == HostStatus.available) {
      Get.find<CallNotificationService>().showAvailableNotification();
    } else {
      Get.find<CallNotificationService>().hideAvailableNotification();
    }
  }

  HostStatus _parseStatus(String value) {
    switch (value) {
      case 'available':
        return HostStatus.available;
      case 'busy':
        return HostStatus.busy;
      default:
        return HostStatus.offline;
    }
  }

  void listenSocketEvents() {
    _socket.onHostAutoBusy = (_) {
      hostStatus.value = HostStatus.busy;
      Get.find<CallNotificationService>().hideAvailableNotification();
      Get.snackbar(
        'Auto Busy',
        'You missed 3 calls — status switched to Busy. Turn Available ON when ready.',
      );
    };
  }

  void stopListening() {
    _socket.onHostAutoBusy = null;
  }
}
