import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/task_repository.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/presentation/task/task_history_view.dart';
import 'package:xbb/presentation/task/task_providers.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-2.2: 恢复归档分段分页加载与历史管理', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late TaskRepository taskRepo;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      taskRepo = TaskRepository(db: db, changeNotifier: dbChangeNotifier);
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('archiveActiveCheckList 提取已完成任务为历史段落，活跃工作区保留未完成任务', () async {
      // 1. 添加3个任务
      await taskRepo.addTask('未完成任务A', 'user-alice');
      await taskRepo.addTask('待完成任务B', 'user-alice');
      await taskRepo.addTask('未完成任务C', 'user-alice');

      final activeBefore = await taskRepo.getOrCreateActiveCheckList('user-alice');
      final itemsBefore = decodeTaskItems(activeBefore.body.tasks);
      expect(itemsBefore.length, equals(3));

      // 2. 将任务B标记为完成
      await taskRepo.toggleTaskDone(itemsBefore[1].id, 'user-alice');

      // 3. 执行归档
      await taskRepo.archiveActiveCheckList('user-alice');

      // 4. 验证活跃清单只保留未完成任务（A和C）
      final activeAfter = await taskRepo.getOrCreateActiveCheckList('user-alice');
      final itemsAfter = decodeTaskItems(activeAfter.body.tasks);
      expect(itemsAfter.length, equals(2));
      expect(itemsAfter.map((t) => t.content).toList(), equals(['未完成任务A', '未完成任务C']));
      expect(itemsAfter[0].sortOrder, equals(0));
      expect(itemsAfter[1].sortOrder, equals(1));

      // 5. 验证归档历史生成了包含任务B的段落
      final archivedList = await taskRepo.watchArchivedSegments(page: 1, pageSize: 10).first;
      expect(archivedList.length, equals(1));
      final archivedSegment = archivedList.first;
      expect(archivedSegment.body.archived, isTrue);
      expect(archivedSegment.body.archivedAt, isNotNull);
      final archivedTasks = decodeTaskItems(archivedSegment.body.tasks);
      expect(archivedTasks.length, equals(1));
      expect(archivedTasks.first.content, equals('待完成任务B'));
      expect(archivedTasks.first.done, isTrue);
    });

    test('watchArchivedSegments 分页查询与 watchArchivedSegmentsCumulative 累加', () async {
      final now = DateTime.now();
      // 创建3个归档段落
      for (var i = 1; i <= 3; i++) {
        final item = DataItem<CheckList>(
          'archive-$i',
          now.add(Duration(minutes: i)),
          now.add(Duration(minutes: i)),
          'user-alice',
          null,
          null,
          body: CheckList(
            tasks: jsonEncode([
              {'id': 't-$i', 'content': '任务 $i', 'done': true, 'last_modified_at': now.toIso8601String(), 'sort_order': 0}
            ]),
            archived: true,
            archivedAt: now.add(Duration(minutes: i)),
          ),
          syncStatus: SyncStatus.pending,
        );
        await taskRepo.saveCheckList(item);
      }

      // 分页验证 page 1, pageSize 2
      final page1 = await taskRepo.watchArchivedSegments(page: 1, pageSize: 2).first;
      expect(page1.length, equals(2));

      // 累加查询 limit 2 -> 返回2条
      final cum2 = await taskRepo.watchArchivedSegmentsCumulative(limit: 2).first;
      expect(cum2.length, equals(2));

      // 累加查询 limit 5 -> 返回全部3条
      final cumAll = await taskRepo.watchArchivedSegmentsCumulative(limit: 5).first;
      expect(cumAll.length, equals(3));
    });

    test('deleteArchivedSegment 物理删除本地记录并在 Outbox 产生 delete 事件', () async {
      final now = DateTime.now();
      final item = DataItem<CheckList>(
        'seg-to-delete',
        now,
        now,
        'user-alice',
        null,
        null,
        body: CheckList(
          tasks: '[]',
          archived: true,
          archivedAt: now,
        ),
        syncStatus: SyncStatus.synced,
      );
      await taskRepo.saveCheckList(item);

      // 验证存在
      var count = await taskRepo.getArchivedSegmentsTotalCount();
      expect(count, equals(1));

      // 删除该历史段
      await taskRepo.deleteArchivedSegment('seg-to-delete');

      // 验证 SQLite check_list 表已删除
      count = await taskRepo.getArchivedSegmentsTotalCount();
      expect(count, equals(0));

      // 验证 Outbox 表生成了 DELETE 记录
      final outboxRows = await db.query(
        'outbox',
        where: 'table_name = ? AND entity_id = ? AND op = ?',
        whereArgs: ['check_list', 'seg-to-delete', 'DELETE'],
      );
      expect(outboxRows.length, equals(1));
    });

    testWidgets('TaskHistoryView 展示段落卡片，支持独立展开折叠与删除确认对话框', (tester) async {
      final now = DateTime.now();
      final item = DataItem<CheckList>(
        'segment-view-test',
        now,
        now,
        'user-alice',
        null,
        null,
        body: CheckList(
          tasks: jsonEncode([
            {'id': 'item-1', 'content': '已完成的历史任务1', 'done': true, 'last_modified_at': now.toIso8601String(), 'sort_order': 0}
          ]),
          archived: true,
          archivedAt: now,
        ),
        syncStatus: SyncStatus.synced,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            archivedSegmentsCumulativeProvider(5).overrideWith((ref) => Stream.value([item])),
            taskRepositoryProvider.overrideWithValue(taskRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: TaskHistoryView(initialPageSize: 5),
            ),
          ),
        ),
      );

      await tester.pump();

      // 应该展示包含 "包含 1 项任务" 的段落卡片
      expect(find.textContaining('包含 1 项任务'), findsOneWidget);

      // 展开前不显示子任务文本
      expect(find.text('已完成的历史任务1'), findsNothing);

      // 点击展开段落
      await tester.tap(find.textContaining('包含 1 项任务'));
      await tester.pump();

      // 展开后应该展示具体子任务内容
      expect(find.text('已完成的历史任务1'), findsOneWidget);

      // 点击删除按钮弹出二次确认框
      await tester.tap(find.byTooltip('删除此历史段落'));
      await tester.pump();

      expect(find.text('删除历史记录'), findsOneWidget);
      expect(find.text('确认删除此段归档历史吗？删除后本地与云端将同步永久移除。'), findsOneWidget);

      // 点击取消
      await tester.tap(find.text('取消'));
      await tester.pump();
      expect(find.text('删除历史记录'), findsNothing);
    });
  });
}
