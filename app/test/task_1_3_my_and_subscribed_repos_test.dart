import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/notes/notes_providers.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _TestAuthNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-1.3: 恢复“我的小本本”与“订阅小本本”双视图及快速切库器', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late NotesRepository notesRepo;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      notesRepo = NotesRepository(db: db, changeNotifier: dbChangeNotifier);
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('watchMyRepos 与 watchSubscribedRepos 正确区分自建与订阅仓库', () async {
      final now = DateTime.now();

      // 1. 添加当前用户 (user-me) 的自建仓库
      final myRepoItem = DataItem<Repo>(
        'repo-self-1',
        now,
        now,
        'user-me',
        null,
        null,
        body: const Repo(name: '我的私人笔记', status: 'active'),
        syncStatus: SyncStatus.synced,
      );
      await notesRepo.saveRepo(myRepoItem);

      // 2. 添加他人 (user-friend) 的仓库 (模拟订阅仓库)
      final subRepoItem = DataItem<Repo>(
        'repo-sub-1',
        now,
        now,
        'user-friend',
        null,
        null,
        body: const Repo(name: '团队技术周刊', status: 'active'),
        syncStatus: SyncStatus.synced,
      );
      await notesRepo.saveRepo(subRepoItem);

      // 3. 验证 watchMyRepos 仅流出 user-me 的仓库
      final myRepos = await notesRepo.watchMyRepos('user-me').first;
      expect(myRepos.length, equals(1));
      expect(myRepos.first.id, equals('repo-self-1'));
      expect(myRepos.first.owner, equals('user-me'));

      // 4. 验证 watchSubscribedRepos 仅流出他人的仓库
      final subRepos = await notesRepo.watchSubscribedRepos('user-me').first;
      expect(subRepos.length, equals(1));
      expect(subRepos.first.id, equals('repo-sub-1'));
      expect(subRepos.first.owner, equals('user-friend'));
    });

    test('切换 selectedRepoId 时 postsStreamProvider 瞬时刷新对应文章', () async {
      final now = DateTime.now();

      // 创建两个仓库
      await notesRepo.saveRepo(
        DataItem<Repo>(
          'repo-a',
          now,
          now,
          'user-me',
          null,
          null,
          body: const Repo(name: 'Repo A', status: 'active'),
          syncStatus: SyncStatus.synced,
        ),
      );
      await notesRepo.saveRepo(
        DataItem<Repo>(
          'repo-b',
          now,
          now,
          'user-me',
          null,
          null,
          body: const Repo(name: 'Repo B', status: 'active'),
          syncStatus: SyncStatus.synced,
        ),
      );

      // 分别在两个仓库下建文章
      await notesRepo.savePost(
        DataItem<Post>(
          'post-a-1',
          now,
          now,
          'user-me',
          'repo-a',
          null,
          body: const Post(title: 'A 的文章', category: '默认', content: 'AAA', repoId: 'repo-a'),
          syncStatus: SyncStatus.synced,
        ),
      );
      await notesRepo.savePost(
        DataItem<Post>(
          'post-b-1',
          now,
          now,
          'user-me',
          'repo-b',
          null,
          body: const Post(title: 'B 的文章', category: '默认', content: 'BBB', repoId: 'repo-b'),
          syncStatus: SyncStatus.synced,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          dbChangeNotifierProvider.overrideWithValue(dbChangeNotifier),
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(
              const AuthState(
                isLoggedIn: true,
                userId: 'user-me',
                username: 'me',
                nickname: 'Me',
                avatar: 'avatar_1',
                token: 'test-token',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // 监听文章流与仓库流
      final repoSub = container.listen(reposStreamProvider, (_, __) {});
      final postSub = container.listen(postsStreamProvider, (_, __) {});

      // 触发初始仓库加载完成
      dbChangeNotifier.notify('repo');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 明确选择 repo-a
      container.read(selectedRepoIdProvider.notifier).state = 'repo-a';
      dbChangeNotifier.notify('post');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final postsA = container.read(postsStreamProvider);
      expect(postsA.value?.length, equals(1));
      expect(postsA.value?.first.id, equals('post-a-1'));

      // 切换到 repo-b (切库器行为)
      container.read(selectedRepoIdProvider.notifier).state = 'repo-b';
      dbChangeNotifier.notify('post');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final postsB = container.read(postsStreamProvider);
      expect(postsB.value?.length, equals(1));
      expect(postsB.value?.first.id, equals('post-b-1'));

      postSub.close();
      repoSub.close();
    });
  });
}
