import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/clipboard_repository.dart';
import 'package:xbb/models/clipboard/model.dart';

final clipboardRepositoryProvider = Provider<ClipboardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return ClipboardRepository(db: db, changeNotifier: notifier);
});

final clipboardEntriesStreamProvider = StreamProvider<List<DataItem<ClipboardHistoryEntry>>>((ref) {
  final repo = ref.watch(clipboardRepositoryProvider);
  return repo.watchEntries();
});

final clipboardSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredClipboardEntriesProvider = Provider<List<DataItem<ClipboardHistoryEntry>>>((ref) {
  final entriesAsync = ref.watch(clipboardEntriesStreamProvider);
  final query = ref.watch(clipboardSearchQueryProvider).trim().toLowerCase();

  return entriesAsync.when(
    data: (list) {
      if (query.isEmpty) return list;
      return list.where((e) => e.body.data.toLowerCase().contains(query)).toList();
    },
    loading: () => <DataItem<ClipboardHistoryEntry>>[],
    error: (_, __) => <DataItem<ClipboardHistoryEntry>>[],
  );
});
