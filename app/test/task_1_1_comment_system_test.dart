import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/notes/notes_providers.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-1.1: 恢复与升级评论系统 (Comment System)', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late NotesRepository notesRepo;
    late NotesCommentRepository commentRepo;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      notesRepo = NotesRepository(db: db, changeNotifier: dbChangeNotifier);
      commentRepo = NotesCommentRepository(notesRepo);
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('addComment 能够在本地 SQLite 落盘并入队 Outbox', () async {
      final now = DateTime.now();
      final commentItem = DataItem<Comment>(
        'comment-101',
        now,
        now,
        'user-alice',
        'post-001',
        null,
        body: const Comment(
          content: '这是一条很有深度的评论！',
          postId: 'post-001',
        ),
        syncStatus: SyncStatus.pending,
      );

      await commentRepo.addComment(commentItem);

      // 1. 验证 SQLite comment 表落盘
      final rows = await db.query(
        'comment',
        where: 'id = ?',
        whereArgs: ['comment-101'],
      );
      expect(rows.length, equals(1));
      expect(rows.first['owner'], equals('user-alice'));
      expect(rows.first['parent_id'], equals('post-001'));
      final body = jsonDecode(rows.first['body'] as String);
      expect(body['content'], equals('这是一条很有深度的评论！'));

      // 2. 验证入队 Outbox (离线立即可见且变更入队)
      final outboxRows = await db.query(
        'outbox',
        where: 'entity_id = ?',
        whereArgs: ['comment-101'],
      );
      expect(outboxRows.length, equals(1));
      expect(outboxRows.first['table_name'], equals('comment'));
      expect(outboxRows.first['op'], equals('PUT'));
    });

    test('watchComments 支持响应式流驱动与多级嵌套评论', () async {
      final stream = commentRepo.watchComments('post-001');

      final results = <List<DataItem<Comment>>>[];
      final sub = stream.listen((data) => results.add(data));

      final now = DateTime.now();

      // 1. 发送根评论 1
      await commentRepo.addComment(
        DataItem<Comment>(
          'root-1',
          now,
          now,
          'user-alice',
          'post-001',
          null,
          body: const Comment(
            content: '第一条根评论',
            postId: 'post-001',
          ),
          syncStatus: SyncStatus.pending,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      // 2. 发送根评论 2
      await commentRepo.addComment(
        DataItem<Comment>(
          'root-2',
          now.add(const Duration(seconds: 1)),
          now.add(const Duration(seconds: 1)),
          'user-bob',
          'post-001',
          null,
          body: const Comment(
            content: '第二条根评论',
            postId: 'post-001',
          ),
          syncStatus: SyncStatus.pending,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      // 3. 发送回复评论 (parentId = root-1)
      await commentRepo.addComment(
        DataItem<Comment>(
          'reply-1',
          now.add(const Duration(seconds: 2)),
          now.add(const Duration(seconds: 2)),
          'user-charlie',
          'post-001',
          null,
          body: const Comment(
            content: '@user-alice 赞同你的看法！',
            postId: 'post-001',
            parentId: 'root-1',
          ),
          syncStatus: SyncStatus.pending,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(results.isNotEmpty, isTrue);
      final lastList = results.last;
      expect(lastList.length, equals(3));
      expect(lastList.any((c) => c.id == 'root-1' && c.body.parentId == null), isTrue);
      expect(lastList.any((c) => c.id == 'root-2' && c.body.parentId == null), isTrue);
      expect(lastList.any((c) => c.id == 'reply-1' && c.body.parentId == 'root-1'), isTrue);

      await sub.cancel();
    });

    test('deleteComment 物理删除评论并在 Outbox 产生 delete 记录', () async {
      final now = DateTime.now();
      await commentRepo.addComment(
        DataItem<Comment>(
          'comment-del',
          now,
          now,
          'user-alice',
          'post-001',
          null,
          body: const Comment(
            content: '即将被删除的评论',
            postId: 'post-001',
          ),
          syncStatus: SyncStatus.pending,
        ),
      );

      // 确认存在
      final beforeRows = await db.query('comment', where: 'id = ?', whereArgs: ['comment-del']);
      expect(beforeRows.length, equals(1));

      // 执行删除
      await commentRepo.deleteComment('comment-del');

      // 确认从 comment 表删除
      final afterRows = await db.query('comment', where: 'id = ?', whereArgs: ['comment-del']);
      expect(afterRows.isEmpty, isTrue);

      // 确认 Outbox 中产生 delete 记录
      final outboxDeleteRows = await db.query(
        'outbox',
        where: 'entity_id = ? AND op = ?',
        whereArgs: ['comment-del', 'DELETE'],
      );
      expect(outboxDeleteRows.length, equals(1));
    });

    test('commentsStreamProvider 可以在 Riverpod 容器中正常响应', () async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          dbChangeNotifierProvider.overrideWithValue(dbChangeNotifier),
        ],
      );
      addTearDown(container.dispose);

      final subscription = container.listen(
        commentsStreamProvider('post-999'),
        (previous, next) {},
      );

      // 初始查询触发
      dbChangeNotifier.notify('comment');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();
      await container.read(commentRepositoryProvider).addComment(
        DataItem<Comment>(
          'c-riverpod-1',
          now,
          now,
          'user-provider',
          'post-999',
          null,
          body: const Comment(
            content: 'Riverpod 驱动测试评论',
            postId: 'post-999',
          ),
          syncStatus: SyncStatus.pending,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final asyncVal = container.read(commentsStreamProvider('post-999'));
      expect(asyncVal.value?.length, equals(1));
      expect(asyncVal.value?.first.id, equals('c-riverpod-1'));

      subscription.close();
    });
  });
}
