import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../models/request_entity.dart';
import '../models/workspace_entity.dart';
import '../../domain/workspace_service.dart';
import '../../../http_client/domain/models/request_params.dart';
import '../../../http_client/domain/models/request_params_codec.dart';

class CollectionTransferService {
  static const postmanSchema =
      'https://schema.getpostman.com/json/collection/v2.1.0/collection.json';

  static Future<int> importCollection({
    required String source,
    required int workspaceId,
    required String content,
  }) async {
    final requests = parseRequests(source: source, content: content);
    if (requests.isEmpty) {
      throw const FormatException(
          'O ficheiro não contém requisições suportadas.');
    }

    for (final request in requests) {
      await WorkspaceService.createRequest(
        name: request.name,
        url: request.url,
        method: request.method,
        headersJson: jsonEncode(request.headers),
        queryParamsJson: jsonEncode(request.queryParams),
        body: RequestParamsCodec.encodeBody(
          RequestParams(
            url: request.url,
            method: _method(request.method),
            headers: [
              for (final item in request.headers)
                HeaderItem(
                  key: item['key'] ?? '',
                  value: item['value'] ?? '',
                  isEnabled: item['isEnabled'] ?? true,
                ),
            ],
            queryParams: [
              for (final item in request.queryParams)
                QueryParamItem(
                  key: item['key'] ?? '',
                  value: item['value'] ?? '',
                  isEnabled: item['isEnabled'] ?? true,
                ),
            ],
            body: request.body,
            bodyMode: request.bodyMode,
            formFields: request.formFields,
            auth: request.auth,
          ),
        ),
        workspaceId: workspaceId,
      );
    }
    return requests.length;
  }

  static List<ImportedCollectionRequest> parseRequests({
    required String source,
    required String content,
  }) {
    return source.toLowerCase().endsWith('.bru')
        ? _parseBrunoRequest(content, source)
        : _parseJsonCollection(_decodeJsonOrYaml(content));
  }

  static dynamic _decodeJsonOrYaml(String content) {
    try {
      return jsonDecode(content);
    } on FormatException {
      return _normalizeYaml(loadYaml(content));
    }
  }

  static dynamic _normalizeYaml(dynamic value) {
    if (value is YamlMap) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _normalizeYaml(entry.value),
      };
    }
    if (value is YamlList) {
      return value.map(_normalizeYaml).toList();
    }
    if (value is DateTime) return value.toIso8601String();
    return value;
  }

  static Future<String> exportPostmanCollection(
    WorkspaceEntity workspace,
  ) async {
    final requests =
        await WorkspaceService.getRequestsByWorkspace(workspace.id);
    return const JsonEncoder.withIndent('  ').convert({
      'info': {
        'name': workspace.name,
        'schema': postmanSchema,
      },
      'item': [
        for (final request in requests) _exportRequest(request),
      ],
    });
  }

  static List<ImportedCollectionRequest> _parseJsonCollection(
    dynamic document,
  ) {
    if (document is! Map<String, dynamic>) {
      throw const FormatException('O JSON deve conter um objeto de coleção.');
    }
    final info = document['info'];
    final schema = info is Map ? info['schema']?.toString() ?? '' : '';
    if (schema.contains('collection/v2.1')) {
      return _parsePostmanItems(
        document['item'],
        inheritedAuth: _postmanAuth(document['auth']),
      );
    }
    if (document['openapi'] != null || document['swagger'] != null) {
      return _parseOpenApi(document);
    }
    throw const FormatException(
      'Formato não reconhecido. Esperado Postman v2.1 ou OpenAPI.',
    );
  }

  static List<ImportedCollectionRequest> _parsePostmanItems(
    dynamic items, {
    RequestAuth inheritedAuth = const RequestAuth(),
  }) {
    if (items is! List) return [];
    final requests = <ImportedCollectionRequest>[];
    for (final item in items.whereType<Map>()) {
      if (item['item'] is List) {
        final folderAuth = _postmanAuth(item['auth']);
        requests.addAll(
          _parsePostmanItems(
            item['item'],
            inheritedAuth:
                folderAuth.type == AuthType.none ? inheritedAuth : folderAuth,
          ),
        );
        continue;
      }
      final request = item['request'];
      if (request is! Map) continue;
      final urlValue = request['url'];
      final rawUrl = urlValue is Map
          ? urlValue['raw']?.toString() ?? ''
          : urlValue?.toString() ?? '';
      if (rawUrl.isEmpty) continue;
      final explicitQuery = urlValue is Map && urlValue['query'] is List
          ? _postmanPairs(urlValue['query'])
          : <Map<String, dynamic>>[];
      final query = explicitQuery.isNotEmpty
          ? explicitQuery
          : _queryParamsFromUrl(rawUrl);
      final url = _removeQueryFromUrl(rawUrl);
      final headers = _postmanPairs(request['header']);
      final body = request['body'];
      final decodedBody = _postmanBody(body);
      final requestAuth = _postmanAuth(request['auth']);
      final auth =
          requestAuth.type == AuthType.none ? inheritedAuth : requestAuth;
      requests.add(
        ImportedCollectionRequest(
          name: item['name']?.toString() ?? url,
          url: url,
          method: request['method']?.toString() ?? 'GET',
          headers: headers,
          queryParams: query,
          body: decodedBody.$1,
          bodyMode: decodedBody.$2,
          formFields: decodedBody.$3,
          auth: auth,
        ),
      );
    }
    return requests;
  }

  static List<ImportedCollectionRequest> _parseOpenApi(
    Map<String, dynamic> document,
  ) {
    final paths = document['paths'];
    if (paths is! Map) return [];
    final servers = document['servers'];
    final baseUrl = servers is List && servers.isNotEmpty
        ? (servers.first is Map ? servers.first['url']?.toString() ?? '' : '')
        : document['swagger'] != null
            ? _swaggerBaseUrl(document)
            : '';
    final requests = <ImportedCollectionRequest>[];
    const supportedMethods = {
      'get',
      'post',
      'put',
      'patch',
      'delete',
      'head',
      'options',
      'trace',
    };
    for (final pathEntry in paths.entries) {
      if (pathEntry.value is! Map) continue;
      final path = pathEntry.key.toString();
      final pathItem = pathEntry.value as Map;
      for (final operation in pathItem.entries) {
        final method = operation.key.toString().toLowerCase();
        if (!supportedMethods.contains(method) || operation.value is! Map) {
          continue;
        }
        final details = operation.value as Map;
        final headers = <Map<String, dynamic>>[];
        final query = <Map<String, dynamic>>[];
        final operationParameters = [
          if (pathItem['parameters'] is List)
            ...(pathItem['parameters'] as List),
          if (details['parameters'] is List) ...(details['parameters'] as List),
        ];
        for (final parameter in operationParameters.whereType<Map>()) {
          final location = parameter['in']?.toString();
          final name = parameter['name']?.toString() ?? '';
          if (name.isEmpty) continue;
          final target = location == 'query'
              ? query
              : location == 'header'
                  ? headers
                  : null;
          target?.add({
            'key': name,
            'value': parameter['example']?.toString() ??
                (parameter['schema'] is Map
                    ? (parameter['schema'] as Map)['default']?.toString() ?? ''
                    : ''),
            'isEnabled': true,
          });
        }
        var body = '';
        var bodyMode = BodyMode.none;
        final requestBody = details['requestBody'];
        final content = requestBody is Map ? requestBody['content'] : null;
        if (content is Map && content.isNotEmpty) {
          final jsonContent =
              content['application/json'] ?? content.values.first;
          final example = jsonContent is Map
              ? jsonContent['example'] ??
                  (jsonContent['schema'] is Map
                      ? (jsonContent['schema'] as Map)['example']
                      : null)
              : null;
          body = example is String ? example : jsonEncode(example ?? {});
          bodyMode = BodyMode.json;
        }
        requests.add(
          ImportedCollectionRequest(
            name: details['summary']?.toString() ??
                details['operationId']?.toString() ??
                '${method.toUpperCase()} $path',
            url: '$baseUrl$path',
            method: method,
            headers: headers,
            queryParams: query,
            body: body,
            bodyMode: bodyMode,
            auth: _openApiAuth(document, details),
          ),
        );
      }
    }
    return requests;
  }

  static List<ImportedCollectionRequest> _parseBrunoRequest(
    String content,
    String source,
  ) {
    final requestLine = RegExp(
      r'^\s*(get|post|put|patch|delete|head|options|trace)\s+(.+?)\s*$',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(content);
    if (requestLine == null) {
      throw const FormatException(
          'Ficheiro Bruno não contém uma linha HTTP válida.');
    }
    final name = RegExp(r'^\s*name:\s*(.+)$', multiLine: true)
            .firstMatch(content)
            ?.group(1)
            ?.trim() ??
        source.split(Platform.pathSeparator).last.replaceFirst('.bru', '');
    final headers = _parseBrunoBlock(content, 'headers');
    final query = _parseBrunoBlock(content, 'params');
    final auth = _parseBrunoAuth(content);
    var body = '';
    var mode = BodyMode.none;
    var formFields = <FormFieldItem>[];
    final jsonBody = RegExp(
      r'body:json\s*\{([\s\S]*?)^\s*\}',
      multiLine: true,
    ).firstMatch(content);
    final textBody = RegExp(
      r'body:text\s*\{([\s\S]*?)^\s*\}',
      multiLine: true,
    ).firstMatch(content);
    if (jsonBody != null) {
      body = jsonBody.group(1)!.trim();
      mode = BodyMode.json;
    } else if (textBody != null) {
      body = textBody.group(1)!.trim();
      mode = BodyMode.text;
    } else {
      formFields = _parseBrunoBlock(content, 'body:form-urlencoded')
          .map(
            (field) => FormFieldItem(
              key: field['key'] ?? '',
              value: field['value'] ?? '',
            ),
          )
          .toList();
      if (formFields.isNotEmpty) mode = BodyMode.formUrlEncoded;
    }
    return [
      ImportedCollectionRequest(
        name: name,
        url: requestLine.group(2)!.trim(),
        method: requestLine.group(1)!.toUpperCase(),
        headers: headers,
        queryParams: query,
        body: body,
        bodyMode: mode,
        formFields: formFields,
        auth: auth,
      ),
    ];
  }

  static RequestAuth _parseBrunoAuth(String content) {
    final block = RegExp(
      r'auth:\s*(bearer|basic|apikey)\s*\{([\s\S]*?)^\s*\}',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(content);
    if (block == null) return const RequestAuth();
    final values = <String, String>{};
    for (final line in block.group(2)!.split('\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      values[line.substring(0, separator).trim().toLowerCase()] =
          line.substring(separator + 1).trim();
    }
    return switch (block.group(1)!.toLowerCase()) {
      'bearer' => RequestAuth(
          type: AuthType.bearer,
          token: values['token'] ?? '',
        ),
      'basic' => RequestAuth(
          type: AuthType.basic,
          username: values['username'] ?? '',
          password: values['password'] ?? '',
        ),
      'apikey' => RequestAuth(
          type: AuthType.apiKey,
          apiKeyName: values['key'] ?? '',
          apiKeyValue: values['value'] ?? '',
          apiKeyLocation:
              values['placement'] == 'query' || values['in'] == 'query'
                  ? ApiKeyLocation.query
                  : ApiKeyLocation.header,
        ),
      _ => const RequestAuth(),
    };
  }

  static List<Map<String, dynamic>> _parseBrunoBlock(
    String content,
    String blockName,
  ) {
    final blockPattern = blockName == 'params'
        ? r'params(?::query)?\s*\{([\s\S]*?)^\s*\}'
        : '${RegExp.escape(blockName)}\\s*\\{([\\s\\S]*?)^\\s*\\}';
    final match = RegExp(
      blockPattern,
      multiLine: true,
    ).firstMatch(content);
    if (match == null) return [];
    final result = <Map<String, dynamic>>[];
    for (final line in match.group(1)!.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final separator = trimmed.indexOf(':');
      if (separator <= 0) continue;
      result.add({
        'key': trimmed.substring(0, separator).trim(),
        'value': trimmed.substring(separator + 1).trim(),
        'isEnabled': true,
      });
    }
    return result;
  }

  static List<Map<String, dynamic>> _postmanPairs(dynamic values) {
    if (values is! List) return [];
    return [
      for (final item in values.whereType<Map>())
        {
          'key': item['key']?.toString() ?? '',
          'value': item['value']?.toString() ?? '',
          'isEnabled': item['disabled'] != true,
        },
    ];
  }

  static List<Map<String, dynamic>> _queryParamsFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return [];
    return [
      for (final entry in uri.queryParametersAll.entries)
        for (final value in entry.value)
          {
            'key': entry.key,
            'value': value,
            'isEnabled': true,
          },
    ];
  }

  static String _removeQueryFromUrl(String url) {
    final fragmentIndex = url.indexOf('#');
    final fragment = fragmentIndex < 0 ? '' : url.substring(fragmentIndex);
    final beforeFragment =
        fragmentIndex < 0 ? url : url.substring(0, fragmentIndex);
    final queryIndex = beforeFragment.indexOf('?');
    return '${queryIndex < 0 ? beforeFragment : beforeFragment.substring(0, queryIndex)}$fragment';
  }

  static RequestAuth _openApiAuth(
    Map<String, dynamic> document,
    Map operation,
  ) {
    final security = operation['security'] ?? document['security'];
    if (security is! List) return const RequestAuth();
    final schemes = (document['components'] is Map
            ? (document['components'] as Map)['securitySchemes']
            : null) ??
        document['securityDefinitions'];
    if (schemes is! Map) return const RequestAuth();
    for (final requirement in security.whereType<Map>()) {
      for (final name in requirement.keys) {
        final scheme = schemes[name];
        if (scheme is! Map) continue;
        if (scheme['type'] == 'apiKey') {
          return RequestAuth(
            type: AuthType.apiKey,
            apiKeyName: scheme['name']?.toString() ?? '',
            apiKeyLocation: scheme['in'] == 'query'
                ? ApiKeyLocation.query
                : ApiKeyLocation.header,
          );
        }
        if (scheme['type'] == 'http' && scheme['scheme'] == 'bearer') {
          return const RequestAuth(type: AuthType.bearer);
        }
        if (scheme['type'] == 'http' && scheme['scheme'] == 'basic') {
          return const RequestAuth(type: AuthType.basic);
        }
        if (scheme['type'] == 'basic') {
          return const RequestAuth(type: AuthType.basic);
        }
      }
    }
    return const RequestAuth();
  }

  static String _swaggerBaseUrl(Map<String, dynamic> document) {
    final host = document['host']?.toString() ?? '';
    if (host.isEmpty) return document['basePath']?.toString() ?? '';
    final schemes = document['schemes'];
    final scheme = schemes is List && schemes.isNotEmpty
        ? schemes.first.toString()
        : 'https';
    final basePath = document['basePath']?.toString() ?? '';
    return '$scheme://$host$basePath';
  }

  static (String?, BodyMode, List<FormFieldItem>) _postmanBody(dynamic body) {
    if (body is! Map) return (null, BodyMode.none, []);
    final mode = body['mode']?.toString();
    switch (mode) {
      case 'raw':
        final raw = body['raw']?.toString() ?? '';
        final language = body['options'] is Map
            ? (body['options'] as Map)['raw'] is Map
                ? ((body['options'] as Map)['raw'] as Map)['language']
                    ?.toString()
                : null
            : null;
        return (
          raw,
          language == 'json' ? BodyMode.json : BodyMode.text,
          <FormFieldItem>[],
        );
      case 'urlencoded':
        return (
          null,
          BodyMode.formUrlEncoded,
          _postmanFormFields(body['urlencoded']),
        );
      case 'formdata':
        return (
          null,
          BodyMode.formData,
          _postmanFormFields(body['formdata']),
        );
      case 'file':
        final file = body['file'];
        return (
          file is Map ? file['src']?.toString() : null,
          BodyMode.binary,
          <FormFieldItem>[],
        );
      default:
        return (null, BodyMode.none, []);
    }
  }

  static List<FormFieldItem> _postmanFormFields(dynamic values) {
    if (values is! List) return [];
    return [
      for (final item in values.whereType<Map>())
        FormFieldItem(
          key: item['key']?.toString() ?? '',
          value: item['src']?.toString() ?? item['value']?.toString() ?? '',
          isFile: item['type'] == 'file',
          isEnabled: item['disabled'] != true,
        ),
    ];
  }

  static RequestAuth _postmanAuth(dynamic auth) {
    if (auth is! Map) return const RequestAuth();
    final type = auth['type']?.toString();
    final values = auth[type] is List
        ? {
            for (final entry in (auth[type] as List).whereType<Map>())
              entry['key']?.toString(): entry['value']?.toString() ?? '',
          }
        : <String?, String>{};
    switch (type) {
      case 'bearer':
        return RequestAuth(
          type: AuthType.bearer,
          token: values['token'] ?? '',
        );
      case 'basic':
        return RequestAuth(
          type: AuthType.basic,
          username: values['username'] ?? '',
          password: values['password'] ?? '',
        );
      case 'apikey':
        return RequestAuth(
          type: AuthType.apiKey,
          apiKeyName: values['key'] ?? '',
          apiKeyValue: values['value'] ?? '',
          apiKeyLocation: values['in'] == 'query'
              ? ApiKeyLocation.query
              : ApiKeyLocation.header,
        );
      default:
        return const RequestAuth();
    }
  }

  static Map<String, dynamic> _exportRequest(RequestEntity request) {
    final decoded = RequestParamsCodec.decodeBody(request.body);
    final rawBody = decoded.text;
    final headers = _decodePairs(request.headersJson);
    final query = _decodePairs(request.queryParamsJson);
    final auth = switch (decoded.auth.type) {
      AuthType.none => {'type': 'noauth'},
      AuthType.bearer => {
          'type': 'bearer',
          'bearer': [
            {'key': 'token', 'value': decoded.auth.token, 'type': 'string'},
          ],
        },
      AuthType.basic => {
          'type': 'basic',
          'basic': [
            {
              'key': 'username',
              'value': decoded.auth.username,
              'type': 'string',
            },
            {
              'key': 'password',
              'value': decoded.auth.password,
              'type': 'string',
            },
          ],
        },
      AuthType.apiKey => {
          'type': 'apikey',
          'apikey': [
            {
              'key': 'key',
              'value': decoded.auth.apiKeyName,
              'type': 'string',
            },
            {
              'key': 'value',
              'value': decoded.auth.apiKeyValue,
              'type': 'string',
            },
            {
              'key': 'in',
              'value': decoded.auth.apiKeyLocation == ApiKeyLocation.query
                  ? 'query'
                  : 'header',
              'type': 'string',
            },
          ],
        },
    };

    final body = switch (decoded.mode) {
      BodyMode.none => null,
      BodyMode.json => {
          'mode': 'raw',
          'raw': rawBody ?? '',
          'options': {
            'raw': {'language': 'json'},
          },
        },
      BodyMode.text => {
          'mode': 'raw',
          'raw': rawBody ?? '',
          'options': {
            'raw': {'language': 'text'},
          },
        },
      BodyMode.formUrlEncoded => {
          'mode': 'urlencoded',
          'urlencoded': _exportStoredFields(rawBody),
        },
      BodyMode.formData => {
          'mode': 'formdata',
          'formdata': _exportStoredFields(rawBody, multipart: true),
        },
      BodyMode.binary => {
          'mode': 'file',
          'file': {'src': rawBody}
        },
    };
    return {
      'name': request.name,
      'request': {
        'method': request.method.toUpperCase(),
        'header': headers,
        'url': {
          'raw': request.url,
          'query': query,
        },
        'auth': auth,
        if (body != null) 'body': body,
      },
    };
  }

  static List<Map<String, dynamic>> _decodePairs(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } on FormatException {
      return [];
    }
    return [];
  }

  static List<Map<String, dynamic>> _exportStoredFields(
    String? source, {
    bool multipart = false,
  }) {
    if (source == null) return [];
    try {
      final decoded = jsonDecode(source);
      if (decoded is List) {
        return [
          for (final item in decoded.whereType<Map>())
            {
              'key': item['key']?.toString() ?? '',
              'type': item['isFile'] == true ? 'file' : 'text',
              'disabled': item['isEnabled'] == false,
              if (multipart && item['isFile'] == true)
                'src': item['value']?.toString() ?? ''
              else
                'value': item['value']?.toString() ?? '',
            },
        ];
      }
    } on FormatException {
      return [];
    }
    return [];
  }

  static HttpMethod _method(String method) => HttpMethod.values.firstWhere(
        (value) => value.name.toLowerCase() == method.toLowerCase(),
        orElse: () => HttpMethod.get,
      );
}

class ImportedCollectionRequest {
  const ImportedCollectionRequest({
    required this.name,
    required this.url,
    required this.method,
    required this.headers,
    required this.queryParams,
    required this.body,
    required this.bodyMode,
    this.formFields = const [],
    this.auth = const RequestAuth(),
  });

  final String name;
  final String url;
  final String method;
  final List<Map<String, dynamic>> headers;
  final List<Map<String, dynamic>> queryParams;
  final String? body;
  final BodyMode bodyMode;
  final List<FormFieldItem> formFields;
  final RequestAuth auth;
}
