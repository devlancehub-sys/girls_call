import 'package:get/get.dart';

import 'online_users_controller.dart';

class OnlineUsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(OnlineUsersController.new);
  }
}
