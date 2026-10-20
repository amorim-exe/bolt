import 'package:isar/isar.dart';

part 'workspace_entity.g.dart';

@collection
class WorkspaceEntity {
  Id id = Isar.autoIncrement;

  late String name;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();
}
