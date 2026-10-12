import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return NotesRepository(db: db, changeNotifier: notifier);
});

final reposStreamProvider = StreamProvider<List<DataItem<Repo>>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchRepos();
});

final myReposStreamProvider = StreamProvider<List<DataItem<Repo>>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  final userId = ref.watch(authProvider).userId;
  return repo.watchMyRepos(userId);
});

final subscribedReposStreamProvider = StreamProvider<List<DataItem<Repo>>>((ref) {
  final repo = ref.watch(notesRepositoryProvider);
  final userId = ref.watch(authProvider).userId;
  return repo.watchSubscribedRepos(userId);
});

final selectedRepoIdProvider = StateProvider<String?>((ref) {
  ref.listen<AsyncValue<List<DataItem<Repo>>>>(reposStreamProvider, (prev, next) {
    final list = next.value;
    if (list != null && list.isNotEmpty) {
      final current = ref.controller.state;
      if (current == null || !list.any((r) => r.id == current)) {
        ref.controller.state = list.first.id;
      }
    } else if (list != null && list.isEmpty) {
      ref.controller.state = null;
    }
  }, fireImmediately: true);
  return null;
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

final commentRepositoryProvider = Provider<NotesCommentRepository>((ref) {
  final notesRepo = ref.watch(notesRepositoryProvider);
  return NotesCommentRepository(notesRepo);
});

final commentsStreamProvider =
    StreamProvider.family<List<DataItem<Comment>>, String>((ref, postId) {
  final repo = ref.watch(notesRepositoryProvider);
  return repo.watchComments(postId);
});
