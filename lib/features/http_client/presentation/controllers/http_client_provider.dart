import 'package:bolt/features/environment/domain/environment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/http_remote_ds.dart';
import '../../domain/models/request_params.dart';
import '../../domain/models/response_result.dart';

// Provedor do Cliente Dio Base
final dioClientProvider = Provider((ref) => DioClient());

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
  }) : variables = variables ?? [
          EnvironmentVariable(key: 'baseUrl', value: 'https://jsonplaceholder.typicode.com')
        ]; // Valor padrão de exemplo

  HttpClientState copyWith({
    RequestParams? params,
    ResponseResult? response,
    bool? isLoading,
    List<EnvironmentVariable>? variables,
  }) {
    return HttpClientState(
      params: params ?? this.params,
      response: response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      variables: variables ?? this.variables,
    );
  }
}

class HttpClientNotifier extends StateNotifier<HttpClientState> {
  final HttpRemoteDataSource _remoteDataSource;

  HttpClientNotifier(this._remoteDataSource)
      : super(HttpClientState(
          params: RequestParams(
            url: 'https://jsonplaceholder.typicode.com/todos/1',
            method: HttpMethod.get,
          ),
        ));

  void updateUrl(String url) {
    state = state.copyWith(params: state.params.copyWith(url: url));
  }

  void updateMethod(HttpMethod method) {
    state = state.copyWith(params: state.params.copyWith(method: method));
  }

  void updateBody(String body) {
    state = state.copyWith(params: state.params.copyWith(body: body));
  }

  void addHeader() {
    final updatedHeaders = List<HeaderItem>.from(state.params.headers)
      ..add(HeaderItem(key: '', value: ''));
    state =
        state.copyWith(params: state.params.copyWith(headers: updatedHeaders));
  }

  void updateHeader(int index, {String? key, String? value, bool? isEnabled}) {
    final updatedHeaders = List<HeaderItem>.from(state.params.headers);
    final header = updatedHeaders[index];
    updatedHeaders[index] = HeaderItem(
      key: key ?? header.key,
      value: value ?? header.value,
      isEnabled: isEnabled ?? header.isEnabled,
    );
    state =
        state.copyWith(params: state.params.copyWith(headers: updatedHeaders));
  }

  void addQueryParam() {
    final updated = List<QueryParamItem>.from(state.params.queryParams)
      ..add(QueryParamItem(key: '', value: ''));
    state = state.copyWith(params: state.params.copyWith(queryParams: updated));
  }

  void updateQueryParam(int index,
      {String? key, String? value, bool? isEnabled}) {
    final updated = List<QueryParamItem>.from(state.params.queryParams);
    final item = updated[index];
    updated[index] = QueryParamItem(
      key: key ?? item.key,
      value: value ?? item.value,
      isEnabled: isEnabled ?? item.isEnabled,
    );
    state = state.copyWith(params: state.params.copyWith(queryParams: updated));
  }

  void removeQueryParam(int index) {
    final updated = List<QueryParamItem>.from(state.params.queryParams)
      ..removeAt(index);
    state = state.copyWith(params: state.params.copyWith(queryParams: updated));
  }

  void removeHeader(int index) {
    final updatedHeaders = List<HeaderItem>.from(state.params.headers)
      ..removeAt(index);
    state =
        state.copyWith(params: state.params.copyWith(headers: updatedHeaders));
  }

  // Gerenciamento de variáveis
  void updateVariable(int index, {String? key, String? value, bool? isEnabled}) {
    final updated = List<EnvironmentVariable>.from(state.variables);
    final item = updated[index];
    updated[index] = EnvironmentVariable(
      key: key ?? item.key,
      value: value ?? item.value,
      isEnabled: isEnabled ?? item.isEnabled,
    );
    state = state.copyWith(variables: updated);
  }

  void addVariable() {
    final updated = List<EnvironmentVariable>.from(state.variables)
      ..add(EnvironmentVariable(key: '', value: ''));
    state = state.copyWith(variables: updated);
  }

  void removeVariable(int index) {
    final updated = List<EnvironmentVariable>.from(state.variables)..removeAt(index);
    state = state.copyWith(variables: updated);
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
    state = state.copyWith(isLoading: true, response: null);

    final interpolatedUrl = _interpolate(state.params.url);
    final interpolatedBody = state.params.body != null ? _interpolate(state.params.body!) : null;

    final interpolatedParams = state.params.copyWith(
      url: interpolatedUrl,
      body: interpolatedBody,
    );

    final result = await _remoteDataSource.sendRequest(interpolatedParams);

    state = state.copyWith(
      isLoading: false,
      response: result,
    );
  }
}

// Provider global do Controller
final httpClientProvider =
    StateNotifierProvider<HttpClientNotifier, HttpClientState>((ref) {
  final ds = ref.read(httpRemoteDsProvider);
  return HttpClientNotifier(ds);
});
