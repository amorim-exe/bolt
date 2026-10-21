import 'dart:async';

import 'package:bolt/features/http_client/domain/models/request_params.dart';
import 'package:bolt/features/http_client/domain/models/response_result.dart';
import 'package:bolt/features/http_client/domain/models/request_params_codec.dart';
import 'package:bolt/features/http_client/domain/services/response_test_runner.dart';
import 'package:bolt/features/http_client/presentation/controllers/http_client_provider.dart';
import 'package:bolt/features/http_client/presentation/controllers/request_tabs_provider.dart';
import 'package:bolt/features/http_client/presentation/services/request_code_generator.dart';
import 'package:bolt/features/history/data/datasources/request_history_datasource.dart';
import 'package:bolt/features/history/data/models/request_history_entity.dart';
import 'package:bolt/features/history/presentation/history_provider.dart';
import 'package:bolt/core/network/dio_client.dart';
import 'package:bolt/features/http_client/data/datasources/http_remote_ds.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryHistoryDatasource extends RequestHistoryDatasource {
  final entries = <RequestHistoryEntity>[];

  @override
  Future<List<RequestHistoryEntity>> getLatest({int limit = 100}) async =>
      entries;

  @override
  Future<void> add(RequestHistoryEntity entry) async {
    entries.insert(0, entry);
  }

  @override
  Future<void> clear() async => entries.clear();
}

class _DeferredHttpDatasource extends HttpRemoteDataSource {
  _DeferredHttpDatasource() : super(DioClient());

  final completer = Completer<ResponseResult>();
  RequestParams? dispatchedParams;

  @override
  Future<ResponseResult> sendRequest(RequestParams params) {
    dispatchedParams = params;
    return completer.future;
  }
}

class _CapturingHttpDatasource extends HttpRemoteDataSource {
  _CapturingHttpDatasource(this.result) : super(DioClient());

  final ResponseResult result;
  RequestParams? dispatchedParams;

  @override
  Future<ResponseResult> sendRequest(RequestParams params) async {
    dispatchedParams = params;
    return result;
  }
}

void main() {
  group('RequestParamsCodec auth and test settings', () {
    test('round trips authentication and test assertions', () {
      final params = RequestParams(
        url: 'https://api.example.com',
        method: HttpMethod.get,
        auth: const RequestAuth(
          type: AuthType.apiKey,
          apiKeyName: 'api_key',
          apiKeyValue: 'secret',
          apiKeyLocation: ApiKeyLocation.query,
        ),
        testScript: 'status == 200',
      );

      final decoded = RequestParamsCodec.decodeBody(
        RequestParamsCodec.encodeBody(params),
      );

      expect(decoded.auth.type, AuthType.apiKey);
      expect(decoded.auth.apiKeyName, 'api_key');
      expect(decoded.auth.apiKeyValue, 'secret');
      expect(decoded.auth.apiKeyLocation, ApiKeyLocation.query);
      expect(decoded.testScript, 'status == 200');
    });
  });

  group('ResponseTestRunner', () {
    final response = ResponseResult(
      statusCode: 200,
      statusMessage: 'OK',
      data: {
        'data': {'id': 42}
      },
      headers: const {},
      responseTimeMs: 30,
      responseSizeBytes: 12,
    );

    test('evaluates status, duration, and response data assertions', () {
      final results = ResponseTestRunner.run(
        'Status is successful: pm.response.code === 200\n'
        'Fast enough: responseTimeMs < 1000\n'
        'Has item: response.data.data.id == 42',
        response,
      );

      expect(results, hasLength(3));
      expect(results.every((result) => result.passed), isTrue);
    });

    test('reports failed and unsupported assertions instead of executing code',
        () {
      final results = ResponseTestRunner.run(
        'Not found: status == 404\n'
        'Unsupported: process.exit(1)',
        response,
      );

      expect(results, hasLength(2));
      expect(results.first.passed, isFalse);
      expect(results.last.passed, isFalse);
      expect(results.last.message, contains('Unsupported value'));
    });
  });

  group('Request authentication injection', () {
    final success = ResponseResult(
      statusCode: 200,
      statusMessage: 'OK',
      data: const {},
      headers: const {},
      responseTimeMs: 10,
      responseSizeBytes: 2,
    );

    test('creates the Basic Authorization header at dispatch', () async {
      final tabs = RequestTabsNotifier();
      final history = RequestHistoryNotifier(_MemoryHistoryDatasource());
      final remote = _CapturingHttpDatasource(success);
      final client = HttpClientNotifier(remote, tabs, history);
      client.updateAuth(
        const RequestAuth(
          type: AuthType.basic,
          username: 'user',
          password: 'pass',
        ),
      );

      await client.sendRequest();

      expect(
        remote.dispatchedParams!.headers.single.value,
        'Basic dXNlcjpwYXNz',
      );
      client.dispose();
      history.dispose();
      tabs.dispose();
    });

    test('adds API key to the configured query parameter', () async {
      final tabs = RequestTabsNotifier();
      final history = RequestHistoryNotifier(_MemoryHistoryDatasource());
      final remote = _CapturingHttpDatasource(success);
      final client = HttpClientNotifier(remote, tabs, history);
      client.updateAuth(
        const RequestAuth(
          type: AuthType.apiKey,
          apiKeyName: 'key',
          apiKeyValue: 'value',
          apiKeyLocation: ApiKeyLocation.query,
        ),
      );

      await client.sendRequest();

      expect(remote.dispatchedParams!.queryParams.single.key, 'key');
      expect(remote.dispatchedParams!.queryParams.single.value, 'value');
      client.dispose();
      history.dispose();
      tabs.dispose();
    });
  });

  group('URL query parameter detection', () {
    final success = ResponseResult(
      statusCode: 200,
      statusMessage: 'OK',
      data: const {},
      headers: const {},
      responseTimeMs: 10,
      responseSizeBytes: 2,
    );

    test('detects repeated URL query params and keeps manual params', () async {
      final tabs = RequestTabsNotifier();
      final history = RequestHistoryNotifier(_MemoryHistoryDatasource());
      final remote = _CapturingHttpDatasource(success);
      final client = HttpClientNotifier(remote, tabs, history);
      const sourceUrl =
          'https://api.example.com/items?term=hello%20world&tag=a&tag=b#results';

      client.updateUrl(sourceUrl);
      expect(client.state.params.queryParams, hasLength(3));
      expect(
        client.state.params.queryParams.map((param) => param.key),
        ['term', 'tag', 'tag'],
      );
      expect(client.state.params.queryParams.first.value, 'hello world');
      expect(
        client.state.params.queryParams.every((param) => param.isAutoDetected),
        isTrue,
      );

      client.updateQueryParams([]);
      expect(
        client.state.params.queryParams.map((param) => param.key),
        ['term', 'tag', 'tag'],
      );

      client.addQueryParam();
      client.updateQueryParam(3, key: 'limit');
      client.updateQueryParam(3, value: '10');
      client.updateUrl(
        'https://api.example.com/items?term=updated&tag=a&tag=b#results',
      );

      expect(client.state.params.queryParams, hasLength(4));
      expect(client.state.params.queryParams.first.value, 'updated');
      expect(client.state.params.queryParams.last.key, 'limit');
      expect(client.state.params.queryParams.last.isAutoDetected, isFalse);

      await client.sendRequest();
      expect(
        remote.dispatchedParams!.url,
        'https://api.example.com/items#results',
      );
      expect(remote.dispatchedParams!.queryParams, hasLength(4));

      client.dispose();
      history.dispose();
      tabs.dispose();
    });
  });

  group('RequestCodeGenerator', () {
    final params = RequestParams(
      url: 'https://api.example.com/items',
      method: HttpMethod.post,
      headers: [
        HeaderItem(key: 'Authorization', value: 'Bearer token'),
        HeaderItem(key: 'Ignored', value: 'no', isEnabled: false),
      ],
      queryParams: [
        QueryParamItem(key: 'page', value: '2'),
        QueryParamItem(key: 'skip', value: 'yes', isEnabled: false),
      ],
      body: '{"name":"Bolt"}',
      bodyMode: BodyMode.json,
    );

    test('generates each supported format using enabled request fields', () {
      final curl =
          RequestCodeGenerator.generate(params, RequestCodeFormat.curl);
      final javascript =
          RequestCodeGenerator.generate(params, RequestCodeFormat.javascript);
      final python =
          RequestCodeGenerator.generate(params, RequestCodeFormat.python);
      final dart =
          RequestCodeGenerator.generate(params, RequestCodeFormat.dart);

      for (final code in [curl, javascript, python, dart]) {
        expect(code, contains('https://api.example.com/items'));
        expect(code, contains('Authorization'));
        expect(code, contains('page'));
        expect(code, isNot(contains('Ignored')));
        expect(code, isNot(contains('skip')));
      }
      expect(curl, contains('curl -X POST'));
      expect(javascript, contains('fetch('));
      expect(javascript, contains('JSON.stringify({'));
      expect(python, contains('requests.request('));
      expect(dart, contains('Options(method: \'POST\')'));
    });

    test('generates multipart uploads without a manual content type', () {
      final multipart = RequestParams(
        url: 'https://api.example.com/upload',
        method: HttpMethod.post,
        headers: [
          HeaderItem(key: 'Content-Type', value: 'application/json'),
        ],
        bodyMode: BodyMode.formData,
        formFields: [
          FormFieldItem(key: 'description', value: 'sample'),
          FormFieldItem(key: 'file', value: '/tmp/sample.png', isFile: true),
        ],
      );

      final curl =
          RequestCodeGenerator.generate(multipart, RequestCodeFormat.curl);
      final javascript = RequestCodeGenerator.generate(
        multipart,
        RequestCodeFormat.javascript,
      );
      final dart =
          RequestCodeGenerator.generate(multipart, RequestCodeFormat.dart);

      expect(curl, contains("-F 'file=@/tmp/sample.png'"));
      expect(javascript, contains('new FormData()'));
      expect(javascript, isNot(contains('Content-Type')));
      expect(dart, contains('MultipartFile.fromFile'));
      expect(dart, isNot(contains('Content-Type')));
    });

    test('avoids repeating URL query values in generated code', () {
      final params = RequestParams(
        url: 'https://api.example.com/search?q=bolt&page=2',
        method: HttpMethod.get,
        queryParams: [
          QueryParamItem(key: 'q', value: 'bolt', isAutoDetected: true),
          QueryParamItem(key: 'page', value: '2', isAutoDetected: true),
        ],
      );
      final curl =
          RequestCodeGenerator.generate(params, RequestCodeFormat.curl);
      final javascript =
          RequestCodeGenerator.generate(params, RequestCodeFormat.javascript);

      expect(curl, contains('https://api.example.com/search'));
      expect(curl, contains('q=bolt'));
      expect(curl, contains('page=2'));
      expect(
        javascript,
        contains('new URL("https://api.example.com/search")'),
      );
      expect(javascript, isNot(contains('search?q=bolt')));
    });
  });

  group('RequestTabsNotifier', () {
    test('keeps tab state isolated and closes the selected tab', () {
      final tabs = RequestTabsNotifier();
      final firstId = tabs.state.activeTabId;
      final firstParams = tabs.activeTab.params.copyWith(
        url: 'https://first.example',
      );
      tabs.saveActive(tabs.activeTab.copyWith(params: firstParams));

      final secondTab = tabs.openTab(
        params: firstParams.copyWith(url: 'https://second.example'),
        variables: tabs.activeTab.variables,
      );
      expect(tabs.state.tabs, hasLength(2));
      expect(tabs.activeTab.params.url, 'https://second.example');

      final restored = tabs.selectTab(firstId);
      expect(restored.params.url, 'https://first.example');

      final activeAfterClose = tabs.closeTab(secondTab.id);
      expect(tabs.state.tabs, hasLength(1));
      expect(activeAfterClose.id, firstId);
      tabs.dispose();
    });

    test('keeps an in-flight response on the tab that sent the request',
        () async {
      final tabs = RequestTabsNotifier();
      final historyDatasource = _MemoryHistoryDatasource();
      final history = RequestHistoryNotifier(historyDatasource);
      final remote = _DeferredHttpDatasource();
      final client = HttpClientNotifier(remote, tabs, history);

      client.updateUrl('https://first.example');
      final firstTabId = tabs.state.activeTabId;
      final sending = client.sendRequest();

      client.openTab();
      client.updateUrl('https://second.example');
      final response = ResponseResult(
        statusCode: 201,
        statusMessage: 'Created',
        data: {'ok': true},
        headers: const {},
        responseTimeMs: 2,
        responseSizeBytes: 11,
      );
      remote.completer.complete(response);
      await sending;

      expect(client.state.params.url, 'https://second.example');
      expect(client.state.response, isNull);
      final firstTab =
          tabs.state.tabs.firstWhere((tab) => tab.id == firstTabId);
      expect(firstTab.response?.statusCode, 201);
      expect(historyDatasource.entries.single.url, 'https://first.example');
      expect(remote.dispatchedParams?.url, 'https://first.example');

      client.dispose();
      history.dispose();
      tabs.dispose();
    });
  });
}
