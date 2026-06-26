import 'package:get/get.dart';

import 'call_history_controller.dart';

class CallHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => CallHistoryController());
  }
}
