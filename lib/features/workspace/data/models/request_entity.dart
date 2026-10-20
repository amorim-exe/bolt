import 'package:isar/isar.dart';

part 'request_entity.g.dart';

@collection
class RequestEntity {
  Id id = Isar.autoIncrement;

  late String name;
  late String url;
  late String method;

  late String headersJson;
  late String queryParamsJson;
  String? body;

  late int workspaceId;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}