import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/parse_utils.dart';

class CallHistoryController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final calls = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final response = await _api.get(
        ApiConstants.callsHistory,
        query: {'page': 1, 'limit': 50},
      );
      calls.assignAll(JsonParse.toMapList(response.data['data']));
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isLoading.value = false;
    }
  }
}
