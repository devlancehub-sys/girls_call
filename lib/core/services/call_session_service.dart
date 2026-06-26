import 'package:get/get.dart';

import '../utils/parse_utils.dart';

typedef CallEndedHandler = Future<void> Function(Map<String, dynamic> data);

class CallSessionService extends GetxService {
  int? _activeCallId;
  CallEndedHandler? _onRemoteEnd;
  bool _handlingEnd = false;

  void register(int callId, CallEndedHandler onRemoteEnd) {
    _activeCallId = callId;
    _onRemoteEnd = onRemoteEnd;
    _handlingEnd = false;
  }

  void unregister() {
    _activeCallId = null;
    _onRemoteEnd = null;
    _handlingEnd = false;
  }

  Future<void> handleCallEnded(Map<String, dynamic> data) async {
    if (_handlingEnd) return;

    final endedId = JsonParse.toInt(data['call_id']);
    if (_activeCallId == null || endedId <= 0 || endedId != _activeCallId) return;

    _handlingEnd = true;
    final handler = _onRemoteEnd;
    try {
      if (handler != null) {
        await handler(data);
      }
    } finally {
      unregister();
      _handlingEnd = false;
    }
  }

  bool matchesCallId(Map<String, dynamic> data, int callId) {
    return JsonParse.toInt(data['call_id']) == callId;
  }
}
