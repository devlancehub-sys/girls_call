import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';
import 'device_service.dart';
import 'host_availability_service.dart';
import 'presence_service.dart';
import 'storage_service.dart';

/// Restores sessions using stored JWT + optional access key; never blocks splash on network.
class AuthSessionService extends GetxService {
  ApiService get _api => Get.find<ApiService>();
  StorageService get _storage => Get.find<StorageService>();
  PresenceService get _presence => Get.find<PresenceService>();
  DeviceService get _device => Get.find<DeviceService>();

  Future<void> bootstrapFromSplash() async {
    try {
      if (!_storage.isLoggedIn) {
        _goLogin();
        return;
      }

      // Fast path: cached session — navigate immediately, sync in background.
      if (_storage.cachedProfile != null) {
        _goMain();
        unawaited(_syncAfterResume());
        return;
      }

      // Legacy / first launch after update: token exists but no cached profile.
      final ok = await _validateStoredSession().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );

      if (ok) {
        _goMain();
        unawaited(_syncAfterResume());
      } else {
        await _storage.clearAuth();
        _goLogin();
      }
    } catch (e, st) {
      debugPrint('[AuthSession] bootstrap failed: $e\n$st');
      await _storage.clearAuth();
      _goLogin();
    }
  }

  Future<void> _syncAfterResume() async {
    try {
      if (Get.isRegistered<HostAvailabilityService>()) {
        final availability = Get.find<HostAvailabilityService>();
        await availability.refresh().timeout(const Duration(seconds: 6));
        if (availability.isAvailable) {
          await _presence.goAvailable().timeout(const Duration(seconds: 6));
        }
      } else {
        await _presence.goOnline().timeout(const Duration(seconds: 6));
      }
    } catch (e) {
      debugPrint('[AuthSession] goOnline skipped: $e');
    }
    unawaited(_device.syncWithServer());

    if (_storage.hasValidAccessKey) {
      unawaited(_backgroundVerify());
    }
  }

  Future<void> _backgroundVerify() async {
    try {
      final ok = await _validateStoredSession().timeout(
        const Duration(seconds: 8),
        onTimeout: () => true,
      );
      if (!ok && Get.currentRoute != AppRoutes.login) {
        if (Get.isRegistered<HostAvailabilityService>()) {
          await Get.find<HostAvailabilityService>().goOffline();
        } else {
          await _presence.goOffline();
        }
        await _storage.clearAuth();
        Get.offAllNamed(AppRoutes.login);
        Get.snackbar('Session expired', 'Please log in again');
      }
    } catch (e) {
      debugPrint('[AuthSession] background verify skipped: $e');
    }
  }

  void _goLogin() {
    if (Get.currentRoute == AppRoutes.login) return;
    Get.offAllNamed(AppRoutes.login);
  }

  void _goMain() {
    if (Get.currentRoute == AppRoutes.mainShell) return;
    Get.offAllNamed(AppRoutes.mainShell);
  }

  /// Validate session via access key or profile API (legacy fallback).
  Future<bool> _validateStoredSession() async {
    if (!_storage.isLoggedIn) return false;

    final accessKey = _storage.accessKey;
    if (accessKey != null && accessKey.isNotEmpty && _storage.hasValidAccessKey) {
      try {
        final response = await _api.post(
          ApiConstants.verifyAccessKey,
          data: {
            'access_key': accessKey,
            'profile_version': _storage.profileVersion,
          },
        );
        final data = response.data['data'];
        if (data is Map<String, dynamic>) {
          await _persistSession(data, refreshProfile: true);
          return true;
        }
      } on DioException catch (e) {
        if (_isAccessKeyFailure(e)) return false;
        debugPrint('[AuthSession] access key verify failed, trying profile: $e');
      } catch (e) {
        debugPrint('[AuthSession] access key verify error: $e');
      }
    }

    return _validateViaProfile();
  }

  Future<bool> _validateViaProfile() async {
    try {
      final response = await _api.get(ApiConstants.profile);
      final data = response.data['data'];
      if (data is! Map<String, dynamic>) return false;

      await _storage.updateCachedProfile(data);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return false;
      // Offline or server error — allow cached session if we have profile.
      return _storage.cachedProfile != null;
    }
  }

  Future<void> persistLoginResponse(Map<String, dynamic> data) async {
    await _persistSession(data, refreshProfile: true);
  }

  Future<void> _persistSession(
    Map<String, dynamic> data, {
    required bool refreshProfile,
  }) async {
    final userRaw = data['user'];
    if (userRaw is! Map) {
      throw StateError('Login response missing user');
    }
    final user = Map<String, dynamic>.from(userRaw);

    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    if (accessToken == null || refreshToken == null) {
      throw StateError('Login response missing tokens');
    }

    final profile = data['profile'] is Map
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : _storage.cachedProfile;

    await _storage.saveAuth(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      accessKey: data['accessKey']?.toString(),
      accessKeyExpiresAt: data['accessKeyExpiresAt']?.toString(),
      profileVersion: data['profileVersion'] is int
          ? data['profileVersion'] as int
          : int.tryParse('${data['profileVersion']}'),
      profile: refreshProfile ? profile : _storage.cachedProfile,
    );

    if (refreshProfile && profile != null) {
      await _storage.updateCachedProfile(
        profile,
        profileVersion: data['profileVersion'] is int
            ? data['profileVersion'] as int
            : int.tryParse('${data['profileVersion']}'),
      );
    }
  }

  bool _isAccessKeyFailure(DioException e) {
    final status = e.response?.statusCode;
    return status == 401 || status == 403 || status == 404;
  }
}
