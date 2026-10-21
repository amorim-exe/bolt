enum HttpMethod { get, post, put, patch, delete, head, options, trace, connect }

enum BodyMode { none, json, text, formUrlEncoded, formData, binary }

enum AuthType { none, bearer, basic, apiKey }

enum ApiKeyLocation { header, query }

class RequestAuth {
  const RequestAuth({
    this.type = AuthType.none,
    this.token = '',
    this.username = '',
    this.password = '',
    this.apiKeyName = '',
    this.apiKeyValue = '',
    this.apiKeyLocation = ApiKeyLocation.header,
  });

  final AuthType type;
  final String token;
  final String username;
  final String password;
  final String apiKeyName;
  final String apiKeyValue;
  final ApiKeyLocation apiKeyLocation;

  RequestAuth copyWith({
    AuthType? type,
    String? token,
    String? username,
    String? password,
    String? apiKeyName,
    String? apiKeyValue,
    ApiKeyLocation? apiKeyLocation,
  }) {
    return RequestAuth(
      type: type ?? this.type,
      token: token ?? this.token,
      username: username ?? this.username,
      password: password ?? this.password,
      apiKeyName: apiKeyName ?? this.apiKeyName,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
    );
  }
}

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
  bool isAutoDetected;

  QueryParamItem({
    required this.key,
    required this.value,
    this.isEnabled = true,
    this.isAutoDetected = false,
  });
}

class RequestParams {
  final String url;
  final HttpMethod method;
  final List<HeaderItem> headers;
  final List<QueryParamItem> queryParams;
  final String? body;
  final BodyMode bodyMode;
  final List<FormFieldItem> formFields;
  final RequestAuth auth;
  final String testScript;

  RequestParams({
    required this.url,
    required this.method,
    List<HeaderItem>? headers,
    List<QueryParamItem>? queryParams,
    this.body,
    this.bodyMode = BodyMode.json,
    List<FormFieldItem>? formFields,
    this.auth = const RequestAuth(),
    this.testScript = '',
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
    RequestAuth? auth,
    String? testScript,
  }) {
    return RequestParams(
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      body: body ?? this.body,
      bodyMode: bodyMode ?? this.bodyMode,
      formFields: formFields ?? this.formFields,
      auth: auth ?? this.auth,
      testScript: testScript ?? this.testScript,
    );
  }
}
