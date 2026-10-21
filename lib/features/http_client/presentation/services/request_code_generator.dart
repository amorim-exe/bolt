import 'dart:convert';

import '../../domain/models/request_params.dart';

enum RequestCodeFormat { curl, javascript, python, dart }

class RequestCodeGenerator {
  static String generate(RequestParams params, RequestCodeFormat format) {
    final parsedUrl = Uri.tryParse(params.url);
    if (parsedUrl != null && parsedUrl.hasQuery) {
      final fragmentIndex = params.url.indexOf('#');
      final fragment =
          fragmentIndex < 0 ? '' : params.url.substring(fragmentIndex);
      final beforeFragment = fragmentIndex < 0
          ? params.url
          : params.url.substring(0, fragmentIndex);
      final queryIndex = beforeFragment.indexOf('?');
      if (queryIndex >= 0) {
        params = params.copyWith(
          url: '${beforeFragment.substring(0, queryIndex)}$fragment',
        );
      }
    }
    final headers = {
      for (final header in params.headers)
        if (header.isEnabled && header.key.trim().isNotEmpty)
          if (params.bodyMode != BodyMode.formData ||
              header.key.toLowerCase() != 'content-type')
            header.key.trim(): header.value,
    };
    final query = <String, dynamic>{};
    for (final item in params.queryParams) {
      if (!item.isEnabled || item.key.trim().isEmpty) continue;
      final key = item.key.trim();
      final previous = query[key];
      if (previous == null) {
        query[key] = item.value;
      } else if (previous is List<String>) {
        previous.add(item.value);
      } else {
        query[key] = [previous.toString(), item.value];
      }
    }
    switch (params.auth.type) {
      case AuthType.none:
        break;
      case AuthType.bearer:
        headers.removeWhere(
          (key, _) => key.toLowerCase() == 'authorization',
        );
        headers['Authorization'] = 'Bearer ${params.auth.token}';
      case AuthType.basic:
        headers.removeWhere(
          (key, _) => key.toLowerCase() == 'authorization',
        );
        headers['Authorization'] =
            'Basic ${base64Encode(utf8.encode('${params.auth.username}:${params.auth.password}'))}';
      case AuthType.apiKey:
        if (params.auth.apiKeyName.isNotEmpty) {
          if (params.auth.apiKeyLocation == ApiKeyLocation.header) {
            headers.removeWhere(
              (key, _) =>
                  key.toLowerCase() == params.auth.apiKeyName.toLowerCase(),
            );
            headers[params.auth.apiKeyName] = params.auth.apiKeyValue;
          } else {
            query.remove(params.auth.apiKeyName);
            query[params.auth.apiKeyName] = params.auth.apiKeyValue;
          }
        }
    }
    final fields = [
      for (final field in params.formFields)
        if (field.isEnabled && field.key.trim().isNotEmpty) field,
    ];

    return switch (format) {
      RequestCodeFormat.curl => _curl(params, headers, query, fields),
      RequestCodeFormat.javascript =>
        _javascript(params, headers, query, fields),
      RequestCodeFormat.python => _python(params, headers, query, fields),
      RequestCodeFormat.dart => _dart(params, headers, query, fields),
    };
  }

  static String _curl(
    RequestParams params,
    Map<String, String> headers,
    Map<String, dynamic> query,
    List<FormFieldItem> fields,
  ) {
    final lines = [
      'curl -X ${params.method.name.toUpperCase()} ${_shellQuote(params.url)}',
      for (final entry in _queryEntries(query))
        '  --url-query ${_shellQuote('${entry.key}=${entry.value}')}',
      for (final entry in headers.entries)
        "  -H ${_shellQuote('${entry.key}: ${entry.value}')}",
      ..._curlBody(params, fields),
    ];
    return lines.join(' \\\n');
  }

  static List<String> _curlBody(
      RequestParams params, List<FormFieldItem> fields) {
    switch (params.bodyMode) {
      case BodyMode.none:
      case BodyMode.binary:
        return params.bodyMode == BodyMode.binary && params.body != null
            ? ["  --data-binary ${_shellQuote('@${params.body!}')}"]
            : [];
      case BodyMode.formData:
        return [
          for (final field in fields)
            "  -F ${_shellQuote('${field.key}=${field.isFile ? '@${field.value}' : field.value}')}",
        ];
      case BodyMode.formUrlEncoded:
        return [
          for (final field in fields)
            "  --data-urlencode ${_shellQuote('${field.key}=${field.value}')}",
        ];
      case BodyMode.json:
      case BodyMode.text:
        return params.body?.isNotEmpty == true
            ? ['  --data-raw ${_shellQuote(params.body!)}']
            : [];
    }
  }

  static String _javascript(
    RequestParams params,
    Map<String, String> headers,
    Map<String, dynamic> query,
    List<FormFieldItem> fields,
  ) {
    final body = switch (params.bodyMode) {
      BodyMode.none => null,
      BodyMode.json => _parseJson(params.body),
      BodyMode.text => params.body,
      BodyMode.formUrlEncoded => {
          for (final field in fields) field.key: field.value,
        },
      BodyMode.formData => null,
      BodyMode.binary => null,
    };
    final formData = params.bodyMode == BodyMode.formData
        ? [
            'const formData = new FormData();',
            for (final field in fields)
              "formData.append(${_jsString(field.key)}, ${field.isFile ? "document.querySelector('input[type=file]')?.files?.[0]" : _jsString(field.value)});",
          ]
        : <String>[];
    final binaryBody = params.bodyMode == BodyMode.binary
        ? [
            "const binaryBody = document.querySelector('input[type=\"file\"]')?.files?.[0];",
          ]
        : <String>[];
    final requestBody = params.bodyMode == BodyMode.formData
        ? 'formData'
        : params.bodyMode == BodyMode.formUrlEncoded
            ? 'new URLSearchParams(${_jsMap(body as Map<String, String>)})'
            : params.bodyMode == BodyMode.json
                ? body == null
                    ? 'undefined'
                    : 'JSON.stringify(${_jsLiteral(body)})'
                : body == null
                    ? 'undefined'
                    : jsonEncode(body);

    return [
      if (query.isNotEmpty) 'const url = new URL(${_jsString(params.url)});',
      if (query.isNotEmpty)
        for (final entry in _queryEntries(query))
          'url.searchParams.append(${_jsString(entry.key)}, ${_jsString(entry.value)});',
      ...formData,
      ...binaryBody,
      'const response = await fetch(${query.isEmpty ? _jsString(params.url) : 'url'}, {',
      "  method: '${params.method.name.toUpperCase()}',",
      '  headers: ${_jsMap(headers)},',
      if (params.bodyMode != BodyMode.none &&
          params.bodyMode != BodyMode.binary)
        '  body: $requestBody,',
      if (params.bodyMode == BodyMode.binary) '  body: binaryBody,',
      '});',
      'const data = await response.json();',
    ].join('\n');
  }

  static String _python(
    RequestParams params,
    Map<String, String> headers,
    Map<String, dynamic> query,
    List<FormFieldItem> fields,
  ) {
    final body = switch (params.bodyMode) {
      BodyMode.none || BodyMode.binary => null,
      BodyMode.json => _parseJson(params.body),
      BodyMode.formUrlEncoded || BodyMode.formData => {
          for (final field in fields) field.key: field.value,
        },
      BodyMode.text => params.body,
    };
    return [
      'import requests',
      '',
      'url = ${_pyString(params.url)}',
      'headers = ${_pyLiteral(headers)}',
      'params = ${_pyLiteral(query)}',
      if (params.bodyMode == BodyMode.formData &&
          fields.any((field) => field.isFile))
        'files = {${fields.where((field) => field.isFile).map((field) => '${_pyString(field.key)}: open(${_pyString(field.value)}, "rb")').join(', ')}}',
      if (body != null && params.bodyMode == BodyMode.json)
        'json = ${_pyLiteral(body)}',
      if (body != null &&
          params.bodyMode != BodyMode.json &&
          params.bodyMode != BodyMode.formData)
        'data = ${_pyLiteral(body)}',
      'response = requests.request(',
      '    ${_pyString(params.method.name.toUpperCase())},',
      '    url,',
      '    headers=headers,',
      '    params=params,',
      if (params.bodyMode == BodyMode.json) '    json=json,',
      if (params.bodyMode == BodyMode.formData &&
          fields.any((field) => field.isFile))
        '    files=files,',
      if (body != null &&
          params.bodyMode != BodyMode.json &&
          params.bodyMode != BodyMode.formData)
        '    data=data,',
      if (params.bodyMode == BodyMode.formData &&
          fields.any((field) => !field.isFile))
        '    data=${_pyLiteral({
              for (final field in fields)
                if (!field.isFile) field.key: field.value
            })},',
      if (params.bodyMode == BodyMode.binary && params.body != null)
        '    data=open(${_pyString(params.body!)}, "rb"),',
      '    timeout=30,',
      ')',
      'print(response.status_code)',
      'print(response.text)',
    ].join('\n');
  }

  static String _dart(
    RequestParams params,
    Map<String, String> headers,
    Map<String, dynamic> query,
    List<FormFieldItem> fields,
  ) {
    final body = switch (params.bodyMode) {
      BodyMode.none || BodyMode.binary || BodyMode.formData => null,
      BodyMode.json => _parseJson(params.body),
      BodyMode.text => params.body,
      BodyMode.formUrlEncoded => {
          for (final field in fields) field.key: field.value,
        },
    };
    return [
      if (params.bodyMode == BodyMode.binary) "import 'dart:io';",
      "import 'package:dio/dio.dart';",
      '',
      'final dio = Dio();',
      'final response = await dio.request(',
      '  ${_dartString(params.url)},',
      "  options: Options(method: '${params.method.name.toUpperCase()}'),",
      '  queryParameters: ${_dartLiteral(query)},',
      '  headers: ${_dartLiteral(headers)},',
      if (body != null) '  data: ${_dartLiteral(body)},',
      if (params.bodyMode == BodyMode.formData)
        '  data: FormData.fromMap({${fields.map((field) => field.isFile ? '${_dartString(field.key)}: await MultipartFile.fromFile(${_dartString(field.value)})' : '${_dartString(field.key)}: ${_dartString(field.value)}').join(', ')}}),',
      if (params.bodyMode == BodyMode.binary)
        "  data: await File(${_dartString(params.body ?? '')}).readAsBytes(),",
      ');',
      'print(response.statusCode);',
      'print(response.data);',
    ].join('\n');
  }

  static dynamic _parseJson(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      return jsonDecode(source);
    } on FormatException {
      return source;
    }
  }

  static String _shellQuote(String value) =>
      "'${value.replaceAll("'", "'\\''")}'";

  static String _jsString(String value) => jsonEncode(value);

  static String _jsMap(Map<String, String> values) => '{\n'
      '${values.entries.map((entry) => '    ${_jsString(entry.key)}: ${_jsString(entry.value)}').join(',\n')}\n  }';

  static Iterable<MapEntry<String, String>> _queryEntries(
    Map<String, dynamic> query,
  ) sync* {
    for (final entry in query.entries) {
      final values = entry.value;
      if (values is List) {
        for (final value in values) {
          yield MapEntry(entry.key, value.toString());
        }
      } else {
        yield MapEntry(entry.key, values.toString());
      }
    }
  }

  static String _jsLiteral(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return _jsString(value);
    if (value is bool || value is num) return value.toString();
    if (value is List) return '[${value.map(_jsLiteral).join(', ')}]';
    if (value is Map) {
      return '{${value.entries.map((entry) => '${_jsString(entry.key.toString())}: ${_jsLiteral(entry.value)}').join(', ')}}';
    }
    return _jsString(value.toString());
  }

  static String _pyString(String value) => jsonEncode(value);

  static String _pyLiteral(dynamic value) {
    if (value == null) return 'None';
    if (value is bool) return value ? 'True' : 'False';
    if (value is String) return _pyString(value);
    if (value is List) {
      return '[${value.map(_pyLiteral).join(', ')}]';
    }
    if (value is Map) {
      return '{${value.entries.map((entry) => '${_pyLiteral(entry.key)}: ${_pyLiteral(entry.value)}').join(', ')}}';
    }
    return value.toString();
  }

  static String _dartString(String value) =>
      "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";

  static String _dartLiteral(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return _dartString(value);
    if (value is bool || value is num) return value.toString();
    if (value is List) {
      return '[${value.map(_dartLiteral).join(', ')}]';
    }
    if (value is Map) {
      return '{${value.entries.map((entry) => '${_dartLiteral(entry.key)}: ${_dartLiteral(entry.value)}').join(', ')}}';
    }
    return _dartString(value.toString());
  }
}
