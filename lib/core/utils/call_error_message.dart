/// Maps backend/API errors to user-friendly call messages.
String callErrorMessage(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('internal server error') || lower.contains('internal issue')) {
    return 'Server error during call. Ask admin to deploy latest backend and check ZEGOCLOUD env on Railway.';
  }
  if (lower.contains('zegocloud') ||
      (lower.contains('voice call') && lower.contains('unavailable'))) {
    return 'Voice calls are not available right now. Please try again later.';
  }
  if (lower.contains('offline')) {
    return 'User is offline';
  }
  if (lower.contains('insufficient balance')) {
    return 'User has insufficient balance';
  }
  return raw;
}
