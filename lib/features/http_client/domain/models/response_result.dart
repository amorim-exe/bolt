// lib/features/http_client/domain/models/response_result.dart
class ResponseResult {
  final int statusCode;
  final String statusMessage;
  final dynamic data;
  final Map<String, List<String>> headers;
  final int responseTimeMs;
  final int responseSizeBytes;

  ResponseResult({
    required this.statusCode,
    required this.statusMessage,
    required this.data,
    required this.headers,
    required this.responseTimeMs,
    required this.responseSizeBytes,
  });
}