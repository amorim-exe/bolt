// lib/features/http_client/domain/models/request_params.dart
enum HttpMethod { get, post, put, patch, delete, head, options, trace, connect }

enum BodyMode { none, json, text, formUrlEncoded, formData, binary }

class FormFieldItem {
  String key;
  String value;
  bool isFile;
  bool isEnabled;

  FormFieldItem({
    required this.key,
    required this.value,
    this.isFile = false,
    this.isEnabled = true,
  });
}

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

  QueryParamItem(
      {required this.key, required this.value, this.isEnabled = true});
}

class RequestParams {
  final String url;
  final HttpMethod method;
  final List<HeaderItem> headers;
  final List<QueryParamItem> queryParams;
  final String? body;
  final BodyMode bodyMode;
  final List<FormFieldItem> formFields;

  RequestParams({
    required this.url,
    required this.method,
    List<HeaderItem>? headers,
    List<QueryParamItem>? queryParams,
    this.body,
    this.bodyMode = BodyMode.json,
    List<FormFieldItem>? formFields,
  })  : headers = headers ?? [],
        queryParams = queryParams ?? [],
        formFields = formFields ?? [];

  RequestParams copyWith({
    String? url,
    HttpMethod? method,
    List<HeaderItem>? headers,
    List<QueryParamItem>? queryParams,
    String? body,
    BodyMode? bodyMode,
    List<FormFieldItem>? formFields,
  }) {
    return RequestParams(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      body: body ?? this.body,
      bodyMode: bodyMode ?? this.bodyMode,
      formFields: formFields ?? this.formFields,
    );
  }
}
