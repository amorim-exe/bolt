// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (_) =>
            true, // Permite capturar 400, 500 sem disparar exception automática
      ),
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

  Dio get dio => _dio;
}
