import 'package:isar/isar.dart';

import '../../../../core/storage/isar_service.dart';
import '../models/request_history_entity.dart';

class RequestHistoryDatasource {
  Future<List<RequestHistoryEntity>> getLatest({int limit = 100}) {
    return IsarService.isar.requestHistoryEntitys
        .where()
        .sortByTimestampDesc()
        .limit(limit)
        .findAll();
  }

  Future<void> add(RequestHistoryEntity entry) async {
    final isar = IsarService.isar;
    await isar.writeTxn(() async {
      await isar.requestHistoryEntitys.put(entry);
      final excess = await isar.requestHistoryEntitys
          .where()
          .sortByTimestampDesc()
          .offset(100)
          .findAll();
      if (excess.isNotEmpty) {
        await isar.requestHistoryEntitys.deleteAll(
          excess.map((item) => item.id).toList(),
        );
      }
    });
  }

  Future<void> clear() async {
    final isar = IsarService.isar;
    await isar.writeTxn(() => isar.requestHistoryEntitys.clear());
  }
}
