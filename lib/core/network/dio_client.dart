// lib/core/network/dio_client.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../settings/app_settings.dart';

class DioClient {
  late final Dio _dio;
  late bool _verifySslCertificates;

  DioClient([AppSettings settings = const AppSettings()]) {
    _verifySslCertificates = settings.verifySslCertificates;
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: settings.timeoutSeconds),
        receiveTimeout: Duration(seconds: settings.timeoutSeconds),
        followRedirects: settings.followRedirects,
        validateStatus: (_) =>
            true, // Permite capturar 400, 500 sem disparar exception automática
      ),
    );
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (certificate, host, port) =>
            !_verifySslCertificates;
        return client;
      },
    );

    // Interceptor para medir tempo de resposta
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['startTime'] = DateTime.now().millisecondsSinceEpoch;
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final startTime = response.requestOptions.extra['startTime'] as int?;
          if (startTime != null) {
            final duration = DateTime.now().millisecondsSinceEpoch - startTime;
            response.extra['responseTime'] = duration;
          }
          response.extra['capturedCookies'] =
              response.headers['set-cookie'] ?? const <String>[];
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          final startTime = e.requestOptions.extra['startTime'] as int?;
          if (startTime != null) {
            final duration = DateTime.now().millisecondsSinceEpoch - startTime;
            e.response?.extra['responseTime'] = duration;
          }
          e.response?.extra['capturedCookies'] =
              e.response?.headers['set-cookie'] ?? const <String>[];
          return handler.next(e);
        },
      ),
    );
  }

  void updateSettings(AppSettings settings) {
    _verifySslCertificates = settings.verifySslCertificates;
    _dio.options
      ..connectTimeout = Duration(seconds: settings.timeoutSeconds)
      ..receiveTimeout = Duration(seconds: settings.timeoutSeconds)
      ..followRedirects = settings.followRedirects;
  }

  Dio get dio => _dio;
}
