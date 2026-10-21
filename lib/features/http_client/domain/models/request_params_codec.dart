import 'dart:convert';

import 'request_params.dart';

class RequestParamsCodec {
  static String encodeBody(RequestParams params) => jsonEncode({
        '__boltBody': 1,
        'mode': params.bodyMode.name,
        'text': params.body,
        'fields': [
          for (final field in params.formFields)
            {
              'key': field.key,
              'value': field.value,
              'isFile': field.isFile,
              'isEnabled': field.isEnabled,
            },
        ],
        'auth': {
          'type': params.auth.type.name,
          'token': params.auth.token,
          'username': params.auth.username,
          'password': params.auth.password,
          'apiKeyName': params.auth.apiKeyName,
          'apiKeyValue': params.auth.apiKeyValue,
          'apiKeyLocation': params.auth.apiKeyLocation.name,
        },
        'testScript': params.testScript,
      });

  static DecodedRequestBody decodeBody(String? source) {
    var bodyMode = BodyMode.json;
    String? text = source;
    var fields = <FormFieldItem>[];
    var auth = const RequestAuth();
    var testScript = '';

    if (source != null) {
      try {
        final decoded = jsonDecode(source);
        if (decoded is Map && decoded['__boltBody'] == 1) {
          bodyMode = BodyMode.values.firstWhere(
            (mode) => mode.name == decoded['mode'],
            orElse: () => BodyMode.json,
          );
          text = decoded['text'] as String?;
          final encodedFields = decoded['fields'];
          if (encodedFields is List) {
            fields = encodedFields.whereType<Map>().map((field) {
              return FormFieldItem(
                key: field['key']?.toString() ?? '',
                value: field['value']?.toString() ?? '',
                isFile: field['isFile'] == true,
                isEnabled: field['isEnabled'] != false,
              );
            }).toList();
          }
          final encodedAuth = decoded['auth'];
          if (encodedAuth is Map) {
            auth = RequestAuth(
              type: AuthType.values.firstWhere(
                (value) => value.name == encodedAuth['type'],
                orElse: () => AuthType.none,
              ),
              token: encodedAuth['token']?.toString() ?? '',
              username: encodedAuth['username']?.toString() ?? '',
              password: encodedAuth['password']?.toString() ?? '',
              apiKeyName: encodedAuth['apiKeyName']?.toString() ?? '',
              apiKeyValue: encodedAuth['apiKeyValue']?.toString() ?? '',
              apiKeyLocation: ApiKeyLocation.values.firstWhere(
                (value) => value.name == encodedAuth['apiKeyLocation'],
                orElse: () => ApiKeyLocation.header,
              ),
            );
          }
          testScript = decoded['testScript']?.toString() ?? '';
        }
      } on FormatException {
        // Plain text bodies from older saved requests remain supported.
      }
    }
    return DecodedRequestBody(
      mode: bodyMode,
      text: text,
      fields: fields,
      auth: auth,
      testScript: testScript,
    );
  }
}

class DecodedRequestBody {
  const DecodedRequestBody({
    required this.mode,
    required this.text,
    required this.fields,
    this.auth = const RequestAuth(),
    this.testScript = '',
  });

  final BodyMode mode;
  final String? text;
  final List<FormFieldItem> fields;
  final RequestAuth auth;
  final String testScript;
}
