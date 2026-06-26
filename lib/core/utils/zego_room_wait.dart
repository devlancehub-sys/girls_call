import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// Register **before** [ZegoExpressEngine.instance.loginRoom], then await [future].
ZegoRoomWaitHandle beginZegoRoomWait(
  String roomId, {
  Duration timeout = const Duration(seconds: 5),
}) {
  final completer = Completer<bool>();
  Timer? timer;

  void Function(String, ZegoRoomState, int, Map<String, dynamic>)? previous;

  void onState(String roomID, ZegoRoomState state, int errorCode, Map<String, dynamic> extendedData) {
    if (roomID != roomId) return;
    debugPrint('[Zego] wait room=$roomID state=$state error=$errorCode');
    if (state == ZegoRoomState.Connected && !completer.isCompleted) {
      completer.complete(true);
    } else if (state == ZegoRoomState.Disconnected && errorCode != 0 && !completer.isCompleted) {
      completer.complete(false);
    }
  }

  void dispose() {
    timer?.cancel();
    ZegoExpressEngine.onRoomStateUpdate = previous;
  }

  previous = ZegoExpressEngine.onRoomStateUpdate;
  ZegoExpressEngine.onRoomStateUpdate = (roomID, state, errorCode, extendedData) {
    previous?.call(roomID, state, errorCode, extendedData);
    onState(roomID, state, errorCode, extendedData);
  };

  timer = Timer(timeout, () {
    if (!completer.isCompleted) completer.complete(false);
  });

  return ZegoRoomWaitHandle._(completer.future, dispose);
}

class ZegoRoomWaitHandle {
  const ZegoRoomWaitHandle._(this.future, this._dispose);

  final Future<bool> future;
  final void Function() _dispose;

  void dispose() => _dispose();
}
