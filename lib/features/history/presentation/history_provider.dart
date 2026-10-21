import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/request_history_datasource.dart';
import '../data/models/request_history_entity.dart';

final requestHistoryDatasourceProvider =
    Provider<RequestHistoryDatasource>((ref) => RequestHistoryDatasource());

final requestHistoryProvider = StateNotifierProvider<RequestHistoryNotifier,
    AsyncValue<List<RequestHistoryEntity>>>((ref) {
  return RequestHistoryNotifier(ref.read(requestHistoryDatasourceProvider))
    ..load();
});

class RequestHistoryNotifier
    extends StateNotifier<AsyncValue<List<RequestHistoryEntity>>> {
  RequestHistoryNotifier(this._datasource) : super(const AsyncData([]));

  final RequestHistoryDatasource _datasource;

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_datasource.getLatest);
  }

  Future<void> add(RequestHistoryEntity entry) async {
    await _datasource.add(entry);
    state = AsyncData(await _datasource.getLatest());
  }

  Future<void> clear() async {
    await _datasource.clear();
    state = const AsyncData([]);
  }
}
