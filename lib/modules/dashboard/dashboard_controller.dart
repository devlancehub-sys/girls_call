import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/host_availability_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/utils/parse_utils.dart';

class DashboardController extends GetxController {
  final ApiService _api = Get.find<ApiService>();
  final HostAvailabilityService _availability = Get.find<HostAvailabilityService>();
  final SocketService _socket = Get.find<SocketService>();

  final isLoading = true.obs;
  final isTogglingAvailability = false.obs;
  final isClaimingReward = false.obs;

  final todayEarnings = 0.0.obs;
  final totalEarnings = 0.0.obs;
  final withdrawBalance = 0.0.obs;
  final walletBalance = 0.0.obs;
  final callsToday = 0.obs;
  final totalCalls = 0.obs;
  final rating = 0.0.obs;
  final ratePerMinute = 0.0.obs;
  final hostName = ''.obs;
  final onlineDurationSeconds = 0.obs;

  // Tier
  final currentTier = ''.obs;
  final currentTierLabel = ''.obs;
  final lifetimeTalkMinutes = 0.obs;
  final nextTier = ''.obs;
  final nextTierLabel = ''.obs;
  final minutesToNextTier = 0.obs;
  final dayHostShare = 0.0.obs;
  final nightHostShare = 0.0.obs;
  final unlockedTiers = <String>[].obs;
  final lockedTiers = <String>[].obs;
  final isChangingTier = false.obs;

  Timer? _durationTimer;

  bool get isAvailable => _availability.isAvailable;
  HostStatus get hostStatus => _availability.hostStatus.value;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    _socket.on('earning_updated', (_) => _loadEarnings());
    _startDurationTicker();
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _socket.off('earning_updated');
    super.onClose();
  }

  void _startDurationTicker() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_availability.isAvailable) {
        onlineDurationSeconds.value = _availability.onlineDurationSeconds.value + 30;
        unawaited(_availability.refresh());
      }
    });
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadProfile(),
        _loadEarnings(),
        _loadTierInfo(),
        _availability.refresh(),
      ]);
      onlineDurationSeconds.value = _availability.onlineDurationSeconds.value;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleAvailability(bool enabled) async {
    isTogglingAvailability.value = true;
    try {
      final ok = await _availability.setAvailable(enabled);
      if (ok) {
        onlineDurationSeconds.value = _availability.onlineDurationSeconds.value;
        Get.snackbar(
          enabled ? 'Available' : 'Busy',
          enabled
              ? 'You can receive calls — app works in background'
              : 'New calls are paused until you turn Available ON',
        );
      }
    } finally {
      isTogglingAvailability.value = false;
    }
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _api.get(ApiConstants.profile);
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;
      totalCalls.value = JsonParse.toInt(data['total_calls']);
      rating.value = JsonParse.toDouble(data['rating']);
      ratePerMinute.value = JsonParse.toDouble(data['rate_per_minute']);
      hostName.value = data['name']?.toString() ?? 'Host';
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    }
  }

  Future<void> _loadEarnings() async {
    try {
      final response = await _api.get(ApiConstants.earningsSummary);
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;
      todayEarnings.value = JsonParse.toDouble(data['today_earnings']);
      totalEarnings.value = JsonParse.toDouble(data['total_earnings']);
      withdrawBalance.value = JsonParse.toDouble(data['withdraw_balance']);
      walletBalance.value = JsonParse.toDouble(data['wallet_balance']);
      callsToday.value = JsonParse.toInt(data['calls_today']);
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    }
  }

  String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  bool get isOffline => hostStatus == HostStatus.offline;

  Map<String, int> get tierRequirements => {
    'iron': 0,
    'silver': 60,
    'gold': 120,
    'diamond': 180,
  };

  String? canChangeTier(String tier) {
    if (!isOffline) {
      return 'Tier can only be changed while you are offline';
    }
    
    final requiredMinutes = tierRequirements[tier.toLowerCase()] ?? 0;
    if (lifetimeTalkMinutes.value < requiredMinutes) {
      final needed = requiredMinutes - lifetimeTalkMinutes.value;
      return 'Need $needed more minutes to unlock $tier';
    }
    
    return null;
  }

  Future<void> changeTier(String tier) async {
    final validationError = canChangeTier(tier);
    if (validationError != null) {
      Get.snackbar('Cannot Change Tier', validationError);
      return;
    }

    isChangingTier.value = true;
    try {
      await _api.post(ApiConstants.hostChangeTier, data: {'tier': tier});
      await _loadTierInfo();
      await _loadProfile();
      Get.snackbar('Tier Updated', 'Your tier has been changed to $tier');
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isChangingTier.value = false;
    }
  }

  Future<void> _loadTierInfo() async {
    try {
      final response = await _api.get(ApiConstants.hostTier);
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;
      currentTier.value = data['active_tier']?.toString() ?? '';
      lifetimeTalkMinutes.value = JsonParse.toInt(data['lifetime_talk_minutes']);
      dayHostShare.value = JsonParse.toDouble(data['day_host_share']);
      nightHostShare.value = JsonParse.toDouble(data['night_host_share']);
      debugPrint('[Dashboard] Tier info loaded: $data');
    } on DioException catch (e) {
      debugPrint('[Dashboard] tier info load failed: ${_api.extractError(e)}');
      // Fallback: calculate tier from profile data
      _calculateTierFromProfile();
    }

    try {
      final response = await _api.get(ApiConstants.hostTierProgress);
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;
      currentTierLabel.value = data['current_tier_label']?.toString() ?? '';
      nextTier.value = data['next_tier']?.toString() ?? '';
      nextTierLabel.value = data['next_tier_label']?.toString() ?? '';
      minutesToNextTier.value = JsonParse.toInt(data['minutes_to_next_tier']);
      final unlocked = data['unlocked_tiers'];
      if (unlocked is List) {
        unlockedTiers.value = unlocked.map((e) => e.toString()).toList();
      }
      final locked = data['locked_tiers'];
      if (locked is List) {
        lockedTiers.value = locked.map((e) => e.toString()).toList();
      }
      debugPrint('[Dashboard] Tier progress loaded: $data');
    } on DioException catch (e) {
      debugPrint('[Dashboard] tier progress load failed: ${_api.extractError(e)}');
      // Fallback: calculate progress from current tier
      _calculateTierProgress();
    }
  }

  void _calculateTierFromProfile() {
    // Fallback calculation based on total calls and rating
    final minutes = lifetimeTalkMinutes.value > 0 ? lifetimeTalkMinutes.value : (totalCalls.value * 5); // Assume 5 min avg call
    _calculateTierFromMinutes(minutes);
  }

  void _calculateTierFromMinutes(int minutes) {
    String tier = 'iron';
    String label = 'Iron';
    String nextTierStr = 'silver';
    String nextLabel = 'Silver';
    int minutesToNext = 60 - minutes;
    final dayShare = 45.0;
    final nightShare = 50.0;

    if (minutes >= 180) {
      tier = 'diamond';
      label = 'Diamond';
      nextTierStr = '';
      nextLabel = '';
      minutesToNext = 0;
    } else if (minutes >= 120) {
      tier = 'gold';
      label = 'Gold';
      nextTierStr = 'diamond';
      nextLabel = 'Diamond';
      minutesToNext = 180 - minutes;
    } else if (minutes >= 60) {
      tier = 'silver';
      label = 'Silver';
      nextTierStr = 'gold';
      nextLabel = 'Gold';
      minutesToNext = 120 - minutes;
    }

    currentTier.value = tier;
    currentTierLabel.value = label;
    nextTier.value = nextTierStr;
    nextTierLabel.value = nextLabel;
    minutesToNextTier.value = minutesToNext;
    dayHostShare.value = dayShare;
    nightHostShare.value = nightShare;
    lifetimeTalkMinutes.value = minutes;

    // Set unlocked/locked tiers
    unlockedTiers.value = ['iron'];
    lockedTiers.value = ['silver', 'gold', 'diamond'];
    if (minutes >= 60) {
      unlockedTiers.value = ['iron', 'silver'];
      lockedTiers.value = ['gold', 'diamond'];
    }
    if (minutes >= 120) {
      unlockedTiers.value = ['iron', 'silver', 'gold'];
      lockedTiers.value = ['diamond'];
    }
    if (minutes >= 180) {
      unlockedTiers.value = ['iron', 'silver', 'gold', 'diamond'];
      lockedTiers.value = [];
    }
  }

  void _calculateTierProgress() {
    _calculateTierFromMinutes(lifetimeTalkMinutes.value);
  }
}
