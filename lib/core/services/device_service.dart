import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../constants/api_constants.dart';
import '../messaging/notification_permission_service.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Resolves device identity and keeps the FCM token in sync with the backend.
class DeviceService extends GetxService {
  static const _deviceIdKey = 'device_id';
  static const _fcmTokenKey = 'fcm_token_cached';

  String? _deviceId;
  String? _fcmToken;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _backgroundFcmFetchRunning = false;

  String get deviceId => _deviceId ?? 'unknown';
  String? get fcmToken => _fcmToken;

  Map<String, String> get loginFields {
    final fields = <String, String>{'device_id': deviceId};
    final token = _fcmToken;
    if (token != null && token.isNotEmpty) {
      fields['fcm_token'] = token;
    }
    return fields;
  }

  Future<DeviceService> init() async {
    await _ensureFirebase();
    _deviceId = await _resolveDeviceId();
    _fcmToken = await _loadCachedFcmToken();
    _listenForTokenRefresh();
    unawaited(_fetchFcmTokenInBackground(source: 'startup'));
    _logDetails();
    return this;
  }

  void printDetails() => _logDetails();

  /// Fast path — does not block login on slow Google/FCM.
  Future<void> ensureFcmReady() async {
    if (Firebase.apps.isEmpty) return;

    await NotificationPermissionService.requestIfNeeded();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    _fcmToken ??= await _loadCachedFcmToken();

    final token = await _resolveFcmToken(
      timeout: const Duration(seconds: 3),
      logOnFailure: false,
    );
    if (token != null && token.isNotEmpty) {
      _fcmToken = token;
      await _cacheFcmToken(token);
      _logDetails();
      return;
    }

    unawaited(_fetchFcmTokenInBackground(source: 'ready'));
  }

  Future<void> refreshFcmToken() async {
    if (Firebase.apps.isEmpty) return;
    final token = await _resolveFcmToken();
    if (token != null && token.isNotEmpty) {
      _fcmToken = token;
      await _cacheFcmToken(token);
    }
    _logDetails();
  }

  Future<void> syncWithServer() async {
    if (!Get.isRegistered<StorageService>() || !Get.isRegistered<ApiService>()) {
      return;
    }

    final storage = Get.find<StorageService>();
    if (!storage.isLoggedIn) return;

    await refreshFcmToken();

    try {
      await Get.find<ApiService>().put(ApiConstants.deviceSync, data: loginFields);
      debugPrint('[Device] FCM token synced with server');
    } catch (e) {
      debugPrint('[Device] server sync failed: $e');
    }
  }

  Future<void> _ensureFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('[Device] Firebase init skipped: $e');
    }
  }

  Future<String> _resolveDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_deviceIdKey);
    if (cached != null && cached.isNotEmpty) return cached;

    final plugin = DeviceInfoPlugin();
    String id;

    if (GetPlatform.isAndroid) {
      final info = await plugin.androidInfo;
      id = info.id;
    } else if (GetPlatform.isIOS) {
      final info = await plugin.iosInfo;
      id = info.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      id = 'device_${DateTime.now().millisecondsSinceEpoch}';
    }

    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  Future<String?> _loadCachedFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_fcmTokenKey);
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  }

  Future<void> _cacheFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> _resolveFcmToken({
    Duration timeout = const Duration(seconds: 12),
    bool logOnFailure = true,
  }) async {
    if (Firebase.apps.isEmpty) return null;
    try {
      return await FirebaseMessaging.instance.getToken().timeout(timeout);
    } on TimeoutException {
      if (logOnFailure) {
        debugPrint(
          '[Device] FCM token slow (network/Google). Retrying in background — calls unaffected.',
        );
      }
      return null;
    } catch (e) {
      if (logOnFailure) {
        debugPrint('[Device] FCM token unavailable (calls unaffected): $e');
      }
      return null;
    }
  }

  Future<void> _fetchFcmTokenInBackground({required String source}) async {
    if (_backgroundFcmFetchRunning || Firebase.apps.isEmpty) return;
    _backgroundFcmFetchRunning = true;
    try {
      for (var attempt = 1; attempt <= 5; attempt++) {
        final token = await _resolveFcmToken(
          timeout: Duration(seconds: 8 + attempt * 2),
          logOnFailure: attempt == 5,
        );
        if (token != null && token.isNotEmpty) {
          _fcmToken = token;
          await _cacheFcmToken(token);
          debugPrint('[Device] fcm_token ($source): obtained');
          if (Get.isRegistered<StorageService>() &&
              Get.find<StorageService>().isLoggedIn) {
            unawaited(syncWithServer());
          }
          return;
        }
        await Future<void>.delayed(Duration(seconds: attempt * 3));
      }
    } finally {
      _backgroundFcmFetchRunning = false;
    }
  }

  void _listenForTokenRefresh() {
    if (Firebase.apps.isEmpty) return;
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      await _cacheFcmToken(token);
      debugPrint('[Device] fcm_token refreshed');
      await syncWithServer();
    });
  }

  void _logDetails() {
    debugPrint('[Device] device_id: $deviceId');
    debugPrint('[Device] fcm_token: ${fcmToken ?? 'none (voice calls still work via socket)'}');
  }

  @override
  void onClose() {
    _tokenRefreshSub?.cancel();
    super.onClose();
  }
}
