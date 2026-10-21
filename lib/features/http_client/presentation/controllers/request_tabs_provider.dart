import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../environment/domain/environment_model.dart';
import '../../domain/models/request_params.dart';
import '../../domain/models/response_result.dart';

class RequestTabSnapshot {
  const RequestTabSnapshot({
    required this.id,
    required this.name,
    required this.params,
    required this.variables,
    this.response,
    this.isLoading = false,
    this.savedRequestId,
  });

  final int id;
  final String name;
  final RequestParams params;
  final List<EnvironmentVariable> variables;
  final ResponseResult? response;
  final bool isLoading;
  final int? savedRequestId;

  RequestTabSnapshot copyWith({
    String? name,
    RequestParams? params,
    List<EnvironmentVariable>? variables,
    ResponseResult? response,
    bool? isLoading,
    bool clearResponse = false,
    int? savedRequestId,
    bool clearSavedRequestId = false,
  }) {
    return RequestTabSnapshot(
      id: id,
      name: name ?? this.name,
      params: params ?? this.params,
      variables: variables ?? this.variables,
      response: clearResponse ? null : response ?? this.response,
      isLoading: isLoading ?? this.isLoading,
      savedRequestId:
          clearSavedRequestId ? null : savedRequestId ?? this.savedRequestId,
    );
  }
}

class RequestTabsState {
  const RequestTabsState({
    required this.tabs,
    required this.activeTabId,
  });

  final List<RequestTabSnapshot> tabs;
  final int activeTabId;

  RequestTabSnapshot get activeTab =>
      tabs.firstWhere((tab) => tab.id == activeTabId);
}

class RequestTabsNotifier extends StateNotifier<RequestTabsState> {
  RequestTabsNotifier()
      : super(
          RequestTabsState(
            tabs: [_createTab(0)],
            activeTabId: 0,
          ),
        );

  static int _nextId = 1;

  static RequestTabSnapshot _createTab(int id) => RequestTabSnapshot(
        id: id,
        name: 'New Request',
        params: RequestParams(
          url: 'https://jsonplaceholder.typicode.com/todos/1',
          method: HttpMethod.get,
        ),
        variables: [
          EnvironmentVariable(
            key: 'baseUrl',
            value: 'https://jsonplaceholder.typicode.com',
          ),
        ],
      );

  RequestTabSnapshot get activeTab => state.activeTab;

  void saveActive(RequestTabSnapshot snapshot) {
    saveTab(state.activeTabId, snapshot);
  }

  void saveTab(int id, RequestTabSnapshot snapshot) {
    state = RequestTabsState(
      tabs: [
        for (final tab in state.tabs)
          if (tab.id == id) snapshot else tab,
      ],
      activeTabId: state.activeTabId,
    );
  }

  RequestTabSnapshot openTab({
    required RequestParams params,
    required List<EnvironmentVariable> variables,
    String name = 'New Request',
    int? savedRequestId,
  }) {
    final tab = RequestTabSnapshot(
      id: _nextId++,
      name: name,
      params: params,
      variables: List.unmodifiable(variables),
      savedRequestId: savedRequestId,
    );
    state = RequestTabsState(
      tabs: [...state.tabs, tab],
      activeTabId: tab.id,
    );
    return tab;
  }

  RequestTabSnapshot selectTab(int id) {
    final tab = state.tabs.firstWhere((item) => item.id == id);
    state = RequestTabsState(tabs: state.tabs, activeTabId: id);
    return tab;
  }

  RequestTabSnapshot closeTab(int id) {
    if (state.tabs.length == 1) {
      final replacement = _createTab(_nextId++);
      state = RequestTabsState(
        tabs: [replacement],
        activeTabId: replacement.id,
      );
      return replacement;
    }

    final closedIndex = state.tabs.indexWhere((tab) => tab.id == id);
    final tabs = state.tabs.where((tab) => tab.id != id).toList();
    final activeId = state.activeTabId == id
        ? tabs[(closedIndex - 1).clamp(0, tabs.length - 1)].id
        : state.activeTabId;
    state = RequestTabsState(tabs: tabs, activeTabId: activeId);
    return state.activeTab;
  }
}

final requestTabsProvider =
    StateNotifierProvider<RequestTabsNotifier, RequestTabsState>(
  (ref) => RequestTabsNotifier(),
);
