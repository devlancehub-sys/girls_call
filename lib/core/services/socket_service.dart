import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_constants.dart';
import 'presence_service.dart';
import 'call_session_service.dart';
import 'storage_service.dart';

typedef SocketCallback = void Function(Map<String, dynamic> data);

class SocketService extends GetxService {
  io.Socket? _socket;
  final StorageService _storage = Get.find<StorageService>();

  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  SocketCallback? onIncomingCall;
  SocketCallback? onCallAccepted;
  SocketCallback? onCallRejected;
  SocketCallback? onCallMissed;
  SocketCallback? onHostAutoBusy;
  VoidCallback? onUserPresenceChanged;

  void ensureConnected() {
    if (_socket?.connected == true) return;
    if (_socket != null) {
      _socket!.connect();
      return;
    }
    connect();
  }

  void connect() {
    final token = _storage.accessToken;
    if (token == null || token.isEmpty) return;
    if (_socket?.connected == true) return;

    final existing = _socket;
    if (existing != null) {
      existing.dispose();
      _socket = null;
    }

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _bindCoreEvents();
    _socket!.connect();
  }

  void _bindCoreEvents() {
    final socket = _socket;
    if (socket == null) return;

    socket.onConnect((_) {
      debugPrint('[Socket] connected');
      if (Get.isRegistered<PresenceService>()) {
        Get.find<PresenceService>().isOnline.value = true;
      }
    });

    socket.onDisconnect((_) {
      debugPrint('[Socket] disconnected');
      if (Get.isRegistered<PresenceService>()) {
        Get.find<PresenceService>().isOnline.value = false;
      }
    });

    socket.onConnectError((data) => debugPrint('[Socket] connect error: $data'));

    socket.on('incoming_call', (data) => onIncomingCall?.call(_toMap(data)));
    socket.on('call_accepted', (data) => onCallAccepted?.call(_toMap(data)));
    socket.on('call_rejected', (data) => onCallRejected?.call(_toMap(data)));
    socket.on('call_missed', (data) => onCallMissed?.call(_toMap(data)));

    socket.on('call_ended', (data) {
      final map = _toMap(data);
      debugPrint(
        '[Socket] call_ended call_id=${map['call_id']} reason=${map['reason']}',
      );
      if (Get.isRegistered<CallSessionService>()) {
        Get.find<CallSessionService>().handleCallEnded(map);
      }
    });

    socket.on('host_auto_busy', (data) => onHostAutoBusy?.call(_toMap(data)));

    for (final event in ['user_online', 'user_offline', 'user_busy', 'user_available']) {
      socket.on(event, (_) => onUserPresenceChanged?.call());
    }
  }

  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }

  void on(String event, void Function(dynamic) callback) {
    _socket?.on(event, callback);
  }

  void off(String event, [void Function(dynamic)? callback]) {
    if (callback != null) {
      _socket?.off(event, callback);
    } else {
      _socket?.off(event);
    }
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  @override
  void onClose() {
    onIncomingCall = null;
    onCallAccepted = null;
    onCallRejected = null;
    onCallMissed = null;
    onHostAutoBusy = null;
    onUserPresenceChanged = null;
    disconnect();
    super.onClose();
  }
}
