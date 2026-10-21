// lib/features/http_client/domain/models/response_result.dart
class ResponseResult {
  final int statusCode;
  final String statusMessage;
  final dynamic data;
  final Map<String, List<String>> headers;
  final int responseTimeMs;
  final int responseSizeBytes;
  final List<String> cookies;
  final List<ResponseTestResult> testResults;

  ResponseResult({
    required this.statusCode,
    required this.statusMessage,
    required this.data,
    required this.headers,
    required this.responseTimeMs,
    required this.responseSizeBytes,
    this.cookies = const [],
    this.testResults = const [],
  });

  ResponseResult copyWith({
    int? statusCode,
    String? statusMessage,
    dynamic data,
    Map<String, List<String>>? headers,
    int? responseTimeMs,
    int? responseSizeBytes,
    List<String>? cookies,
    List<ResponseTestResult>? testResults,
  }) {
    return ResponseResult(
      statusCode: statusCode ?? this.statusCode,
      statusMessage: statusMessage ?? this.statusMessage,
      data: data ?? this.data,
      headers: headers ?? this.headers,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      responseSizeBytes: responseSizeBytes ?? this.responseSizeBytes,
      cookies: cookies ?? this.cookies,
      testResults: testResults ?? this.testResults,
    );
  }
}

class ResponseTestResult {
  const ResponseTestResult({
    required this.name,
    required this.passed,
    this.message,
  });

  final String name;
  final bool passed;
  final String? message;
}
