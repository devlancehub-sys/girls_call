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
  final isClaimingWeeklyBonus = false.obs;

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

  // Daily task
  final dailyMinCalls = 6.obs;
  final dailyMinMinutes = 60.obs;
  final completedCalls = 0.obs;
  final completedMinutes = 0.obs;
  final progressCallsPercent = 0.obs;
  final progressMinutesPercent = 0.obs;
  final targetMet = false.obs;
  final earningStatusActive = false.obs;
  final streakCount = 0.obs;
  final dailyRewardAmount = 0.0.obs;
  final rewardClaimed = false.obs;
  final canClaimReward = false.obs;

  // Weekly bonus
  final weeklyBonusAmount = 0.0.obs;
  final weeklyDaysCompleted = 0.obs;
  final weeklyDaysRequired = 7.obs;
  final weeklyBonusGranted = false.obs;
  final canClaimWeeklyBonus = false.obs;
  final previousWeekBonusPending = false.obs;
  final weeklyDayStatus = <Map<String, dynamic>>[].obs;

  Timer? _durationTimer;

  bool get isAvailable => _availability.isAvailable;
  HostStatus get hostStatus => _availability.hostStatus.value;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    _socket.on('earning_updated', (_) => _loadEarnings());
    _socket.on('daily_task_completed', (_) {
      unawaited(_loadDailyTask());
      unawaited(_loadEarnings());
    });
    _socket.on('weekly_bonus_granted', (_) {
      unawaited(_loadDailyTask());
      unawaited(_loadEarnings());
      Get.snackbar('Weekly Bonus', 'You completed all 7 days — bonus credited!');
    });
    _startDurationTicker();
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _socket.off('earning_updated');
    _socket.off('daily_task_completed');
    _socket.off('weekly_bonus_granted');
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
        _loadDailyTask(),
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

  Future<void> claimDailyReward() async {
    isClaimingReward.value = true;
    try {
      final response = await _api.post(ApiConstants.hostDailyTaskClaim);
      final data = JsonParse.toMap(response.data['data']);
      if (data != null) _applyDailyTask(data);

      await _loadEarnings();
      Get.snackbar(
        'Reward claimed',
        '₹${dailyRewardAmount.value.toStringAsFixed(0)} added to your earnings',
      );
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isClaimingReward.value = false;
    }
  }

  Future<void> claimWeeklyBonus() async {
    isClaimingWeeklyBonus.value = true;
    try {
      final response = await _api.post(ApiConstants.hostWeeklyBonusClaim);
      final data = JsonParse.toMap(response.data['data']);
      if (data != null) _applyDailyTask(data);

      await _loadEarnings();
      Get.snackbar(
        'Weekly bonus',
        '₹${weeklyBonusAmount.value.toStringAsFixed(0)} added to your earnings',
      );
    } on DioException catch (e) {
      Get.snackbar('Error', _api.extractError(e));
    } finally {
      isClaimingWeeklyBonus.value = false;
    }
  }

  Future<void> _loadDailyTask() async {
    try {
      final response = await _api.get(ApiConstants.hostDailyTask);
      final data = JsonParse.toMap(response.data['data']);
      if (data == null) return;
      _applyDailyTask(data);
    } on DioException catch (e) {
      debugPrint('[Dashboard] daily task load failed: ${_api.extractError(e)}');
    }
  }

  void _applyDailyTask(Map<String, dynamic> data) {
    dailyMinCalls.value = JsonParse.toInt(data['daily_min_calls'], fallback: 6);
    dailyMinMinutes.value = JsonParse.toInt(data['daily_min_minutes'], fallback: 60);
    completedCalls.value = JsonParse.toInt(data['completed_calls']);
    completedMinutes.value = JsonParse.toInt(data['completed_minutes']);
    progressCallsPercent.value = JsonParse.toInt(data['progress_calls_percent']);
    progressMinutesPercent.value = JsonParse.toInt(data['progress_minutes_percent']);
    targetMet.value = data['target_met'] == true;
    earningStatusActive.value = data['earning_status']?.toString() == 'active';
    streakCount.value = JsonParse.toInt(data['streak_count']);
    dailyRewardAmount.value = JsonParse.toDouble(data['reward_amount']);
    rewardClaimed.value = data['reward_claimed'] == true;
    canClaimReward.value = data['can_claim_reward'] == true;
    weeklyBonusAmount.value = JsonParse.toDouble(data['weekly_bonus_amount']);
    weeklyDaysCompleted.value = JsonParse.toInt(data['weekly_days_completed']);
    weeklyDaysRequired.value = JsonParse.toInt(data['weekly_days_required'], fallback: 7);
    weeklyBonusGranted.value = data['weekly_bonus_granted'] == true;
    canClaimWeeklyBonus.value = data['can_claim_weekly_bonus'] == true;
    previousWeekBonusPending.value = data['previous_week_bonus_pending'] == true;
    final days = data['weekly_day_status'];
    if (days is List) {
      weeklyDayStatus.value = days
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
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
}
