// lib/core/storage/isar_service.dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/workspace/data/models/request_entity.dart';
import '../../features/workspace/data/models/workspace_entity.dart';
import '../../features/history/data/models/request_history_entity.dart';

class IsarService {
  static late Isar _isar;

  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        WorkspaceEntitySchema,
        RequestEntitySchema,
        RequestHistoryEntitySchema,
      ],
      directory: dir.path,
    );
  }

  static Isar get isar => _isar;
}
