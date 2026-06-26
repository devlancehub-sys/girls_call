import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/parse_utils.dart';

class PromoCodeController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final codeController = TextEditingController();
  final isApplying = false.obs;
  final lastResult = Rxn<Map<String, dynamic>>();

  Future<void> applyPromoCode() async {
    final code = codeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Required', 'Enter a promo code');
      return;
    }

    isApplying.value = true;
    lastResult.value = null;

    try {
      final validateResponse = await _api.post(
        ApiConstants.promoValidate,
        data: {'promo_code': code},
      );
      final validateData = JsonParse.toMap(validateResponse.data['data']);
      if (validateData == null || validateData['valid'] != true) {
        lastResult.value = {
          'success': false,
          'message': validateData?['message']?.toString() ?? 'Invalid promo code',
        };
        return;
      }

      final applyResponse = await _api.post(
        ApiConstants.promoApply,
        data: {'promo_code': code},
      );

      final applyData = JsonParse.toMap(applyResponse.data['data']);
      lastResult.value = {
        'success': true,
        'message': applyResponse.data['message']?.toString() ?? 'Bonus added to wallet',
        'bonusAmount': applyData?['bonusAmount'],
      };
      codeController.clear();
      Get.snackbar('Success', 'Bonus added to your wallet');
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
      lastResult.value = {
        'success': false,
        'message': _api.extractError(e),
      };
    } finally {
      isApplying.value = false;
    }
  }

  @override
  void onClose() {
    codeController.dispose();
    super.onClose();
  }
}
