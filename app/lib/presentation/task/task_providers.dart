import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/task_repository.dart';
import 'package:xbb/models/task/model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return TaskRepository(db: db, changeNotifier: notifier);
});

final activeCheckListStreamProvider = StreamProvider<DataItem<CheckList>?>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchActiveCheckList();
});

final activeTaskItemsProvider = Provider<List<TaskItem>>((ref) {
  final activeAsync = ref.watch(activeCheckListStreamProvider);
  return activeAsync.when(
    data: (item) {
      if (item == null) return <TaskItem>[];
      return sortTaskItems(decodeTaskItems(item.body.tasks));
    },
    loading: () => <TaskItem>[],
    error: (_, __) => <TaskItem>[],
  );
});

final archivedCheckListsProvider = StreamProvider<List<DataItem<CheckList>>>((ref) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchArchivedCheckLists();
});
