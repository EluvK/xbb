import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/core.dart';
import 'package:xbb/models/notes/db.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/models/task/db.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/sync/v2/sync_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await LocalFirstDB.closeAll();
    LocalFirstDB.setMockDb(null);
    Locate.clear();
  });

  group('APP 运行时问题修复专项验证', () {
    testWidgets('P0 验证: AppNavigator 路由参数传递与 Get.arguments 提取正常工作且不为 null', (tester) async {
      final key = AppNavigator.navigatorKey;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          navigatorObservers: [AppNavigator.observer],
          initialRoute: '/',
          routes: {
            '/': (context) => const Scaffold(body: Text('Home')),
            '/detail': (context) {
              final args = Get.arguments;
              final text = args is List && args.isNotEmpty ? args[0].toString() : 'NO_ARGS';
              return Scaffold(body: Text('Detail: $text'));
            },
          },
        ),
      );

      expect(find.text('Home'), findsOneWidget);

      // 通过 AppNavigator 携带参数跳转
      AppNavigator.toNamed('/detail', arguments: ['HelloRepair']);
      await tester.pumpAndSettle();

      expect(find.text('Detail: HelloRepair'), findsOneWidget);
      expect(Get.arguments, equals(['HelloRepair']));

      // 验证返回上一页
      AppNavigator.back();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });

    test('P1 验证: 各业务模块 DB 统一收拢到底层 LocalFirstDB (同一数据库物理实例)', () async {
      Locate.clear();
      final dbInMemory = await LocalFirstDB.openInMemory();
      LocalFirstDB.setMockDb(dbInMemory);

      final notesDb = await NotesDB().getDb();
      final taskDb = await TaskDB().getDb();

      // 两个不同模块的 DB 获取到的必须是同一个数据库实例
      expect(identical(notesDb, taskDb), isTrue);
      expect(identical(notesDb, dbInMemory), isTrue);

      // 核心业务表必须已在该统一库中就绪
      final tables = await dbInMemory.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = tables.map((e) => e['name'] as String).toSet();
      expect(tableNames.contains('repo'), isTrue);
      expect(tableNames.contains('post'), isTrue);
      expect(tableNames.contains('check_list'), isTrue);
      expect(tableNames.contains('outbox'), isTrue);
      expect(tableNames.contains('sync_meta'), isTrue);
      expect(tableNames.contains('acl'), isTrue);

      await dbInMemory.close();
      LocalFirstDB.setMockDb(null);
    });

    test('P3 验证: Task 业务 Controller 的 addData / updateData / deleteData 均落盘并入队 Outbox', () async {
      Locate.clear();
      final db = await LocalFirstDB.openInMemory();
      LocalFirstDB.setMockDb(db);

      final tokenStorage = InMemoryTokenStorage();
      tokenStorage.setUserId('user_task_test');
      final client = SyncStoreClient(
        baseUrl: 'http://localhost:8080',
        tokenStorage: tokenStorage,
      );

      final taskCtrl = CheckListController(client);
      await taskCtrl.ensureInitialization();

      // 1. 添加任务
      const initialTask = CheckList(tasks: '[{"id":"t1","name":"购买牛奶","completed":false}]', archived: false);
      taskCtrl.addData(initialTask);

      // 等待异步落盘事务完成
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // 验证本地数据库中已持久化
      final savedRows = await db.query('check_list');
      expect(savedRows.length, equals(1));
      expect(savedRows.first['body'], contains('购买牛奶'));

      // 验证 Outbox 中已生成待推送的 PUT 变更
      final outboxItems1 = await OutboxDao.getPending(db);
      expect(outboxItems1.length, equals(1));
      expect(outboxItems1.first.tableName, equals('check_list'));
      expect(outboxItems1.first.op, equals('PUT'));
      expect(outboxItems1.first.data, contains('购买牛奶'));

      final entityId = savedRows.first['id'] as String;

      // 2. 更新任务
      const updatedTask = CheckList(tasks: '[{"id":"t1","name":"购买牛奶","completed":true}]', archived: false);
      taskCtrl.updateData(entityId, updatedTask);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final updatedRows = await db.query('check_list', where: 'id = ?', whereArgs: [entityId]);
      expect(updatedRows.first['body'], contains('购买牛奶'));
      expect(updatedRows.first['body'], contains('true'));

      final outboxItems2 = await OutboxDao.getPending(db);
      expect(outboxItems2.length, equals(2));
      expect(outboxItems2.last.op, equals('PUT'));

      // 3. 删除任务
      taskCtrl.deleteData(entityId);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final deletedRows = await db.query('check_list', where: 'id = ?', whereArgs: [entityId]);
      expect(deletedRows.isEmpty, isTrue);

      final outboxItems3 = await OutboxDao.getPending(db);
      expect(outboxItems3.length, equals(3));
      expect(outboxItems3.last.op, equals('DELETE'));
      expect(outboxItems3.last.entityId, equals(entityId));

      await db.close();
      LocalFirstDB.setMockDb(null);
    });

    test('P3 验证: Notes 业务 Controller 的 addData / updateData / deleteData 均落盘并入队 Outbox', () async {
      Locate.clear();
      final db = await LocalFirstDB.openInMemory();
      LocalFirstDB.setMockDb(db);

      final tokenStorage = InMemoryTokenStorage();
      tokenStorage.setUserId('user_notes_test');
      final client = SyncStoreClient(
        baseUrl: 'http://localhost:8080',
        tokenStorage: tokenStorage,
      );

      final repoCtrl = RepoController(client);
      await repoCtrl.ensureInitialization();

      // 1. 新增笔记本
      const newRepo = Repo(name: '我的工作笔记本', status: 'active');
      repoCtrl.addData(newRepo);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final repoRows = await db.query('repo');
      expect(repoRows.length, equals(1));
      expect(repoRows.first['body'], contains('我的工作笔记本'));

      final outboxList = await OutboxDao.getPending(db);
      print('Outbox items after add repo: ${outboxList.map((e) => '${e.tableName}:${e.entityId}:${e.op}').toList()}');
      expect(outboxList.length, equals(1));
      expect(outboxList.first.tableName, equals('repo'));
      expect(outboxList.first.op, equals('PUT'));

      final repoId = repoRows.first['id'] as String;

      // 2. 新增笔记 Post
      final postCtrl = PostController(client);
      await postCtrl.ensureInitialization();

      final newPost = Post(repoId: repoId, title: '周报', content: '完成了所有修复任务', category: 'general');
      postCtrl.addData(newPost);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final postRows = await db.query('post');
      expect(postRows.length, equals(1));
      expect(postRows.first['body'], contains('周报'));

      final postOutbox = await OutboxDao.getPending(db);
      expect(postOutbox.length, equals(2));
      expect(postOutbox.last.tableName, equals('post'));
      expect(postOutbox.last.op, equals('PUT'));

      final postId = postRows.first['id'] as String;

      // 3. 删除 Post
      postCtrl.deleteData(postId);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final remainingPosts = await db.query('post', where: 'id = ?', whereArgs: [postId]);
      expect(remainingPosts.isEmpty, isTrue);

      final finalOutbox = await OutboxDao.getPending(db);
      expect(finalOutbox.length, equals(3));
      expect(finalOutbox.last.tableName, equals('post'));
      expect(finalOutbox.last.op, equals('DELETE'));

      await db.close();
      LocalFirstDB.setMockDb(null);
    });
  });
}
