import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';
  static const _profileKey = 'cached_profile';
  static const _profileVersionKey = 'profile_version';
  static const _accessKeyExpiresKey = 'access_key_expires_at';
  static const _callVibrateEnabledKey = 'call_vibrate_enabled';

  static const _secureAccessKey = 'host_access_key';

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  late SharedPreferences _prefs;
  String? _cachedAccessKey;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _cachedAccessKey = await _secureStorage.read(key: _secureAccessKey);
    return this;
  }

  String? get accessToken => _prefs.getString(_accessTokenKey);
  String? get refreshToken => _prefs.getString(_refreshTokenKey);
  String? get accessKey => _cachedAccessKey;

  Map<String, dynamic>? get user => _readJsonMap(_userKey);

  Map<String, dynamic>? get cachedProfile => _readJsonMap(_profileKey);

  Map<String, dynamic>? _readJsonMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : null;
    } catch (_) {
      return null;
    }
  }

  int get profileVersion => _prefs.getInt(_profileVersionKey) ?? 0;

  DateTime? get accessKeyExpiresAt {
    final raw = _prefs.getString(_accessKeyExpiresKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool get isLoggedIn => accessToken != null && accessToken!.isNotEmpty;

  bool get hasValidAccessKey {
    final key = accessKey;
    if (key == null || key.isEmpty) return false;
    final expires = accessKeyExpiresAt;
    if (expires == null) return true;
    return DateTime.now().isBefore(expires);
  }

  bool get callVibrateEnabled =>
      _prefs.getBool(_callVibrateEnabledKey) ?? true;

  Future<void> setCallVibrateEnabled(bool value) async {
    await _prefs.setBool(_callVibrateEnabledKey, value);
  }

  Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
    String? accessKey,
    String? accessKeyExpiresAt,
    int? profileVersion,
    Map<String, dynamic>? profile,
  }) async {
    await _prefs.setString(_accessTokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
    await _prefs.setString(_userKey, jsonEncode(user));

    if (accessKey != null) {
      await _secureStorage.write(key: _secureAccessKey, value: accessKey);
      _cachedAccessKey = accessKey;
    }

    if (accessKeyExpiresAt != null) {
      await _prefs.setString(_accessKeyExpiresKey, accessKeyExpiresAt);
    }

    if (profileVersion != null) {
      await _prefs.setInt(_profileVersionKey, profileVersion);
    }

    if (profile != null) {
      await _prefs.setString(_profileKey, jsonEncode(profile));
    }
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    await _prefs.setString(_userKey, jsonEncode(user));
  }

  Future<void> updateCachedProfile(
    Map<String, dynamic> profile, {
    int? profileVersion,
  }) async {
    await _prefs.setString(_profileKey, jsonEncode(profile));
    if (profileVersion != null) {
      await _prefs.setInt(_profileVersionKey, profileVersion);
    }
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userKey);
    await _prefs.remove(_profileKey);
    await _prefs.remove(_profileVersionKey);
    await _prefs.remove(_accessKeyExpiresKey);
    await _secureStorage.delete(key: _secureAccessKey);
    _cachedAccessKey = null;
  }
}
