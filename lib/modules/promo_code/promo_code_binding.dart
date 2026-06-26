import 'package:get/get.dart';

import 'promo_code_controller.dart';

class PromoCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(PromoCodeController.new);
  }
}
