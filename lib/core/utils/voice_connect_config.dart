/// Voice join retry tuning — automatic attempts before showing Retry Voice UI.
class VoiceConnectConfig {
  VoiceConnectConfig._();

  static const maxAttempts = 8;
  static const initialSettleMs = 600;

  /// Delay before attempt [attempt] (1-based). First attempt waits for accept/DB settle.
  static int delayBeforeAttempt(int attempt) {
    if (attempt <= 1) return initialSettleMs;
    return 500 + (attempt - 1) * 400;
  }
}
