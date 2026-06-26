import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/host_availability_service.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final DeviceService _device = Get.find<DeviceService>();
  final AuthSessionService _authSession = Get.find<AuthSessionService>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      Get.snackbar('Required', 'Enter username and password');
      return;
    }

    isLoading.value = true;
    try {
      await _device.ensureFcmReady();
      _device.printDetails();

      final response = await _api.post(
        ApiConstants.hostLogin,
        data: {
          'username': username,
          'password': password,
          ..._device.loginFields,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;
      await _authSession.persistLoginResponse(data);

      await _device.syncWithServer();

      if (Get.isRegistered<HostAvailabilityService>()) {
        await Get.find<HostAvailabilityService>().setAvailable(true);
      }

      Get.offAllNamed(AppRoutes.mainShell);
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
