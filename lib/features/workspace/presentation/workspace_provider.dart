import 'package:bolt/features/workspace/domain/workspace_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/workspace_entity.dart';
import '../data/models/request_entity.dart';

class WorkspaceState {
  final List<WorkspaceEntity> workspaces;
  final WorkspaceEntity? selectedWorkspace;
  final List<RequestEntity> requests;
  final bool isLoading;
  final Set<int> expandedWorkspaces;
  final Map<int, List<RequestEntity>> workspaceRequests;

  WorkspaceState({
    this.workspaces = const [],
    this.selectedWorkspace,
    this.requests = const [],
    this.isLoading = false,
    this.expandedWorkspaces = const {},
    this.workspaceRequests = const {},
  });

  WorkspaceState copyWith({
    List<WorkspaceEntity>? workspaces,
    WorkspaceEntity? selectedWorkspace,
    List<RequestEntity>? requests,
    bool? isLoading,
    Set<int>? expandedWorkspaces,
    Map<int, List<RequestEntity>>? workspaceRequests,
  }) {
    return WorkspaceState(
      workspaces: workspaces ?? this.workspaces,
      selectedWorkspace: selectedWorkspace ?? this.selectedWorkspace,
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      expandedWorkspaces: expandedWorkspaces ?? this.expandedWorkspaces,
      workspaceRequests: workspaceRequests ?? this.workspaceRequests,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier() : super(WorkspaceState()) {
    loadWorkspaces();
  }

  Future<void> loadWorkspaces() async {
    state = state.copyWith(isLoading: true);
    try {
      final workspaces = await WorkspaceService.getAllWorkspaces();
      state = state.copyWith(workspaces: workspaces, isLoading: false);

      if (workspaces.isNotEmpty && state.selectedWorkspace == null) {
        await selectWorkspace(workspaces.first.id);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createWorkspace(String name) async {
    await WorkspaceService.createWorkspace(name);
    await loadWorkspaces();
  }

  Future<void> renameWorkspace(int id, String name) async {
    final workspace = await WorkspaceService.renameWorkspace(id, name);
    final workspaces = state.workspaces
        .map((item) => item.id == id ? workspace : item)
        .toList();
    state = state.copyWith(
      workspaces: workspaces,
      selectedWorkspace:
          state.selectedWorkspace?.id == id ? workspace : null,
    );
  }

  Future<void> deleteWorkspace(int id) async {
    await WorkspaceService.deleteWorkspace(id);
    if (state.selectedWorkspace?.id == id) {
      state = state.copyWith(selectedWorkspace: null, requests: []);
    }
    await loadWorkspaces();
  }

  Future<void> selectWorkspace(int id) async {
    final workspace = state.workspaces.firstWhere((w) => w.id == id);
    final requests = await WorkspaceService.getRequestsByWorkspace(id);

    final newRequests =
        Map<int, List<RequestEntity>>.from(state.workspaceRequests);
    newRequests[id] = requests;

    state = state.copyWith(
      selectedWorkspace: workspace,
      requests: requests,
      workspaceRequests: newRequests,
    );
  }

  Future<void> loadRequestsForWorkspace(int workspaceId) async {
    final requests = await WorkspaceService.getRequestsByWorkspace(workspaceId);
    final newRequests =
        Map<int, List<RequestEntity>>.from(state.workspaceRequests);
    newRequests[workspaceId] = requests;
    state = state.copyWith(workspaceRequests: newRequests);
  }

  List<RequestEntity> getRequestsForWorkspace(int workspaceId) {
    return state.workspaceRequests[workspaceId] ?? [];
  }

  Future<void> createRequest({
    required String name,
    required String url,
    required String method,
    required String headersJson,
    required String queryParamsJson,
    String? body,
  }) async {
    if (state.selectedWorkspace == null) return;

    await WorkspaceService.createRequest(
      name: name,
      url: url,
      method: method,
      headersJson: headersJson,
      queryParamsJson: queryParamsJson,
      body: body,
      workspaceId: state.selectedWorkspace!.id,
    );
    await selectWorkspace(state.selectedWorkspace!.id);
  }

  Future<RequestEntity?> saveRequest({
    int? id,
    required String name,
    required String url,
    required String method,
    required String headersJson,
    required String queryParamsJson,
    String? body,
  }) async {
    final workspace = state.selectedWorkspace;
    if (workspace == null) return null;

    final request = await WorkspaceService.saveRequest(
      id: id,
      name: name,
      url: url,
      method: method,
      headersJson: headersJson,
      queryParamsJson: queryParamsJson,
      body: body,
      workspaceId: workspace.id,
    );
    await loadWorkspaces();
    await selectWorkspace(request.workspaceId);
    return request;
  }

  Future<void> deleteRequest(int id) async {
    await WorkspaceService.deleteRequest(id);
    if (state.selectedWorkspace != null) {
      await selectWorkspace(state.selectedWorkspace!.id);
    }
  }

  Future<void> renameRequest(int id, String name) async {
    final request = await WorkspaceService.renameRequest(id, name);
    final requests = state.requests
        .map((item) => item.id == id ? request : item)
        .toList();
    final workspaceRequests =
        Map<int, List<RequestEntity>>.from(state.workspaceRequests);
    final cachedRequests = workspaceRequests[request.workspaceId];
    if (cachedRequests != null) {
      workspaceRequests[request.workspaceId] = cachedRequests
          .map((item) => item.id == id ? request : item)
          .toList();
    }
    state = state.copyWith(
      requests: requests,
      workspaceRequests: workspaceRequests,
    );
  }

  Future<void> toggleWorkspaceExpanded(int workspaceId) async {
    final newExpanded = Set<int>.from(state.expandedWorkspaces);

    if (newExpanded.contains(workspaceId)) {
      newExpanded.remove(workspaceId);

      state = state.copyWith(expandedWorkspaces: newExpanded);
    } else {
      newExpanded.add(workspaceId);

      state = state.copyWith(expandedWorkspaces: newExpanded);

      if (!state.workspaceRequests.containsKey(workspaceId)) {
        await loadRequestsForWorkspace(workspaceId);
      }
    }
  }
}

final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier();
});
