import 'package:get/get.dart';

import '../dashboard/dashboard_binding.dart';
import '../online_users/online_users_binding.dart';
import '../profile/profile_binding.dart';
import 'main_shell_controller.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(MainShellController.new);
    DashboardBinding().dependencies();
    OnlineUsersBinding().dependencies();
    ProfileBinding().dependencies();
  }
}
