import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/core/acl/acl_repository.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-1.2: 恢复小本本权限与协作 (ACL & Sharing)', () {
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

    test('grantRepoPermission 与 revokeRepoPermission 在本地记录并产生 Outbox 变更事件', () async {
      final repoId = 'repo-knowledge-1';

      final entry1 = EntityAclEntry(
        userId: 'collab-bob',
        username: 'bob',
        nickname: 'Bob',
        avatar: 'preset_avatar_1',
        role: EntityAclRole.share,
      );

      // 1. 授予权限
      await notesRepo.grantRepoPermission(repoId, entry1);

      // 验证本地 acl 表
      final acls = await notesRepo.getRepoAcls(repoId);
      expect(acls.length, equals(1));
      expect(acls.first.userId, equals('collab-bob'));
      expect(acls.first.role, equals(EntityAclRole.share));

      // 验收标准：Outbox 正确产生 ACL 变更事件
      final outboxGrant = await db.query(
        'outbox',
        where: 'table_name = ? AND entity_id = ?',
        whereArgs: ['acl', repoId],
      );
      expect(outboxGrant.isNotEmpty, isTrue);
      expect(outboxGrant.last['op'], equals('PUT'));

      // 2. 追加第二个协作者 (只读 Spy)
      final entry2 = EntityAclEntry(
        userId: 'collab-charlie',
        username: 'charlie',
        nickname: 'Charlie',
        avatar: 'preset_avatar_2',
        role: EntityAclRole.spy,
      );
      await notesRepo.grantRepoPermission(repoId, entry2);

      final aclsAfterSecond = await notesRepo.getRepoAcls(repoId);
      expect(aclsAfterSecond.length, equals(2));

      // 3. 撤销权限
      await notesRepo.revokeRepoPermission(repoId, 'collab-bob');

      final aclsAfterRevoke = await notesRepo.getRepoAcls(repoId);
      expect(aclsAfterRevoke.length, equals(1));
      expect(aclsAfterRevoke.first.userId, equals('collab-charlie'));

      // 验证 Outbox 产生最新的 ACL 变更记录
      final outboxAfterRevoke = await db.query(
        'outbox',
        where: 'table_name = ? AND entity_id = ?',
        whereArgs: ['acl', repoId],
      );
      expect(outboxAfterRevoke.length, equals(3));
    });

    test('watchRepoAcls 支持响应式流实时推送权限变更', () async {
      final repoId = 'repo-stream-1';
      final stream = notesRepo.watchRepoAcls(repoId);

      final updates = <List<EntityAclEntry>>[];
      final sub = stream.listen((list) => updates.add(list));

      // 初始触发
      dbChangeNotifier.notify('acl');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      await notesRepo.grantRepoPermission(
        repoId,
        EntityAclEntry(
          userId: 'user-guest',
          username: 'guest',
          nickname: 'Guest',
          avatar: 'avatar_1',
          role: EntityAclRole.subscribe,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(updates.isNotEmpty, isTrue);
      expect(updates.last.length, equals(1));
      expect(updates.last.first.role, equals(EntityAclRole.subscribe));

      await sub.cancel();
    });

    test('标准分享链接 generateShareLink 与 parseShareLink 互逆解析', () {
      final ownerId = 'user-alice-99';
      final repoId = 'repo-docs-88';

      // 1. 生成链接
      final link = NotesRepository.generateShareLink(ownerId, repoId);
      expect(link, equals('xbb-share://user-alice-99/repo-docs-88'));

      // 2. 正确解析
      final parsed = NotesRepository.parseShareLink(link);
      expect(parsed, isNotNull);
      expect(parsed!.ownerId, equals(ownerId));
      expect(parsed.repoId, equals(repoId));

      // 3. 容错测试
      expect(NotesRepository.parseShareLink('invalid-url'), isNull);
      expect(NotesRepository.parseShareLink('http://example.com'), isNull);
    });
  });
}
