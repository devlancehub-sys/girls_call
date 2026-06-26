/// Normalizes FCM / socket call-invite payloads into the shape expected by
/// [IncomingCallController] and navigation.
class FcmPayloadMapper {
  FcmPayloadMapper._();

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  static Map<String, dynamic> toCallArguments(Map<String, dynamic> data) {
    return {
      'call_id': _toInt(data['call_id'] ?? data['id']),
      'caller_id': _toInt(data['caller_id']),
      'host_id': _toInt(data['host_id']),
      'room_id': data['room_id'],
      'rate_per_minute': double.tryParse('${data['rate_per_minute']}') ?? 0,
      'host_earning_per_minute':
          double.tryParse('${data['host_earning_per_minute']}') ?? 0,
      'caller_name': data['caller_name'],
      'caller_avatar_url': data['caller_avatar_url'],
      'initiated_by': data['initiated_by'] ?? 'male',
      'zego_app_id': _toInt(data['zego_app_id']),
    };
  }

  static String callerName(Map<String, dynamic> data) =>
      data['caller_name']?.toString() ?? 'Caller';
}
