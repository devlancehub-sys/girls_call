import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

/// Explicit phases for Zego voice lifecycle.
enum ZegoVoicePhase {
  idle,
  creatingEngine,
  engineReady,
  loggingIn,
  roomConnected,
  publishing,
  inCall,
  leavingRoom,
  destroyingEngine,
  failed,
}

class ZegoVoiceJoinResult {
  const ZegoVoiceJoinResult._({
    required this.success,
    this.pluginMissing = false,
    this.detail,
  });

  const ZegoVoiceJoinResult.success() : this._(success: true);

  const ZegoVoiceJoinResult.failure({required String detail, bool pluginMissing = false})
      : this._(success: false, detail: detail, pluginMissing: pluginMissing);

  final bool success;
  final bool pluginMissing;
  final String? detail;
}

/// State machine for [zego_express_engine] voice calls.
class ZegoVoiceEngine {
  ZegoVoicePhase _phase = ZegoVoicePhase.idle;
  int? _appId;
  String? _currentRoom;
  String? _streamId;
  bool _engineCreated = false;
  bool _callbacksRegistered = false;
  Future<void>? _mutex;

  final Set<String> _playingStreamIds = {};

  Completer<bool>? _roomConnectCompleter;
  String? _roomConnectTarget;
  Timer? _roomConnectTimer;

  Completer<bool>? _publisherCompleter;
  String? _publisherStreamTarget;
  Timer? _publisherTimer;

  static const Duration roomConnectTimeout = Duration(seconds: 15);
  static const Duration publishConfirmTimeout = Duration(seconds: 10);
  static const Duration cleanupSettleDelay = Duration(milliseconds: 300);

  ZegoVoicePhase get phase => _phase;

  void _log(String step, [String? detail]) {
    final ts = DateTime.now().toIso8601String();
    final thread = _threadLabel();
    debugPrint('[Zego][$ts][$thread][${_phase.name}] $step${detail != null ? ' | $detail' : ''}');
  }

  String _threadLabel() {
    final name = Zone.current[#zegoThread] as String?;
    if (name != null) return name;
    return 'main';
  }

  void _logError(String step, Object error, [StackTrace? stackTrace]) {
    _log('$step ERROR', error.toString());
    if (stackTrace != null) {
      debugPrint('[Zego] stack: $stackTrace');
    }
  }

  void _setPhase(ZegoVoicePhase next, String reason) {
    _log('phase ${_phase.name} → ${next.name}', reason);
    _phase = next;
  }

  Future<T> _withMutex<T>(Future<T> Function() action) async {
    while (_mutex != null) {
      await _mutex;
    }
    final gate = Completer<void>();
    _mutex = gate.future;
    try {
      return await action();
    } finally {
      if (!gate.isCompleted) gate.complete();
      _mutex = null;
    }
  }

  void _registerCallbacks() {
    ZegoExpressEngine.onRoomStateUpdate = _onRoomStateUpdate;
    ZegoExpressEngine.onRoomStateChanged = _onRoomStateChanged;
    ZegoExpressEngine.onRoomStreamUpdate = _onRoomStreamUpdate;
    ZegoExpressEngine.onPublisherStateUpdate = _onPublisherStateUpdate;
    ZegoExpressEngine.onRoomUserUpdate = _onRoomUserUpdate;
    _callbacksRegistered = true;
    _log('callbacks registered', 'roomState, roomStateChanged, roomStream, publisherState, roomUser');
  }

  void _safeCompleteBool(
    Completer<bool> completer,
    bool value,
    String label, {
    String? roomId,
    String? streamId,
    String? source,
  }) {
    if (completer.isCompleted) {
      _log(
        '[$label] ignored duplicate',
        'source=$source room=$roomId stream=$streamId isCompleted=true',
      );
      return;
    }
    _log(
      '[$label] complete($value)',
      'source=$source room=$roomId stream=$streamId isCompleted=false',
    );
    completer.complete(value);
  }

  void _completeRoomConnectWait(String roomID, int errorCode, String source) {
    final target = _roomConnectTarget;
    final waiter = _roomConnectCompleter;
    if (waiter == null || roomID != target) return;

    if (errorCode == 0) {
      _setPhase(ZegoVoicePhase.roomConnected, 'room=$roomID via $source');
      _safeCompleteBool(waiter, true, 'RoomCompleter', roomId: roomID, source: source);
    } else {
      _log('room connect failed', 'room=$roomID errorCode=$errorCode source=$source');
      _safeCompleteBool(waiter, false, 'RoomCompleter', roomId: roomID, source: source);
    }
  }

  void _onRoomStateUpdate(
    String roomID,
    ZegoRoomState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    _log(
      'onRoomStateUpdate',
      'room=$roomID state=$state errorCode=$errorCode extendedData=$extendedData',
    );

    if (errorCode != 0) {
      _log('room error', 'room=$roomID errorCode=$errorCode');
    }

    if (state == ZegoRoomState.Connected && errorCode == 0) {
      _completeRoomConnectWait(roomID, errorCode, 'onRoomStateUpdate');
    } else if (errorCode != 0) {
      _completeRoomConnectWait(roomID, errorCode, 'onRoomStateUpdate');
    }
  }

  void _onRoomStateChanged(
    String roomID,
    ZegoRoomStateChangedReason reason,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    _log(
      'onRoomStateChanged',
      'room=$roomID reason=$reason errorCode=$errorCode extendedData=$extendedData',
    );

    if (reason == ZegoRoomStateChangedReason.Logined && errorCode == 0) {
      _completeRoomConnectWait(roomID, errorCode, 'onRoomStateChanged.Logined');
    } else if (errorCode != 0 &&
        (reason == ZegoRoomStateChangedReason.LoginFailed ||
            reason == ZegoRoomStateChangedReason.KickOut ||
            reason == ZegoRoomStateChangedReason.ReconnectFailed)) {
      _completeRoomConnectWait(roomID, errorCode, 'onRoomStateChanged.$reason');
    }
  }

  void _onRoomUserUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoUser> userList,
  ) {
    _log(
      'onRoomUserUpdate',
      'room=$roomID type=$updateType users=${userList.map((u) => u.userID).join(",")}',
    );
  }

  void _onRoomStreamUpdate(
    String roomID,
    ZegoUpdateType updateType,
    List<ZegoStream> streamList,
    Map<String, dynamic> extendedData,
  ) {
    _log(
      'onRoomStreamUpdate',
      'room=$roomID type=$updateType count=${streamList.length} extendedData=$extendedData',
    );

    if (updateType == ZegoUpdateType.Add) {
      for (final stream in streamList) {
        if (stream.streamID == _streamId) {
          _log('skip own stream', 'id=${stream.streamID}');
          continue;
        }
        _log('playing remote stream', 'id=${stream.streamID} room=$roomID user=${stream.user.userID}');
        _playingStreamIds.add(stream.streamID);
        ZegoExpressEngine.instance.startPlayingStream(
          stream.streamID,
          config: ZegoPlayerConfig.defaultConfig(),
        );
      }
    } else if (updateType == ZegoUpdateType.Delete) {
      for (final stream in streamList) {
        _log('remote stream removed', 'id=${stream.streamID}');
        _playingStreamIds.remove(stream.streamID);
        ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
      }
    }
  }

  void _onPublisherStateUpdate(
    String streamID,
    ZegoPublisherState state,
    int errorCode,
    Map<String, dynamic> extendedData,
  ) {
    _log(
      'onPublisherStateUpdate',
      'stream=$streamID state=$state errorCode=$errorCode extendedData=$extendedData',
    );

    if (errorCode != 0) {
      _log('publisher error', 'stream=$streamID errorCode=$errorCode');
    }

    final target = _publisherStreamTarget;
    final waiter = _publisherCompleter;
    if (waiter == null || streamID != target) return;

    if (state == ZegoPublisherState.Publishing && errorCode == 0) {
      _safeCompleteBool(
        waiter,
        true,
        'PublisherCompleter',
        streamId: streamID,
        source: 'onPublisherStateUpdate.Publishing',
      );
    } else if (errorCode != 0) {
      _safeCompleteBool(
        waiter,
        false,
        'PublisherCompleter',
        streamId: streamID,
        source: 'onPublisherStateUpdate errorCode=$errorCode',
      );
    }
  }

  Future<void> _verifyEngineInstance() async {
    await ZegoExpressEngine.instance.muteMicrophone(false);
    _log('createEngine success', 'instance API verified appId=$_appId');
  }

  Future<void> _stopAllPlayingStreams() async {
    final ids = _playingStreamIds.toList();
    _playingStreamIds.clear();
    for (final id in ids) {
      try {
        _log('stopPlayingStream', 'id=$id');
        await ZegoExpressEngine.instance.stopPlayingStream(id);
      } catch (e, st) {
        _logError('stopPlayingStream', e, st);
      }
    }
  }

  /// stopPublishing → stopPlaying → logoutRoom
  Future<void> cleanupRoom({String? roomId, bool destroyEngineAfter = false}) async {
    final room = roomId ?? _currentRoom;
    _currentRoom = null;
    _streamId = null;
    _cancelRoomWait();
    _cancelPublisherWait();

    if (room == null && _playingStreamIds.isEmpty && !destroyEngineAfter) {
      return;
    }

    _setPhase(ZegoVoicePhase.leavingRoom, 'room=$room');

    try {
      _log('stopPublishingStream start');
      await ZegoExpressEngine.instance.stopPublishingStream();
      _log('stopPublishingStream success');
    } catch (e, st) {
      _logError('stopPublishingStream', e, st);
    }

    await _stopAllPlayingStreams();

    if (room != null) {
      try {
        _log('logoutRoom start', 'room=$room');
        await ZegoExpressEngine.instance.logoutRoom(room);
        _log('logoutRoom success', 'room=$room');
      } catch (e, st) {
        _logError('logoutRoom', e, st);
      }
    }

    await Future<void>.delayed(cleanupSettleDelay);

    if (destroyEngineAfter) {
      await destroyEngine();
    } else if (_engineCreated) {
      _setPhase(ZegoVoicePhase.engineReady, 'room cleanup done');
    } else {
      _setPhase(ZegoVoicePhase.idle, 'no engine');
    }
  }

  Future<void> destroyEngine() async {
    if (!_engineCreated) return;
    _setPhase(ZegoVoicePhase.destroyingEngine, 'destroyEngine start');
    _engineCreated = false;
    _callbacksRegistered = false;
    _appId = null;
    try {
      await ZegoExpressEngine.destroyEngine();
      _log('destroyEngine success');
      _setPhase(ZegoVoicePhase.idle, 'engine destroyed');
    } catch (e, st) {
      _logError('destroyEngine', e, st);
      _setPhase(ZegoVoicePhase.failed, 'destroy failed');
    }
  }

  void _disposeRoomWait() {
    _roomConnectTimer?.cancel();
    _roomConnectTimer = null;
    _roomConnectTarget = null;
    _roomConnectCompleter = null;
  }

  void _cancelRoomWait() {
    _roomConnectTimer?.cancel();
    _roomConnectTimer = null;
    final waiter = _roomConnectCompleter;
    if (waiter != null && !waiter.isCompleted) {
      _log('[RoomCompleter] cancel', 'isCompleted=false');
      waiter.complete(false);
    } else if (waiter != null) {
      _log('[RoomCompleter] cancel skipped', 'isCompleted=true');
    }
    _roomConnectTarget = null;
    _roomConnectCompleter = null;
  }

  void _disposePublisherWait() {
    _publisherTimer?.cancel();
    _publisherTimer = null;
    _publisherStreamTarget = null;
    _publisherCompleter = null;
  }

  void _cancelPublisherWait() {
    _publisherTimer?.cancel();
    _publisherTimer = null;
    final waiter = _publisherCompleter;
    if (waiter != null && !waiter.isCompleted) {
      _log('[PublisherCompleter] cancel', 'isCompleted=false stream=$_publisherStreamTarget');
      waiter.complete(false);
    } else if (waiter != null) {
      _log('[PublisherCompleter] cancel skipped', 'isCompleted=true stream=$_publisherStreamTarget');
    }
    _publisherStreamTarget = null;
    _publisherCompleter = null;
  }

  Future<bool> _waitForRoomConnected(String roomId) async {
    _cancelRoomWait();
    _roomConnectTarget = roomId;
    final completer = Completer<bool>();
    _roomConnectCompleter = completer;

    _log('wait room connected', 'room=$roomId timeout=${roomConnectTimeout.inSeconds}s');

    _roomConnectTimer = Timer(roomConnectTimeout, () {
      _log(
        'room connected TIMEOUT',
        'room=$roomId after ${roomConnectTimeout.inSeconds}s isCompleted=${completer.isCompleted}',
      );
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    try {
      return await completer.future;
    } finally {
      _disposeRoomWait();
    }
  }

  Future<bool> _waitForPublisherPublishing(String streamId) async {
    _cancelPublisherWait();
    _publisherStreamTarget = streamId;
    final completer = Completer<bool>();
    _publisherCompleter = completer;

    _log('wait publisher Publishing', 'stream=$streamId timeout=${publishConfirmTimeout.inSeconds}s');

    _publisherTimer = Timer(publishConfirmTimeout, () {
      _log(
        'publisher Publishing TIMEOUT',
        'stream=$streamId after ${publishConfirmTimeout.inSeconds}s isCompleted=${completer.isCompleted} — proceeding anyway',
      );
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });

    try {
      return await completer.future;
    } finally {
      _disposePublisherWait();
    }
  }

  Future<void> _awaitNativePluginReady() async {
    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final version = await ZegoExpressEngine.getVersion();
        _log(
          'native plugin channel ready',
          'getVersion=$version attempt=$attempt',
        );
        return;
      } on MissingPluginException catch (e, st) {
        lastError = e;
        lastStack = st;
        _logError('native plugin probe attempt=$attempt', e, st);
        if (attempt < 3) {
          await Future<void>.delayed(Duration(milliseconds: 200 * attempt));
        }
      }
    }
    Error.throwWithStackTrace(
      lastError ?? 'Zego native MethodChannel not responding',
      lastStack ?? StackTrace.current,
    );
  }

  Future<void> ensureEngine(int appId, {bool force = false}) async {
    return _withMutex(() async {
      if (appId <= 0) throw StateError('Invalid ZEGOCLOUD app id: $appId');

      if (!force && _engineCreated && _appId == appId && _phase != ZegoVoicePhase.failed) {
        if (!_callbacksRegistered) _registerCallbacks();
        try {
          await _verifyEngineInstance();
          return;
        } catch (e, st) {
          _logError('engine verify', e, st);
          await cleanupRoom(destroyEngineAfter: true);
        }
      }

      if (_currentRoom != null || _phase == ZegoVoicePhase.inCall) {
        await cleanupRoom();
      }
      if (_engineCreated) {
        await destroyEngine();
      }

      _setPhase(ZegoVoicePhase.creatingEngine, 'appId=$appId');
      _log('createEngine start', 'appId=$appId');

      await _awaitNativePluginReady();

      try {
        await ZegoExpressEngine.createEngineWithProfile(
          ZegoEngineProfile(appId, ZegoScenario.StandardVoiceCall),
        );
      } on MissingPluginException catch (e, st) {
        _appId = null;
        _setPhase(ZegoVoicePhase.failed, 'MissingPluginException');
        _logError('createEngine MissingPluginException', e, st);
        rethrow;
      } catch (e, st) {
        _appId = null;
        _setPhase(ZegoVoicePhase.failed, e.toString());
        _logError('createEngine', e, st);
        rethrow;
      }

      _appId = appId;
      _registerCallbacks();
      await _verifyEngineInstance();
      _engineCreated = true;
      _setPhase(ZegoVoicePhase.engineReady, 'appId=$appId');
    });
  }

  Future<ZegoVoiceJoinResult> joinCall({
    required int appId,
    required String roomId,
    required String userId,
    required String userName,
    required String token,
  }) async {
    if (_currentRoom == roomId && _streamId == 'stream_$userId' && _phase == ZegoVoicePhase.inCall) {
      _log('already in call', 'room=$roomId user=$userId stream=$_streamId');
      return const ZegoVoiceJoinResult.success();
    }

    if (_currentRoom != null && _currentRoom != roomId) {
      await cleanupRoom();
    }

    final localStreamId = 'stream_$userId';
    Object? lastError;
    StackTrace? lastStack;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) {
          _log('retry join', 'attempt=${attempt + 1} — cleanup then recreate engine');
          await cleanupRoom(destroyEngineAfter: true);
        }

        await ensureEngine(appId, force: attempt > 0);

        final config = ZegoRoomConfig.defaultConfig()
          ..token = token
          ..isUserStatusNotify = true;

        _setPhase(ZegoVoicePhase.loggingIn, 'room=$roomId user=$userId');
        _log(
          'loginRoom start',
          'room=$roomId user=$userId appId=$appId tokenLen=${token.length} stream=$localStreamId',
        );

        final roomWait = _waitForRoomConnected(roomId);

        await ZegoExpressEngine.instance.loginRoom(
          roomId,
          ZegoUser(userId, userName),
          config: config,
        );

        final roomOk = await roomWait;
        if (!roomOk) {
          await cleanupRoom(roomId: roomId);
          return ZegoVoiceJoinResult.failure(
            detail: 'Room did not reach Connected (errorCode or ${roomConnectTimeout.inSeconds}s timeout)',
          );
        }

        _streamId = localStreamId;
        _setPhase(ZegoVoicePhase.publishing, 'stream=$localStreamId');
        _log('startPublishingStream start', 'stream=$localStreamId room=$roomId user=$userId');

        final publishWait = _waitForPublisherPublishing(localStreamId);
        await ZegoExpressEngine.instance.startPublishingStream(localStreamId);
        final publishOk = await publishWait;

        if (!publishOk) {
          await cleanupRoom(roomId: roomId);
          return const ZegoVoiceJoinResult.failure(
            detail: 'Publisher did not reach Publishing state (errorCode non-zero)',
          );
        }

        _log('publish success', 'stream=$localStreamId room=$roomId user=$userId');

        _currentRoom = roomId;
        _setPhase(ZegoVoicePhase.inCall, 'room=$roomId stream=$localStreamId');

        await _activateVoiceAudio();
        _log('inCall ready', 'room=$roomId user=$userId stream=$localStreamId appId=$appId');
        return const ZegoVoiceJoinResult.success();
      } on MissingPluginException catch (e, st) {
        lastError = e;
        lastStack = st;
        _logError('joinCall MissingPluginException attempt=${attempt + 1}', e, st);
        await cleanupRoom(roomId: roomId, destroyEngineAfter: true);
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        _logError('joinCall attempt=${attempt + 1}', e, st);
        if (e is MissingPluginException || e.toString().contains('MissingPluginException')) {
          await cleanupRoom(roomId: roomId, destroyEngineAfter: true);
          continue;
        }
        await cleanupRoom(roomId: roomId);
        return ZegoVoiceJoinResult.failure(detail: e.toString());
      }
    }

    if (lastError != null && lastStack != null) {
      _logError('joinCall final failure', lastError, lastStack);
    }
    _setPhase(ZegoVoicePhase.failed, lastError?.toString() ?? 'unknown');
    return ZegoVoiceJoinResult.failure(
      detail: lastError?.toString() ?? 'Voice join failed after retries',
      pluginMissing: lastError is MissingPluginException,
    );
  }

  Future<void> _activateVoiceAudio({bool speakerOn = true}) async {
    try {
      await ZegoExpressEngine.instance.muteMicrophone(false);
      await ZegoExpressEngine.instance.muteSpeaker(false);
      await ZegoExpressEngine.instance.setAudioRouteToSpeaker(speakerOn);
      _log('audio route active', 'speaker=$speakerOn mic=unmuted');
    } catch (e, st) {
      _logError('activateVoiceAudio', e, st);
    }
  }

  Future<void> leaveCall() async {
    await cleanupRoom();
  }

  Future<void> destroy() async {
    await cleanupRoom(destroyEngineAfter: true);
  }

  Future<void> setMicrophoneMuted(bool muted) async {
    await ZegoExpressEngine.instance.muteMicrophone(muted);
    _log('microphone', muted ? 'muted' : 'unmuted');
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    await ZegoExpressEngine.instance.muteSpeaker(false);
    await ZegoExpressEngine.instance.setAudioRouteToSpeaker(enabled);
    _log('speaker', enabled ? 'speaker' : 'earpiece');
  }
}
