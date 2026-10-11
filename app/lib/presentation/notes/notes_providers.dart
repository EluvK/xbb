import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/models/notes/model.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return NotesRepository(db: db, changeNotifier: notifier);
});

final reposStreamProvider = StreamProvider<List<DataItem<Repo>>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchRepos();
});

final selectedRepoIdProvider = StateProvider<String?>((ref) {
  final reposAsync = ref.watch(reposStreamProvider);
  return reposAsync.when(
    data: (list) => list.isNotEmpty ? list.first.id : null,
    loading: () => null,
    error: (_, __) => null,
  );
});

final postsStreamProvider = StreamProvider<List<DataItem<Post>>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  final currentRepoId = ref.watch(selectedRepoIdProvider);
  return repo.watchPostsByRepo(currentRepoId);
});

final selectedPostIdProvider = StateProvider<String?>((ref) => null);

final currentPostStreamProvider = StreamProvider<DataItem<Post>?>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  final postId = ref.watch(selectedPostIdProvider);
  return repo.watchPostById(postId);
});
