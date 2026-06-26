import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/call_error_message.dart';
import '../../core/utils/mic_permission.dart';
import '../../core/utils/parse_utils.dart';
import '../../data/models/caller_model.dart';
import '../../routes/app_routes.dart';

class OnlineUsersController extends GetxController {
  final ApiService _api = Get.find<ApiService>();

  final isLoading = false.obs;
  final isCalling = false.obs;
  final onlineUsers = <CallerModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      final response = await _api.get(ApiConstants.callersOnline);
      final list = JsonParse.toMapList(response.data['data']);
      onlineUsers.value = list.map(CallerModel.fromJson).toList();
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> callUser(CallerModel user) async {
    isCalling.value = true;
    try {
      final mic = await requestMicrophonePermission();
      if (mic != MicPermissionOutcome.granted) {
        Get.snackbar('Microphone required', micPermissionMessage(mic));
        if (mic == MicPermissionOutcome.permanentlyDenied) {
          await openMicrophoneSettings();
        }
        return;
      }

      final response = await _api.post(
        ApiConstants.callsInitiateCaller,
        data: {'caller_id': user.id},
      );
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;
      Get.toNamed(
        AppRoutes.outgoingCall,
        arguments: {
          ...data,
          'caller_name': user.name,
          'name': user.name,
        },
      );
    } on DioException catch (e) {
      Get.snackbar('Call failed', callErrorMessage(_api.extractError(e)));
    } finally {
      isCalling.value = false;
    }
  }
}
