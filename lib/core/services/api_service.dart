import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../config/app_config.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  late dio.Dio _dio;
  final StorageService _storage = Get.find<StorageService>();
  bool _isRefreshing = false;

  Future<ApiService> init() async {
    _dio = dio.Dio(
      dio.BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          _logRequest(options);
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response);
          handler.next(response);
        },
        onError: (error, handler) async {
          _logError(error);
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${_storage.accessToken}';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    return this;
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = _storage.refreshToken;
    if (refresh == null) return false;

    _isRefreshing = true;
    try {
      debugPrint('[API] → POST ${AppConfig.apiBaseUrl}${ApiConstants.refreshToken}');
      final response = await dio.Dio(
        dio.BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ).post(
        '${AppConfig.apiBaseUrl}${ApiConstants.refreshToken}',
        data: {'refreshToken': refresh},
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      final user = _storage.user ?? {};
      await _storage.saveAuth(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        user: user,
      );
      debugPrint('[API] ← POST ${ApiConstants.refreshToken} ${response.statusCode}');
      return true;
    } catch (e) {
      debugPrint('[API] ✗ POST ${ApiConstants.refreshToken} $e');
      await _storage.clearAuth();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<dio.Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _dio.get(path, queryParameters: query);
  }

  Future<dio.Response<dynamic>> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<dio.Response<dynamic>> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  void _logRequest(dio.RequestOptions options) {
    final query = options.queryParameters.isEmpty ? '' : ' query=${options.queryParameters}';
    final body = options.data == null ? '' : ' body=${options.data}';
    debugPrint('[API] → ${options.method} ${options.uri}$query$body');
  }

  void _logResponse(dio.Response<dynamic> response) {
    debugPrint(
      '[API] ← ${response.requestOptions.method} ${response.requestOptions.uri} ${response.statusCode}',
    );
  }

  void _logError(dio.DioException error) {
    final status = error.response?.statusCode;
    debugPrint(
      '[API] ✗ ${error.requestOptions.method} ${error.requestOptions.uri} ${status ?? '—'} ${error.message}',
    );
  }

  String extractError(dio.DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(', ');
      return message.toString();
    }
    return e.message ?? 'Something went wrong';
  }
}
