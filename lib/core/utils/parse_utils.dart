class JsonParse {
  JsonParse._();

  static double toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static String? toStringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic>? toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  static List<Map<String, dynamic>> toMapList(dynamic data) {
    if (data is! List) return [];
    return data.map((item) {
      if (item is Map<String, dynamic>) return item;
      if (item is Map) return Map<String, dynamic>.from(item);
      return <String, dynamic>{};
    }).toList();
  }

  static DateTime? toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

String truncateWords(String text, int maxWords) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return trimmed;

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length <= maxWords) return trimmed;
  return '${parts.take(maxWords).join(' ')}...';
}
