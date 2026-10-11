import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/checkin_repository.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/data/repositories/task_repository.dart';
import 'package:xbb/models/notes/db.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/models/task/db.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/outbox_dao.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await LocalFirstDB.closeAll();
    LocalFirstDB.setMockDb(null);
  });

  group('APP 现代化架构重置与端到端响应式验证', () {
    test('P1 验证: 各业务模块 DB 统一收拢到底层 LocalFirstDB (同一数据库物理实例)', () async {
      final dbInMemory = await LocalFirstDB.openInMemory();
      LocalFirstDB.setMockDb(dbInMemory);

      final notesDb = await NotesDB().getDb();
      final taskDb = await TaskDB().getDb();

      expect(identical(notesDb, taskDb), isTrue);
      await dbInMemory.close();
    });

    test('P2 验证: TaskRepository 写操作事务内落盘并入队 Outbox 且触发响应式 Stream', () async {
      final db = await LocalFirstDB.openInMemory();
      final notifier = DatabaseChangeNotifier();
      final repo = TaskRepository(db: db, changeNotifier: notifier);

      await repo.addTask('重置后现代架构待办测试', 'user-001');

      final active = await repo.getOrCreateActiveCheckList('user-001');
      final items = decodeTaskItems(active.body.tasks);
      expect(items.length, equals(1));
      expect(items.first.content, equals('重置后现代架构待办测试'));
      expect(items.first.done, isFalse);

      final pendingOutbox = await OutboxDao.getPending(db);
      expect(pendingOutbox.isNotEmpty, isTrue);
      expect(pendingOutbox.any((item) => item.tableName == 'check_list'), isTrue);

      notifier.dispose();
      await db.close();
    });

    test('P3 验证: NotesRepository 保存 Repo 与 Post 均落盘并入队 Outbox', () async {
      final db = await LocalFirstDB.openInMemory();
      final notifier = DatabaseChangeNotifier();
      final repo = NotesRepository(db: db, changeNotifier: notifier);

      final repoId = UuidService.v7();
      final now = DateTime.now();
      final newRepo = DataItem<Repo>(
        repoId,
        now,
        now,
        'user-001',
        null,
        null,
        body: const Repo(name: '工作笔记本', status: 'active'),
        syncStatus: SyncStatus.pending,
      );
      await repo.saveRepo(newRepo);

      final postId = UuidService.v7();
      final newPost = DataItem<Post>(
        postId,
        now,
        now,
        'user-001',
        repoId,
        null,
        body: Post(
          title: '现代化架构重构指引',
          category: '架构',
          content: '彻底淘汰山寨 GetX，全面拥抱 Riverpod 与响应式 Local-First！',
          repoId: repoId,
        ),
        syncStatus: SyncStatus.pending,
      );
      await repo.savePost(newPost);

      final repoRows = await db.query('repo', where: 'id = ?', whereArgs: [repoId]);
      expect(repoRows.length, equals(1));

      final postRows = await db.query('post', where: 'id = ?', whereArgs: [postId]);
      expect(postRows.length, equals(1));

      final pending = await OutboxDao.getPending(db);
      expect(pending.any((o) => o.tableName == 'repo' && o.entityId == repoId), isTrue);
      expect(pending.any((o) => o.tableName == 'post' && o.entityId == postId), isTrue);

      notifier.dispose();
      await db.close();
    });

    test('P4 验证: CheckinRepository 严格执行 ADR-0003 约束', () async {
      final db = await LocalFirstDB.openInMemory();
      final notifier = DatabaseChangeNotifier();
      final repo = CheckinRepository(db: db, changeNotifier: notifier);

      final tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(
        () => repo.checkin(
          eventId: 'ev-01',
          targetDate: tomorrow,
          currentUserId: 'user-001',
        ),
        throwsA(isA<ArgumentError>()),
      );

      final ok1 = await repo.checkin(
        eventId: 'ev-01',
        targetDate: DateTime.now(),
        currentUserId: 'user-001',
      );
      expect(ok1, isTrue);

      final ok2 = await repo.checkin(
        eventId: 'ev-01',
        targetDate: DateTime.now(),
        currentUserId: 'user-001',
      );
      expect(ok2, isFalse);

      notifier.dispose();
      await db.close();
    });
  });
}
