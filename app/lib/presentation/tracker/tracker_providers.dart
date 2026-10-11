import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/tracker_repository.dart';
import 'package:xbb/models/tracker/model.dart';

final trackerRepositoryProvider = Provider<TrackerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return TrackerRepository(db: db, changeNotifier: notifier);
});

final trackersStreamProvider = StreamProvider<List<DataItem<Tracker>>>((ref) {
  final repo = ref.watch(trackerRepositoryProvider);
  return repo.watchTrackers();
});

final selectedTrackerIdProvider = StateProvider<String?>((ref) => null);

final selectedTrackerRecordsStreamProvider = StreamProvider<List<DataItem<TrackerRecord>>>((ref) {
  final repo = ref.watch(trackerRepositoryProvider);
  final trackerId = ref.watch(selectedTrackerIdProvider);
  return repo.watchRecordsByTracker(trackerId);
});
