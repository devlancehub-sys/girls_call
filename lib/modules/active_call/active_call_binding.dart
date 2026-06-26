import 'package:get/get.dart';

import 'active_call_controller.dart';

class ActiveCallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ActiveCallController.new, fenix: true);
  }
}
