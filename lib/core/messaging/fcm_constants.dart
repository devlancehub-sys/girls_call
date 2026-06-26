/// FCM data payload keys and message types used by the backend.
class FcmConstants {
  FcmConstants._();

  static const typeKey = 'type';

  /// Primary type for voice call invites from the server.
  static const callInvite = 'call_invite';

  /// Legacy alias kept for backward compatibility with existing pushes.
  static const incomingCall = 'incoming_call';

  static const isCallInviteTypes = {callInvite, incomingCall};

  static bool isCallInvite(String? type) =>
      type != null && isCallInviteTypes.contains(type);
}
