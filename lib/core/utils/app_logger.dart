import 'package:flutter/foundation.dart';

/// Debug logs — filter terminal with: flutter logs | grep LoveCallGirls
class AppLogger {
  AppLogger._();

  static const _tag = 'LoveCallGirls';

  static void info(String message) {
    debugPrint('[$_tag] $message');
  }

  static void api(String method, String path, {int? status, String? detail}) {
    final statusPart = status != null ? ' → $status' : '';
    final detailPart = detail != null ? ' | $detail' : '';
    debugPrint('[$_tag][API] $method $path$statusPart$detailPart');
  }

  static void error(String message, [Object? error]) {
    debugPrint('[$_tag][ERROR] $message${error != null ? ' | $error' : ''}');
  }
}
