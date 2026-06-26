import 'package:get/get.dart';

import '../modules/call_history/call_history_binding.dart';
import '../modules/call_history/call_history_view.dart';
import '../modules/active_call/active_call_binding.dart';
import '../modules/active_call/active_call_view.dart';
import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_view.dart';
import '../modules/earnings/earnings_binding.dart';
import '../modules/earnings/earnings_view.dart';
import '../modules/incoming_call/incoming_call_binding.dart';
import '../modules/incoming_call/incoming_call_view.dart';
import '../modules/main_shell/main_shell_binding.dart';
import '../modules/main_shell/main_shell_view.dart';
import '../modules/outgoing_call/outgoing_call_binding.dart';
import '../modules/outgoing_call/outgoing_call_view.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile/profile_view.dart';
import '../modules/promo_code/promo_code_binding.dart';
import '../modules/promo_code/promo_code_view.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/withdraw/withdraw_binding.dart';
import '../modules/withdraw/withdraw_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.mainShell,
      page: () => const MainShellView(),
      binding: MainShellBinding(),
    ),
    GetPage(
      name: AppRoutes.incomingCall,
      page: () => const IncomingCallView(),
      binding: IncomingCallBinding(),
    ),
    GetPage(
      name: AppRoutes.outgoingCall,
      page: () => const OutgoingCallView(),
      binding: OutgoingCallBinding(),
    ),
    GetPage(
      name: AppRoutes.activeCall,
      page: () => const ActiveCallView(),
      binding: ActiveCallBinding(),
    ),
    GetPage(
      name: AppRoutes.earnings,
      page: () => const EarningsView(),
      binding: EarningsBinding(),
    ),
    GetPage(
      name: AppRoutes.withdraw,
      page: () => const WithdrawView(),
      binding: WithdrawBinding(),
    ),
    GetPage(
      name: AppRoutes.callHistory,
      page: () => const CallHistoryView(),
      binding: CallHistoryBinding(),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.promoCode,
      page: () => const PromoCodeView(),
      binding: PromoCodeBinding(),
    ),
  ];
}
