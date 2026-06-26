import 'package:get/get.dart';

import 'withdraw_controller.dart';

class WithdrawBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(WithdrawController.new);
  }
}
