import 'dart:convert';

import 'package:bolt/features/environment/domain/environment_model.dart';
import 'package:bolt/features/history/data/models/request_history_entity.dart';
import 'package:bolt/features/history/presentation/history_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/settings/app_settings.dart';
import '../../data/datasources/http_remote_ds.dart';
import '../../domain/models/request_params.dart';
import '../../domain/models/request_params_codec.dart';
import '../../domain/models/response_result.dart';
import '../../domain/services/response_test_runner.dart';
import 'request_tabs_provider.dart';

// Provedor do Cliente Dio Base
final dioClientProvider = Provider((ref) {
  final client = DioClient(ref.read(appSettingsProvider).settings);
  ref.listen<AppSettingsState>(appSettingsProvider, (previous, next) {
    client.updateSettings(next.settings);
  });
  return client;
});

// Provedor do Datasource HTTP
final httpRemoteDsProvider =
    Provider((ref) => HttpRemoteDataSource(ref.read(dioClientProvider)));

// Estado da Requisição Ativa
class HttpClientState {
  final RequestParams params;
  final ResponseResult? response;
  final bool isLoading;
  final List<EnvironmentVariable> variables;

  HttpClientState({
    required this.params,
    this.response,
    this.isLoading = false,
    List<EnvironmentVariable>? variables,
  }) : variables = variables ??
            [
              EnvironmentVariable(
                  key: 'baseUrl', value: 'https://jsonplaceholder.typicode.com')
            ]; // Valor padrão de exemplo

  HttpClientState copyWith({
    RequestParams? params,
    ResponseResult? response,
    bool? isLoading,
    List<EnvironmentVariable>? variables,
    bool clearResponse = false,
  }) {
    return HttpClientState(
      params: params ?? this.params,
      response: clearResponse ? null : response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      variables: variables ?? this.variables,
    );
  }
}

class HttpClientNotifier extends StateNotifier<HttpClientState> {
  final HttpRemoteDataSource _remoteDataSource;
  final RequestTabsNotifier _tabsNotifier;
  final RequestHistoryNotifier _historyNotifier;

  HttpClientNotifier(
    this._remoteDataSource,
    this._tabsNotifier,
    this._historyNotifier,
  ) : super(_stateFor(_tabsNotifier.activeTab));

  static HttpClientState _stateFor(RequestTabSnapshot tab) => HttpClientState(
        params: tab.params,
        response: tab.response,
        isLoading: tab.isLoading,
        variables: tab.variables,
      );

  void _commit(HttpClientState next) {
    state = next;
    _tabsNotifier.saveActive(
      _tabsNotifier.activeTab.copyWith(
        params: next.params,
        response: next.response,
        isLoading: next.isLoading,
        clearResponse: next.response == null,
        variables: List.unmodifiable(next.variables),
      ),
    );
  }

  void _restoreTab(RequestTabSnapshot tab) {
    state = _stateFor(tab);
  }

  void openTab({
    RequestParams? params,
    String name = 'New Request',
    int? savedRequestId,
  }) {
    _commit(state);
    final tab = _tabsNotifier.openTab(
      params: params ??
          RequestParams(
            url: 'https://jsonplaceholder.typicode.com/todos/1',
            method: HttpMethod.get,
          ),
      variables: state.variables,
      name: name,
      savedRequestId: savedRequestId,
    );
    _restoreTab(tab);
  }

  void selectTab(int id) {
    _commit(state);
    _restoreTab(_tabsNotifier.selectTab(id));
  }

  void closeTab(int id) {
    if (id == _tabsNotifier.state.activeTabId) _commit(state);
    _restoreTab(_tabsNotifier.closeTab(id));
  }

  void setTabMetadata({required String name, int? savedRequestId}) {
    _tabsNotifier.saveActive(
      _tabsNotifier.activeTab.copyWith(
        name: name,
        savedRequestId: savedRequestId,
        clearSavedRequestId: savedRequestId == null,
      ),
    );
  }

  void updateUrl(String url) {
    final existing = state.params.queryParams;
    final retainedManual =
        existing.where((param) => !param.isAutoDetected).toList();
    final detected = _queryParamsFromUrl(url);
    final synchronized = <QueryParamItem>[];
    final usedExisting = <int>{};

    for (final item in detected) {
      final matchingIndex = existing.indexWhere(
        (param) =>
            !usedExisting.contains(existing.indexOf(param)) &&
            param.key == item.key,
      );
      if (matchingIndex >= 0) {
        usedExisting.add(matchingIndex);
      }
      final previous = matchingIndex >= 0 ? existing[matchingIndex] : null;
      synchronized.add(
        QueryParamItem(
          key: item.key,
          value: item.value,
          isEnabled: previous?.isEnabled ?? true,
          isAutoDetected: true,
        ),
      );
    }

    final detectedKeys = detected.map((item) => item.key).toSet();
    synchronized.addAll(
      retainedManual.where((param) => !detectedKeys.contains(param.key)),
    );
    _commit(
      state.copyWith(
        params: state.params.copyWith(url: url, queryParams: synchronized),
      ),
    );
  }

  List<QueryParamItem> _queryParamsFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasQuery) return [];
    return [
      for (final entry in uri.queryParametersAll.entries)
        for (final value in entry.value)
          QueryParamItem(
            key: entry.key,
            value: value,
            isAutoDetected: true,
          ),
    ];
  }

  void updateMethod(HttpMethod method) {
    _commit(state.copyWith(params: state.params.copyWith(method: method)));
  }

  void updateBody(String body) {
    _commit(state.copyWith(params: state.params.copyWith(body: body)));
  }

  void updateBodyMode(BodyMode mode) {
    _commit(state.copyWith(params: state.params.copyWith(bodyMode: mode)));
  }

  void clearResponse() {
    _commit(state.copyWith(clearResponse: true));
  }

  void addFormField({bool isFile = false}) {
    final fields = List<FormFieldItem>.from(state.params.formFields)
      ..add(FormFieldItem(key: '', value: '', isFile: isFile));
    _commit(state.copyWith(params: state.params.copyWith(formFields: fields)));
  }

  void updateFormField(
    int index, {
    String? key,
    String? value,
    bool? isFile,
    bool? isEnabled,
  }) {
    final fields = List<FormFieldItem>.from(state.params.formFields);
    final field = fields[index];
    fields[index] = FormFieldItem(
      key: key ?? field.key,
      value: value ?? field.value,
      isFile: isFile ?? field.isFile,
      isEnabled: isEnabled ?? field.isEnabled,
    );
    _commit(state.copyWith(params: state.params.copyWith(formFields: fields)));
  }

  void removeFormField(int index) {
    final fields = List<FormFieldItem>.from(state.params.formFields)
      ..removeAt(index);
    _commit(state.copyWith(params: state.params.copyWith(formFields: fields)));
  }

  void updateFormFields(List<FormFieldItem> fields) {
    _commit(state.copyWith(params: state.params.copyWith(formFields: fields)));
  }

  void updateHeaders(List<HeaderItem> headers) {
    _commit(state.copyWith(params: state.params.copyWith(headers: headers)));
  }

  void updateQueryParams(List<QueryParamItem> queryParams) {
    final paramsToApply = queryParams.isEmpty
        ? state.params.queryParams
            .where((param) => param.isAutoDetected)
            .toList()
        : queryParams;
    _commit(state.copyWith(
      params: state.params.copyWith(queryParams: paramsToApply),
    ));
  }

  void updateAuth(RequestAuth auth) {
    _commit(state.copyWith(params: state.params.copyWith(auth: auth)));
  }

  void updateTestScript(String testScript) {
    _commit(state.copyWith(
      params: state.params.copyWith(testScript: testScript),
    ));
  }

  void addHeader() {
    final updatedHeaders = List<HeaderItem>.from(state.params.headers)
      ..add(HeaderItem(key: '', value: ''));
    _commit(
      state.copyWith(params: state.params.copyWith(headers: updatedHeaders)),
    );
  }

  void addHeaderPreset({required String key, required String value}) {
    final updatedHeaders = List<HeaderItem>.from(state.params.headers)
      ..add(HeaderItem(key: key, value: value));
    _commit(
      state.copyWith(params: state.params.copyWith(headers: updatedHeaders)),
    );
  }

  void updateHeader(int index, {String? key, String? value, bool? isEnabled}) {
    final updatedHeaders = List<HeaderItem>.from(state.params.headers);
    final header = updatedHeaders[index];
    updatedHeaders[index] = HeaderItem(
      key: key ?? header.key,
      value: value ?? header.value,
      isEnabled: isEnabled ?? header.isEnabled,
    );
    _commit(
      state.copyWith(params: state.params.copyWith(headers: updatedHeaders)),
    );
  }

  void addQueryParam() {
    final updated = List<QueryParamItem>.from(state.params.queryParams)
      ..add(QueryParamItem(key: '', value: ''));
    _commit(
        state.copyWith(params: state.params.copyWith(queryParams: updated)));
  }

  void updateQueryParam(int index,
      {String? key, String? value, bool? isEnabled}) {
    final updated = List<QueryParamItem>.from(state.params.queryParams);
    final item = updated[index];
    updated[index] = QueryParamItem(
      key: key ?? item.key,
      value: value ?? item.value,
      isEnabled: isEnabled ?? item.isEnabled,
      isAutoDetected:
          key != null || value != null ? false : item.isAutoDetected,
    );
    _commit(
        state.copyWith(params: state.params.copyWith(queryParams: updated)));
  }

  void removeQueryParam(int index) {
    final updated = List<QueryParamItem>.from(state.params.queryParams)
      ..removeAt(index);
    _commit(
        state.copyWith(params: state.params.copyWith(queryParams: updated)));
  }

  void removeHeader(int index) {
    final updatedHeaders = List<HeaderItem>.from(state.params.headers)
      ..removeAt(index);
    _commit(
      state.copyWith(params: state.params.copyWith(headers: updatedHeaders)),
    );
  }

  // Gerenciamento de variáveis
  void updateVariable(int index,
      {String? key, String? value, bool? isEnabled}) {
    final updated = List<EnvironmentVariable>.from(state.variables);
    final item = updated[index];
    updated[index] = EnvironmentVariable(
      key: key ?? item.key,
      value: value ?? item.value,
      isEnabled: isEnabled ?? item.isEnabled,
    );
    _commit(state.copyWith(variables: updated));
  }

  void addVariable() {
    final updated = List<EnvironmentVariable>.from(state.variables)
      ..add(EnvironmentVariable(key: '', value: ''));
    _commit(state.copyWith(variables: updated));
  }

  void removeVariable(int index) {
    final updated = List<EnvironmentVariable>.from(state.variables)
      ..removeAt(index);
    _commit(state.copyWith(variables: updated));
  }

  String _interpolate(String text) {
    var result = text;
    for (var v in state.variables) {
      if (v.isEnabled && v.key.trim().isNotEmpty) {
        result = result.replaceAll('{{${v.key.trim()}}}', v.value.trim());
      }
    }
    return result;
  }

  Future<void> sendRequest() async {
    final requestState = state;
    final tabId = _tabsNotifier.state.activeTabId;
    _commit(state.copyWith(isLoading: true, clearResponse: true));

    final interpolatedUrl = _interpolate(requestState.params.url);
    final interpolatedBody = requestState.params.body != null
        ? _interpolate(requestState.params.body!)
        : null;

    final interpolatedParams = requestState.params.copyWith(
      url: interpolatedUrl,
      body: interpolatedBody,
      auth: RequestAuth(
        type: requestState.params.auth.type,
        token: _interpolate(requestState.params.auth.token),
        username: _interpolate(requestState.params.auth.username),
        password: _interpolate(requestState.params.auth.password),
        apiKeyName: _interpolate(requestState.params.auth.apiKeyName),
        apiKeyValue: _interpolate(requestState.params.auth.apiKeyValue),
        apiKeyLocation: requestState.params.auth.apiKeyLocation,
      ),
      headers: [
        for (final header in requestState.params.headers)
          HeaderItem(
            key: _interpolate(header.key),
            value: _interpolate(header.value),
            isEnabled: header.isEnabled,
          ),
      ],
      formFields: [
        for (final field in requestState.params.formFields)
          FormFieldItem(
            key: _interpolate(field.key),
            value: field.isFile ? field.value : _interpolate(field.value),
            isFile: field.isFile,
            isEnabled: field.isEnabled,
          ),
      ],
    );

    final headers = List<HeaderItem>.from(interpolatedParams.headers);
    final queryParams =
        List<QueryParamItem>.from(interpolatedParams.queryParams);
    final auth = interpolatedParams.auth;
    if (auth.type == AuthType.bearer || auth.type == AuthType.basic) {
      headers.removeWhere(
          (header) => header.key.trim().toLowerCase() == 'authorization');
      final credential = auth.type == AuthType.bearer
          ? 'Bearer ${auth.token}'
          : 'Basic ${base64Encode(utf8.encode('${auth.username}:${auth.password}'))}';
      headers.add(HeaderItem(key: 'Authorization', value: credential));
      if (auth.type == AuthType.bearer) {
        headers[headers.length - 1] =
            HeaderItem(key: 'Authorization', value: 'Bearer ${auth.token}');
      }
    } else if (auth.type == AuthType.apiKey && auth.apiKeyName.isNotEmpty) {
      if (auth.apiKeyLocation == ApiKeyLocation.header) {
        headers.removeWhere((header) =>
            header.key.trim().toLowerCase() ==
            auth.apiKeyName.trim().toLowerCase());
        headers.add(
          HeaderItem(key: auth.apiKeyName, value: auth.apiKeyValue),
        );
      } else {
        queryParams
            .removeWhere((param) => param.key.trim() == auth.apiKeyName.trim());
        queryParams.add(
          QueryParamItem(key: auth.apiKeyName, value: auth.apiKeyValue),
        );
      }
    }
    final requestToSend = interpolatedParams.copyWith(
      url: _removeUrlQuery(interpolatedParams.url),
      headers: headers,
      queryParams: queryParams,
    );
    final rawResult = await _remoteDataSource.sendRequest(requestToSend);
    final result = rawResult.copyWith(
      testResults: ResponseTestRunner.run(
        requestState.params.testScript,
        rawResult,
      ),
    );

    final originalTab = _tabsNotifier.state.tabs.firstWhere(
      (tab) => tab.id == tabId,
    );
    _tabsNotifier.saveTab(
      tabId,
      originalTab.copyWith(response: result, isLoading: false),
    );
    if (_tabsNotifier.state.activeTabId == tabId) {
      state = state.copyWith(isLoading: false, response: result);
    }
    await _historyNotifier.add(
      RequestHistoryEntity()
        ..url = requestState.params.url
        ..method = requestState.params.method.name
        ..headersJson = jsonEncode([
          for (final header in requestState.params.headers)
            {
              'key': header.key,
              'value': header.value,
              'isEnabled': header.isEnabled,
            },
        ])
        ..queryParamsJson = jsonEncode([
          for (final param in requestState.params.queryParams)
            {
              'key': param.key,
              'value': param.value,
              'isEnabled': param.isEnabled,
              'isAutoDetected': param.isAutoDetected,
            },
        ])
        ..body = RequestParamsCodec.encodeBody(requestState.params)
        ..statusCode = result.statusCode
        ..timestamp = DateTime.now(),
    );
  }

  String _removeUrlQuery(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasQuery) return url;
    final fragmentIndex = url.indexOf('#');
    final fragment = fragmentIndex < 0 ? '' : url.substring(fragmentIndex);
    final beforeFragment =
        fragmentIndex < 0 ? url : url.substring(0, fragmentIndex);
    final queryIndex = beforeFragment.indexOf('?');
    if (queryIndex < 0) return url;
    return '${beforeFragment.substring(0, queryIndex)}$fragment';
  }
}

// Provider global do Controller
final httpClientProvider =
    StateNotifierProvider<HttpClientNotifier, HttpClientState>((ref) {
  final ds = ref.read(httpRemoteDsProvider);
  return HttpClientNotifier(
    ds,
    ref.read(requestTabsProvider.notifier),
    ref.read(requestHistoryProvider.notifier),
  );
});
