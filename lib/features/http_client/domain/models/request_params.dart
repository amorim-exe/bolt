// lib/features/http_client/domain/models/request_params.dart
enum HttpMethod { get, post, put, delete, patch }

class HeaderItem {
  String key;
  String value;
  bool isEnabled;

  HeaderItem({required this.key, required this.value, this.isEnabled = true});
}

class QueryParamItem {
  String key;
  String value;
  bool isEnabled;

  QueryParamItem({required this.key, required this.value, this.isEnabled = true});
}

class RequestParams {
  final String url;
  final HttpMethod method;
  final List<HeaderItem> headers;
  final List<QueryParamItem> queryParams; 
  final String? body;

  RequestParams({
    required this.url,
    required this.method,
    List<HeaderItem>? headers,
    List<QueryParamItem>? queryParams,
    this.body,
  })  : headers = headers ?? [],
        queryParams = queryParams ?? [];

  RequestParams copyWith({
    String? url,
    HttpMethod? method,
    List<HeaderItem>? headers,
    List<QueryParamItem>? queryParams,
    String? body,
  }) {
    return RequestParams(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      body: body ?? this.body,
    );
  }
}