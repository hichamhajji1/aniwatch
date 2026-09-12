Map<String, dynamic>? asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> asJsonMapList(dynamic value) {
  if (value is! List) return const [];
  return value.map(asJsonMap).whereType<Map<String, dynamic>>().toList();
}
