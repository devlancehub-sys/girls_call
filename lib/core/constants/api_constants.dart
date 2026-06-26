import '../config/app_config.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get socketUrl => AppConfig.socketUrl;

  /// Backend route: POST /api/auth/host/login
  static const String hostLogin = '/auth/host/login';
  static const String hostSendOtp = '/auth/host/send-otp';
  static const String hostVerifyOtp = '/auth/host/verify-otp';
  static const String verifyAccessKey = '/auth/host/verify-access-key';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  static const String profile = '/users/profile';
  static const String onlineStatus = '/users/online-status';
  static const String deviceSync = '/users/device';

  static const String hostAvailability = '/host/availability';
  static const String hostDailyTask = '/host/daily-task';
  static const String hostDailyTaskClaim = '/host/daily-task/claim-reward';
  static const String hostWeeklyBonusClaim = '/host/daily-task/claim-weekly-bonus';

  static const String callersOnline = '/callers/online';
  static const String callersBrowse = '/callers';

  static const String callsInitiateCaller = '/calls/initiate-caller';
  static const String callsHistory = '/calls/history';
  static const String callsPrefix = '/calls';
  static const String health = '/health';

  static String callJoinVoice(int id) => '$callsPrefix/$id/join-voice';

  static const String earningsSummary = '/earnings/summary';
  static const String earningsHistory = '/earnings/history';

  static const String withdraw = '/withdraw';
  static const String withdrawHistory = '/withdraw/history';

  static const String promoValidate = '/promo-codes/validate';
  static const String promoApply = '/promo-codes/apply';
}
