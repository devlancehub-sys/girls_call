import 'package:flutter/foundation.dart' show kDebugMode;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/girls_avatar_assets.dart';
import '../../core/services/host_availability_service.dart';
import '../../core/services/presence_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../../core/utils/parse_utils.dart';
import '../../routes/app_routes.dart';

class ProfileController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final StorageService _storage = Get.find<StorageService>();
  final PresenceService _presence = Get.find<PresenceService>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final isLoggingOut = false.obs;
  final callVibrateEnabled = true.obs;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final ageController = TextEditingController();
  final aboutController = TextEditingController();

  final name = ''.obs;
  final username = ''.obs;
  final avatarUrl = GirlsAvatarAssets.defaultFileName.obs;
  final totalCalls = 0.obs;
  final rating = 0.0.obs;

  // Tier information
  final currentTier = 'iron'.obs;
  final currentTierLabel = ''.obs;
  final lifetimeTalkMinutes = 0.obs;
  final callRate = 0.0.obs;
  final unlockedTiers = <String>[].obs;
  final lockedTiers = <String>[].obs;
  final isChangingTier = false.obs;

  String? get selectedAvatarFileName =>
      GirlsAvatarAssets.presetFileName(avatarUrl.value);

  void selectAvatar(String fileName) {
    avatarUrl.value = fileName;
  }

  @override
  void onInit() {
    super.onInit();
    callVibrateEnabled.value = _storage.callVibrateEnabled;
    _loadFromCache();
    loadProfile(forceRefresh: false);
  }

  void _loadFromCache() {
    final cached = _storage.cachedProfile;
    if (cached == null) return;
    _applyProfileData(cached);
    isLoading.value = false;
  }

  void _applyProfileData(Map<String, dynamic> data) {
    nameController.text = data['name']?.toString() ?? '';
    emailController.text = data['email']?.toString() ?? '';
    ageController.text = data['age']?.toString() ?? '';
    aboutController.text = data['about']?.toString() ?? '';
    name.value = data['name']?.toString() ?? '';
    username.value = data['username']?.toString() ?? '';
    final storedAvatar = data['avatar_url']?.toString();
    avatarUrl.value = GirlsAvatarAssets.presetFileName(storedAvatar) ??
        GirlsAvatarAssets.defaultFileName;
    totalCalls.value = JsonParse.toInt(data['total_calls']);
    rating.value = JsonParse.toDouble(data['rating']);
    currentTier.value = data['tier']?.toString() ?? 'iron';
  }

  Future<void> loadProfile({bool forceRefresh = true}) async {
    if (forceRefresh || _storage.cachedProfile == null) {
      isLoading.value = true;
    }
    try {
      final response = await _api.get(ApiConstants.profile);
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;

      _applyProfileData(data);
      await _storage.updateCachedProfile(data);
    } on DioException catch (e) {
      if (_storage.cachedProfile == null) {
        Get.snackbar('Error', _api.extractError(e));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    isSaving.value = true;
    try {
      await _api.put(
        ApiConstants.profile,
        data: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'age': int.tryParse(ageController.text.trim()),
          'about': aboutController.text.trim(),
          'avatar_url': avatarUrl.value,
        },
      );
      name.value = nameController.text.trim();
      Get.snackbar('Success', 'Profile updated');
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> logout() async {
    isLoggingOut.value = true;
    try {
      final refresh = _storage.refreshToken;
      if (refresh != null) {
        await _api.post(ApiConstants.logout, data: {'refreshToken': refresh});
      }
    } catch (_) {
      // Continue logout locally even if API fails
    } finally {
      if (Get.isRegistered<HostAvailabilityService>()) {
        await Get.find<HostAvailabilityService>().goOffline();
      } else {
        await _presence.goOffline();
      }
      await _storage.clearAuth();
      isLoggingOut.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
  }

  Future<void> setCallVibrateEnabled(bool value) async {
    callVibrateEnabled.value = value;
    await _storage.setCallVibrateEnabled(value);
  }


  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    aboutController.dispose();
    super.onClose();
  }
}
