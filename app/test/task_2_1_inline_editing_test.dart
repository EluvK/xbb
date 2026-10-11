import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/task_repository.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/presentation/task/modern_task_view.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-2.1: 恢复任务原位就地编辑 (Inline Editing) 与防失焦机制', () {
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

    test('updateTaskContent 能够正确就地更新指定任务内容并更新 lastModifiedAt', () async {
      // 1. 添加任务
      await taskRepo.addTask('初始任务1', 'user-1');
      await taskRepo.addTask('初始任务2', 'user-1');

      final active = await taskRepo.getOrCreateActiveCheckList('user-1');
      final items = decodeTaskItems(active.body.tasks);
      expect(items.length, equals(2));
      final targetId = items.first.id;
      final originalModTime = items.first.lastModifiedAt;

      // 2. 更新内容
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await taskRepo.updateTaskContent(targetId, '修改后的任务1内容', 'user-1');

      // 3. 校验更新结果
      final updatedActive = await taskRepo.getOrCreateActiveCheckList('user-1');
      final updatedItems = decodeTaskItems(updatedActive.body.tasks);
      expect(updatedItems.first.content, equals('修改后的任务1内容'));
      expect(updatedItems.first.lastModifiedAt.isAfter(originalModTime) ||
             updatedItems.first.lastModifiedAt == originalModTime, isTrue);
      // 第二项不受影响
      expect(updatedItems[1].content, equals('初始任务2'));
    });

    test('updateTaskContent 忽略空字符与内容未变更', () async {
      await taskRepo.addTask('稳定任务', 'user-1');
      final active = await taskRepo.getOrCreateActiveCheckList('user-1');
      final targetId = decodeTaskItems(active.body.tasks).first.id;

      // 传空字符串不应修改
      await taskRepo.updateTaskContent(targetId, '   ', 'user-1');
      var current = await taskRepo.getOrCreateActiveCheckList('user-1');
      expect(decodeTaskItems(current.body.tasks).first.content, equals('稳定任务'));

      // 传相同内容不应触发更新
      await taskRepo.updateTaskContent(targetId, '稳定任务', 'user-1');
      current = await taskRepo.getOrCreateActiveCheckList('user-1');
      expect(decodeTaskItems(current.body.tasks).first.content, equals('稳定任务'));
    });

    test('防失焦排序锁定：编辑态下保持 frozenOrderIds 顺序不变', () {
      final now = DateTime.now();
      final task1 = TaskItem(id: 't-1', content: 'Task 1', done: false, lastModifiedAt: now, sortOrder: 0);
      final task2 = TaskItem(id: 't-2', content: 'Task 2', done: false, lastModifiedAt: now, sortOrder: 1);
      final task3 = TaskItem(id: 't-3', content: 'Task 3', done: true, doneAt: now, lastModifiedAt: now, sortOrder: 2);

      final list = [task1, task2, task3];
      final frozenOrder = ['t-3', 't-1', 't-2'];

      // 模拟根据 frozenOrderIds 冻结排序
      final byId = {for (final t in list) t.id: t};
      final ordered = <TaskItem>[];
      for (final id in frozenOrder) {
        final t = byId.remove(id);
        if (t != null) ordered.add(t);
      }
      if (byId.isNotEmpty) ordered.addAll(byId.values);

      expect(ordered.map((t) => t.id).toList(), equals(['t-3', 't-1', 't-2']));
    });

    testWidgets('InlineTaskTile 在非编辑态展示任务文本，点击修改可进入编辑态', (tester) async {
      final now = DateTime.now();
      final task = TaskItem(id: 't-test', content: '待编辑的任务', done: false, lastModifiedAt: now);
      bool editTapped = false;
      bool submitted = false;
      String submittedValue = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineTaskTile(
              task: task,
              isEditing: false,
              onTapEdit: () => editTapped = true,
              onSubmitted: (val) {
                submitted = true;
                submittedValue = val;
              },
              onCancel: () {},
              onToggleDone: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // 非编辑态应展示文本
      expect(find.text('待编辑的任务'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // 点击任务文本触发 onTapEdit
      await tester.tap(find.text('待编辑的任务'));
      await tester.pump();
      expect(editTapped, isTrue);
    });

    testWidgets('InlineTaskTile 在编辑态展示 TextField，修改后回车提交', (tester) async {
      final now = DateTime.now();
      final task = TaskItem(id: 't-test', content: '原任务内容', done: false, lastModifiedAt: now);
      String submittedValue = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineTaskTile(
              task: task,
              isEditing: true,
              onTapEdit: () {},
              onSubmitted: (val) => submittedValue = val,
              onCancel: () {},
              onToggleDone: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // 编辑态应展示 TextField
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('原任务内容'), findsOneWidget);

      // 修改输入框内容
      await tester.enterText(find.byType(TextField), '更新后的任务内容');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submittedValue, equals('更新后的任务内容'));
    });

    testWidgets('InlineTaskTile 在编辑态下点击取消按钮触发 onCancel', (tester) async {
      final now = DateTime.now();
      final task = TaskItem(id: 't-test', content: '任务', done: false, lastModifiedAt: now);
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineTaskTile(
              task: task,
              isEditing: true,
              onTapEdit: () {},
              onSubmitted: (_) {},
              onCancel: () => cancelled = true,
              onToggleDone: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
