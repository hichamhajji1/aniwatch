class NetworkException implements Exception {
  const NetworkException(this.message, {this.statusCode, this.offline = false});

  final String message;
  final int? statusCode;
  final bool offline;

  @override
  String toString() => message;
}
