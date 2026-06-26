import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/parse_utils.dart';

class WithdrawController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final withdrawBalance = 0.0.obs;
  final history = <Map<String, dynamic>>[].obs;

  final amountController = TextEditingController();
  final accountController = TextEditingController();
  final selectedMethod = 'upi'.obs;

  final methods = ['upi', 'bank', 'paytm'];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final summary = await _api.get(ApiConstants.earningsSummary);
      final data = JsonParse.toMap(summary.data['data']);
      if (data == null) return;
      withdrawBalance.value = JsonParse.toDouble(data['withdraw_balance']);

      final historyResponse = await _api.get(ApiConstants.withdrawHistory);
      history.assignAll(JsonParse.toMapList(historyResponse.data['data']));
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitWithdraw() async {
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount < 100) {
      Get.snackbar('Invalid amount', 'Minimum withdraw is ₹100');
      return;
    }

    if (accountController.text.trim().isEmpty) {
      Get.snackbar('Required', 'Enter account details');
      return;
    }

    isSubmitting.value = true;
    try {
      await _api.post(
        ApiConstants.withdraw,
        data: {
          'amount': amount.round(),
          'method': selectedMethod.value,
          'account_details': {'detail': accountController.text.trim()},
        },
      );
      amountController.clear();
      accountController.clear();
      Get.snackbar('Success', 'Withdraw request submitted');
      await loadData();
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    amountController.dispose();
    accountController.dispose();
    super.onClose();
  }
}
