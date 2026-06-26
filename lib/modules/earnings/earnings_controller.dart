import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/parse_utils.dart';

class EarningsController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final isLoading = true.obs;
  final todayEarnings = 0.0.obs;
  final weeklyEarnings = 0.0.obs;
  final monthlyEarnings = 0.0.obs;
  final totalEarnings = 0.0.obs;
  final withdrawBalance = 0.0.obs;
  final history = <Map<String, dynamic>>[].obs;

  final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      await Future.wait([_loadSummary(), _loadHistory()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSummary() async {
    try {
      final response = await _api.get(ApiConstants.earningsSummary);
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;
      todayEarnings.value = JsonParse.toDouble(data['today_earnings']);
      weeklyEarnings.value = JsonParse.toDouble(data['weekly_earnings']);
      monthlyEarnings.value = JsonParse.toDouble(data['monthly_earnings']);
      totalEarnings.value = JsonParse.toDouble(data['total_earnings']);
      withdrawBalance.value = JsonParse.toDouble(data['withdraw_balance']);
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    }
  }

  Future<void> _loadHistory() async {
    try {
      final response = await _api.get(ApiConstants.earningsHistory);
      history.assignAll(JsonParse.toMapList(response.data['data']));
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    }
  }
}
