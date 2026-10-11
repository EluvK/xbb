import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/checkin_repository.dart';
import 'package:xbb/models/checkin/model.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return CheckinRepository(db: db, changeNotifier: notifier);
});

final checkinEventsStreamProvider = StreamProvider<List<DataItem<CheckinEvent>>>((ref) {
  final repo = ref.watch(checkinRepositoryProvider);
  return repo.watchEvents();
});

final checkinRecordsStreamProvider = StreamProvider<List<DataItem<CheckinRecord>>>((ref) {
  final repo = ref.watch(checkinRepositoryProvider);
  return repo.watchRecords();
});

/// 当前选中的日期（用于日历打点与补打卡）
final checkinSelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
