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

/// 当前聚焦查看的月份（默认为当前本地时间）
final checkinFocusedDayProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// 当前选中的过滤事件 ID 集合（空集合表示不过滤/显示全部）
final checkinFilteredEventIdsProvider = StateProvider<Set<String>>((ref) {
  return <String>{};
});

/// 当前聚焦年月的各个事件完成次数响应式统计
final checkinMonthlyCountsStreamProvider = StreamProvider<Map<String, int>>((ref) {
  final repo = ref.watch(checkinRepositoryProvider);
  final focused = ref.watch(checkinFocusedDayProvider);
  return repo.watchMonthlyCheckinCounts(focused.year, focused.month);
});

/// 当前生效的事件过滤集合（若用户未做排他过滤，则返回全部事件 ID）
final effectiveFilteredEventIdsProvider = Provider<Set<String>>((ref) {
  final filtered = ref.watch(checkinFilteredEventIdsProvider);
  final events = ref.watch(checkinEventsStreamProvider).value ?? [];
  if (filtered.isEmpty || filtered.length == events.length) {
    return events.map((e) => e.id).toSet();
  }
  return filtered;
});
