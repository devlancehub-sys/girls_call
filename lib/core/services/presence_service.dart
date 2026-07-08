import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/api_constants.dart';
import 'api_service.dart';
import 'host_availability_service.dart';
import 'socket_service.dart';
import 'storage_service.dart';

/// Keeps socket connected while host is available — including when app is backgrounded.
class PresenceService extends GetxService with WidgetsBindingObserver {
  final StorageService _storage = Get.find<StorageService>();
  final ApiService _api = Get.find<ApiService>();
  final SocketService _socket = Get.find<SocketService>();

  final isOnline = false.obs;
  bool _foreground = true;
  bool _callActive = false;
  bool _keepAliveInBackground = false;
  int _restoreEpoch = 0;

  Future<PresenceService> init() async {
    WidgetsBinding.instance.addObserver(this);
    return this;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        if (_keepAliveInBackground) {
          _socket.connect();
        }
        break;
      case AppLifecycleState.inactive:
        // Mic permission / audio session dialogs briefly enter inactive — keep call socket alive.
        if (_callActive || _keepAliveInBackground) return;
        _foreground = false;
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _foreground = false;
        if (!_keepAliveInBackground && !_callActive) {
          _socket.disconnect();
        }
        break;
      case AppLifecycleState.detached:
        _foreground = false;
        break;
    }
  }

  void setCallActive(bool active) {
    if (active) {
      _restoreEpoch++;
      _callActive = true;
      _keepAliveInBackground = true;
      if (_storage.isLoggedIn && !_socket.isConnected) {
        _socket.ensureConnected();
      }
      return;
    }

    _callActive = false;
  }

  Future<void> restoreAfterCall() async {
    _callActive = false;
    _keepAliveInBackground = false;

    if (!Get.isRegistered<HostAvailabilityService>()) return;

    final availability = Get.find<HostAvailabilityService>();
    await availability.refresh();
    if (availability.isAvailable) {
      await goAvailable();
    }
  }

  Future<void> goAvailable() async {
    if (!_storage.isLoggedIn) return;
    _keepAliveInBackground = true;

    try {
      await _api.put(ApiConstants.onlineStatus, data: {'is_online': true});
      _socket.ensureConnected();
      isOnline.value = true;
      debugPrint('[Presence] available — socket kept alive in background');
    } catch (e) {
      debugPrint('[Presence] goAvailable failed: $e');
    }
  }

  Future<void> goBusy() async {
    _keepAliveInBackground = false;

    try {
      if (_storage.isLoggedIn) {
        await _api.put(ApiConstants.onlineStatus, data: {'is_online': false});
      }
    } catch (_) {}

    if (!_foreground) {
      _socket.disconnect();
    }
    isOnline.value = false;
    debugPrint('[Presence] busy — not receiving calls');
  }

  Future<void> goOffline() async {
    _keepAliveInBackground = false;

    try {
      if (_storage.isLoggedIn) {
        await _api.put(ApiConstants.onlineStatus, data: {'is_online': false});
      }
    } catch (_) {}

    _socket.disconnect();
    isOnline.value = false;
    debugPrint('[Presence] offline');
  }

  /// Legacy alias used after login / splash — sets available if host toggles on later.
  Future<void> goOnline() async {
    if (Get.isRegistered<HostAvailabilityService>()) {
      final availability = Get.find<HostAvailabilityService>();
      if (availability.isAvailable) {
        await goAvailable();
        return;
      }
    }
    await goBusy();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
