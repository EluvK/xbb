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

class ClipboardDateGroup {
  final String dateKey;
  final DateTime date;
  final List<DataItem<ClipboardHistoryEntry>> entries;

  const ClipboardDateGroup({
    required this.dateKey,
    required this.date,
    required this.entries,
  });
}

String formatClipboardDateKey(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime clipboardDisplayTimeOf(DataItem<ClipboardHistoryEntry> item) {
  return item.body.capturedAt ?? item.createdAt;
}

final groupedClipboardEntriesProvider = Provider<List<ClipboardDateGroup>>((ref) {
  final entries = ref.watch(filteredClipboardEntriesProvider);
  if (entries.isEmpty) return const [];

  final sorted = List<DataItem<ClipboardHistoryEntry>>.from(entries)
    ..sort((a, b) {
      final timeA = clipboardDisplayTimeOf(a);
      final timeB = clipboardDisplayTimeOf(b);
      return timeB.compareTo(timeA);
    });

  final groups = <ClipboardDateGroup>[];
  for (final item in sorted) {
    final displayTime = clipboardDisplayTimeOf(item);
    final local = displayTime.toLocal();
    final dateKey = formatClipboardDateKey(local);
    final date = DateTime(local.year, local.month, local.day);
    if (groups.isNotEmpty && groups.last.dateKey == dateKey) {
      groups.last.entries.add(item);
    } else {
      groups.add(ClipboardDateGroup(dateKey: dateKey, date: date, entries: [item]));
    }
  }
  return groups;
});

final collapsedClipboardDatesProvider = StateNotifierProvider<CollapsedClipboardDatesNotifier, Set<String>>((ref) {
  return CollapsedClipboardDatesNotifier();
});

class CollapsedClipboardDatesNotifier extends StateNotifier<Set<String>> {
  CollapsedClipboardDatesNotifier() : super(<String>{});

  void toggle(String dateKey) {
    if (state.contains(dateKey)) {
      state = Set<String>.from(state)..remove(dateKey);
    } else {
      state = Set<String>.from(state)..add(dateKey);
    }
  }

  void collapse(String dateKey) {
    if (!state.contains(dateKey)) {
      state = Set<String>.from(state)..add(dateKey);
    }
  }

  void expand(String dateKey) {
    if (state.contains(dateKey)) {
      state = Set<String>.from(state)..remove(dateKey);
    }
  }

  void collapseAll(Iterable<String> keys) {
    state = Set<String>.from(state)..addAll(keys);
  }

  void expandAll() {
    state = <String>{};
  }
}

final selectedClipboardIdsProvider = StateNotifierProvider<SelectedClipboardIdsNotifier, Set<String>>((ref) {
  return SelectedClipboardIdsNotifier();
});

class SelectedClipboardIdsNotifier extends StateNotifier<Set<String>> {
  SelectedClipboardIdsNotifier() : super(<String>{});

  void toggle(String id) {
    if (state.contains(id)) {
      state = Set<String>.from(state)..remove(id);
    } else {
      state = Set<String>.from(state)..add(id);
    }
  }

  void select(String id) {
    if (!state.contains(id)) {
      state = Set<String>.from(state)..add(id);
    }
  }

  void deselect(String id) {
    if (state.contains(id)) {
      state = Set<String>.from(state)..remove(id);
    }
  }

  void selectGroup(List<String> ids) {
    state = Set<String>.from(state)..addAll(ids);
  }

  void deselectGroup(List<String> ids) {
    state = Set<String>.from(state)..removeAll(ids);
  }

  void toggleGroup(List<String> ids) {
    if (ids.isEmpty) return;
    final allSelected = ids.every(state.contains);
    if (allSelected) {
      deselectGroup(ids);
    } else {
      selectGroup(ids);
    }
  }

  void clear() {
    state = <String>{};
  }

  void setFailedIds(List<String> failedIds) {
    state = failedIds.toSet();
  }
}
