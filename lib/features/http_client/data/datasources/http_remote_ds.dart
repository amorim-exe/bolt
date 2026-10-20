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

      final activeQueryParams = <String, dynamic>{};
      for (var q in params.queryParams) {
        if (q.isEnabled && q.key.trim().isNotEmpty) {
          activeQueryParams[q.key.trim()] = q.value.trim();
        }
      }

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
      final responseString =
          response.data is String ? response.data : jsonEncode(response.data);
      final responseSize = utf8.encode(responseString).length;

      // Normaliza os headers do Dio
      final normalizedHeaders = <String, List<String>>{};
      response.headers.forEach((name, values) {
        normalizedHeaders[name] = values;
      });

      return ResponseResult(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? '',
        data: response.data,
        headers: normalizedHeaders,
        responseTimeMs: responseTime,
        responseSizeBytes: responseSize,
      );
    } on DioException catch (e) {
      final responseTime = e.response?.extra['responseTime'] as int? ?? 0;

      return ResponseResult(
        statusCode: e.response?.statusCode ?? 500,
        statusMessage:
            e.response?.statusMessage ?? e.message ?? 'Erro desconhecido',
        data: e.response?.data ?? {'error': e.message},
        headers: {},
        responseTimeMs: responseTime,
        responseSizeBytes: 0,
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
