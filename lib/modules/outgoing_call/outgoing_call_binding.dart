import 'package:get/get.dart';

import 'outgoing_call_controller.dart';

class OutgoingCallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(OutgoingCallController.new);
  }
}
