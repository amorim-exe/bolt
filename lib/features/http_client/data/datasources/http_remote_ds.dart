import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/request_params.dart';
import '../../domain/models/response_result.dart';

class HttpRemoteDataSource {
  final DioClient _dioClient;

  HttpRemoteDataSource(this._dioClient);

  Future<ResponseResult> sendRequest(RequestParams params) async {
    try {
      final dio = _dioClient.dio;

      // Filtra apenas os headers habilitados e transforma em Map<String, dynamic>
      final activeHeaders = <String, dynamic>{};
      for (var h in params.headers) {
        if (h.isEnabled && h.key.trim().isNotEmpty) {
          activeHeaders[h.key.trim()] = h.value.trim();
        }
      }

      final queryValues = <String, List<String>>{};
      for (var q in params.queryParams) {
        if (q.isEnabled && q.key.trim().isNotEmpty) {
          queryValues.putIfAbsent(q.key.trim(), () => []).add(q.value.trim());
        }
      }
      final activeQueryParams = <String, dynamic>{
        for (final entry in queryValues.entries)
          entry.key: entry.value.length == 1 ? entry.value.single : entry.value,
      };

      dynamic data;
      String? contentType;
      switch (params.bodyMode) {
        case BodyMode.none:
          break;
        case BodyMode.json:
          final body = params.body;
          if (body != null && body.isNotEmpty) {
            try {
              data = jsonDecode(body);
            } catch (_) {
              data = body;
            }
          }
          contentType = Headers.jsonContentType;
        case BodyMode.text:
          data = params.body;
          contentType = Headers.textPlainContentType;
        case BodyMode.formUrlEncoded:
          data = _formFieldsToMap(params.formFields);
          contentType = Headers.formUrlEncodedContentType;
        case BodyMode.formData:
          data = await _createFormData(params.formFields);
        case BodyMode.binary:
          final path = params.body;
          if (path != null && path.isNotEmpty) {
            data = await File(path).readAsBytes();
          }
          contentType = 'application/octet-stream';
      }

      if (params.bodyMode == BodyMode.formData) {
        activeHeaders.removeWhere(
          (key, _) => key.toLowerCase() == 'content-type',
        );
      }

      final options = Options(
        headers: activeHeaders.isEmpty ? null : activeHeaders,
        contentType: contentType,
        method: params.method.name.toUpperCase(),
        responseType: ResponseType.bytes,
      );

      final method = params.method.name.toUpperCase();
      final response = await dio.request(
        params.url,
        data: const {'GET', 'HEAD', 'CONNECT'}.contains(method) ? null : data,
        queryParameters: activeQueryParams.isEmpty ? null : activeQueryParams,
        options: options,
      );

      // Tempo calculado pelo interceptor
      final responseTime = response.extra['responseTime'] as int? ?? 0;

      // Tamanho aproximado da resposta em bytes
      final responseBytes = response.data is List<int>
          ? response.data as List<int>
          : utf8.encode(response.data?.toString() ?? '');
      final responseData = _decodeResponse(
        responseBytes,
        response.headers.value(Headers.contentTypeHeader),
      );
      final responseSize = responseBytes.length;

      // Normaliza os headers do Dio
      final normalizedHeaders = <String, List<String>>{};
      response.headers.forEach((name, values) {
        normalizedHeaders[name] = values;
      });

      return ResponseResult(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? '',
        data: responseData,
        headers: normalizedHeaders,
        responseTimeMs: responseTime,
        responseSizeBytes: responseSize,
        cookies: List<String>.from(
          response.extra['capturedCookies'] as List? ?? const [],
        ),
      );
    } on DioException catch (e) {
      final responseTime = e.response?.extra['responseTime'] as int? ?? 0;
      final responseBytes = e.response?.data is List<int>
          ? e.response!.data as List<int>
          : utf8.encode(e.response?.data?.toString() ?? '');
      final responseHeaders = <String, List<String>>{};
      e.response?.headers.forEach((name, values) {
        responseHeaders[name] = values;
      });

      return ResponseResult(
        statusCode: e.response?.statusCode ?? 500,
        statusMessage:
            e.response?.statusMessage ?? e.message ?? 'Erro desconhecido',
        data: e.response == null
            ? {'error': e.message}
            : _decodeResponse(
                responseBytes,
                e.response?.headers.value(Headers.contentTypeHeader),
              ),
        headers: responseHeaders,
        responseTimeMs: responseTime,
        responseSizeBytes: responseBytes.length,
        cookies: List<String>.from(
          e.response?.extra['capturedCookies'] as List? ?? const [],
        ),
      );
    } catch (e) {
      return ResponseResult(
        statusCode: 0,
        statusMessage: e.toString(),
        data: {'error': e.toString()},
        headers: {},
        responseTimeMs: 0,
        responseSizeBytes: 0,
      );
    }
  }

  dynamic _decodeResponse(List<int> bytes, String? contentType) {
    final mimeType = contentType?.split(';').first.trim().toLowerCase() ?? '';
    final isText = mimeType.startsWith('text/') ||
        mimeType.contains('json') ||
        mimeType.contains('xml') ||
        mimeType.contains('javascript') ||
        mimeType.contains('x-www-form-urlencoded');
    if (!isText) return bytes;

    final text = utf8.decode(bytes, allowMalformed: true);
    if (mimeType.contains('json')) {
      try {
        return jsonDecode(text);
      } on FormatException {
        return text;
      }
    }
    return text;
  }

  Map<String, dynamic> _formFieldsToMap(List<FormFieldItem> fields) {
    return {
      for (final field in fields)
        if (field.isEnabled && field.key.trim().isNotEmpty)
          field.key.trim(): field.value,
    };
  }

  Future<FormData> _createFormData(List<FormFieldItem> fields) async {
    final data = <String, dynamic>{};
    for (final field in fields) {
      if (!field.isEnabled || field.key.trim().isEmpty) continue;
      if (field.isFile) {
        if (field.value.isNotEmpty) {
          data[field.key.trim()] = await MultipartFile.fromFile(field.value);
        }
      } else {
        data[field.key.trim()] = field.value;
      }
    }
    return FormData.fromMap(data);
  }
}
