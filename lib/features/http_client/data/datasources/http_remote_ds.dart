// lib/features/http_client/data/datasources/http_remote_ds.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/request_params.dart';
import '../../domain/models/response_result.dart';

class HttpRemoteDataSource {
  final DioClient _dioClient;

  HttpRemoteDataSource(this._dioClient);

  Future<ResponseResult> sendRequest(RequestParams params) async {
    try {
      Response response;
      final dio = _dioClient.dio;

      // Prepara o body caso exista e não seja GET/DELETE
      dynamic parsedBody = params.body;
      if (params.body != null && params.body!.isNotEmpty) {
        try {
          parsedBody = jsonDecode(params.body!);
        } catch (_) {
          parsedBody = params.body;
        }
      }

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

      // Opções com headers unificados
      final options = Options(
        headers: activeHeaders.isEmpty ? null : activeHeaders,
      );

      // Executa o método HTTP correspondente
      switch (params.method) {
        case HttpMethod.get:
          response = await dio.get(params.url, queryParameters: activeQueryParams.isEmpty ? null : activeQueryParams, options: options);
          break;
        case HttpMethod.post:
          response = await dio.post(params.url, data: parsedBody, queryParameters: activeQueryParams.isEmpty ? null : activeQueryParams, options: options);
          break;
        case HttpMethod.put:
          response = await dio.put(params.url, data: parsedBody, queryParameters: activeQueryParams.isEmpty ? null : activeQueryParams, options: options);
          break;
        case HttpMethod.delete:
          response = await dio.delete(params.url, data: parsedBody, queryParameters: activeQueryParams.isEmpty ? null : activeQueryParams, options: options);
          break;
        case HttpMethod.patch:
          response = await dio.patch(params.url, data: parsedBody, queryParameters: activeQueryParams.isEmpty ? null : activeQueryParams, options: options);
          break;
      }

      // Tempo calculado pelo interceptor
      final responseTime = response.extra['responseTime'] as int? ?? 0;

      // Tamanho aproximado da resposta em bytes
      final responseString = response.data is String ? response.data : jsonEncode(response.data);
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
        statusMessage: e.response?.statusMessage ?? e.message ?? 'Erro desconhecido',
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
}