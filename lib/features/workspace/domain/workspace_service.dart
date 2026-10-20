import 'package:bolt/core/storage/isar_service.dart';
import 'package:isar/isar.dart';
import '../data/models/workspace_entity.dart';
import '../data/models/request_entity.dart';

class WorkspaceService {
  static Future<List<WorkspaceEntity>> getAllWorkspaces() async {
    return await IsarService.isar.workspaceEntitys.where().findAll();
  }

  static Future<WorkspaceEntity> createWorkspace(String name) async {
    final workspace = WorkspaceEntity()..name = name;
    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.workspaceEntitys.put(workspace);
    });
    return workspace;
  }

  static Future<void> deleteWorkspace(int id) async {
    await IsarService.isar.writeTxn(() async {
      final requests = await IsarService.isar.requestEntitys
          .filter()
          .workspaceIdEqualTo(id)
          .findAll();
      for (final request in requests) {
        await IsarService.isar.requestEntitys.delete(request.id);
      }
      await IsarService.isar.workspaceEntitys.delete(id);
    });
  }

  static Future<List<RequestEntity>> getRequestsByWorkspace(int workspaceId) async {
    return await IsarService.isar.requestEntitys
        .filter()
        .workspaceIdEqualTo(workspaceId)
        .findAll();
  }

  static Future<RequestEntity> createRequest({
    required String name,
    required String url,
    required String method,
    required String headersJson,
    required String queryParamsJson,
    String? body,
    required int workspaceId,
  }) async {
    final request = RequestEntity()
      ..name = name
      ..url = url
      ..method = method
      ..headersJson = headersJson
      ..queryParamsJson = queryParamsJson
      ..body = body
      ..workspaceId = workspaceId;

    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.requestEntitys.put(request);
    });
    return request;
  }

  static Future<void> deleteRequest(int id) async {
    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.requestEntitys.delete(id);
    });
  }

  static Future<void> updateRequest(RequestEntity request) async {
    await IsarService.isar.writeTxn(() async {
      await IsarService.isar.requestEntitys.put(request);
    });
  }
}
