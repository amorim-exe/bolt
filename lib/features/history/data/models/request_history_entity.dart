import 'package:isar/isar.dart';

part 'request_history_entity.g.dart';

@collection
class RequestHistoryEntity {
  Id id = Isar.autoIncrement;

  late String url;
  late String method;
  late String headersJson;
  late String queryParamsJson;
  String? body;
  int? statusCode;
  DateTime timestamp = DateTime.now();
}
