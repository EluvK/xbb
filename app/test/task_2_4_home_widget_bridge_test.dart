import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/task_repository.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/presentation/settings/modern_settings_view.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-2.4: 重新对接系统桌面小部件 (HomeWidget Bridge)', () {
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

    test('buildSnapshotFromTasks 正确构建桌面小部件待办数据快照', () {
      final now = DateTime.now();

      // 1. 空任务测试
      final emptySnapshot = TaskWidgetBridge.buildSnapshotFromTasks([]);
      expect(emptySnapshot.state, equals(taskWidgetStateEmpty));
      expect(emptySnapshot.totalCount, equals(0));
      expect(emptySnapshot.unfinishedCount, equals(0));
      expect(emptySnapshot.items, isEmpty);

      // 2. 混合任务测试
      final tasks = [
        TaskItem(id: 't-1', content: '未完成任务 1', done: false, lastModifiedAt: now, sortOrder: 0),
        TaskItem(id: 't-2', content: '已完成任务 2', done: true, doneAt: now, lastModifiedAt: now, sortOrder: 1),
        TaskItem(id: 't-3', content: '未完成任务 3', done: false, lastModifiedAt: now, sortOrder: 2),
      ];

      final readySnapshot = TaskWidgetBridge.buildSnapshotFromTasks(tasks);
      expect(readySnapshot.state, equals(taskWidgetStateReady));
      expect(readySnapshot.totalCount, equals(3));
      expect(readySnapshot.unfinishedCount, equals(2));
      expect(readySnapshot.items.length, equals(2));
      expect(readySnapshot.items[0].content, equals('未完成任务 1'));
      expect(readySnapshot.items[1].content, equals('未完成任务 3'));

      // 3. 校验 JSON 结构与原生接口契约
      final json = readySnapshot.toJson();
      expect(json['state'], equals('ready'));
      expect(json['total_count'], equals(3));
      expect(json['unfinished_count'], equals(2));
      expect(json['items'], isA<List>());
      expect((json['items'] as List).length, equals(2));

      // 4. 全部完成任务测试
      final allDoneTasks = [
        TaskItem(id: 't-1', content: '任务1', done: true, doneAt: now, lastModifiedAt: now),
      ];
      final allDoneSnapshot = TaskWidgetBridge.buildSnapshotFromTasks(allDoneTasks);
      expect(allDoneSnapshot.state, equals(taskWidgetStateEmpty));
      expect(allDoneSnapshot.totalCount, equals(1));
      expect(allDoneSnapshot.unfinishedCount, equals(0));
    });

    test('TaskRepository 写入后能够基于 SQLite 状态构建最新的桌面小部件快照', () async {
      await taskRepo.addTask('桌面小部件待办事项', 'user-test');
      final active = await taskRepo.getOrCreateActiveCheckList('user-test');
      final items = decodeTaskItems(active.body.tasks);

      final snapshot = TaskWidgetBridge.buildSnapshotFromTasks(items);
      expect(snapshot.state, equals(taskWidgetStateReady));
      expect(snapshot.unfinishedCount, equals(1));
      expect(snapshot.items.first.content, equals('桌面小部件待办事项'));

      // 勾选完成后再构建
      await taskRepo.toggleTaskDone(items.first.id, 'user-test');
      final activeDone = await taskRepo.getOrCreateActiveCheckList('user-test');
      final itemsDone = decodeTaskItems(activeDone.body.tasks);

      final snapshotDone = TaskWidgetBridge.buildSnapshotFromTasks(itemsDone);
      expect(snapshotDone.state, equals(taskWidgetStateEmpty));
      expect(snapshotDone.unfinishedCount, equals(0));
    });

    testWidgets('ModernSettingsView 展示桌面小部件卡片并支持点击引导对话框', (tester) async {
      // 模拟 MethodChannel 返回 false (不支持系统 pin 的平台或返回 false)
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.eluvk.xbb/task_widget'),
        (call) async {
          if (call.method == 'requestPinWidget') {
            return false;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ModernSettingsView(),
          ),
        ),
      );

      await tester.pump();

      // 滚动到底部找到桌面小部件卡片
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();

      expect(find.text('桌面小部件 (Home Widget)'), findsOneWidget);
      expect(find.text('添加到桌面小部件'), findsOneWidget);

      // 点击添加到桌面小部件按钮
      await tester.tap(find.text('添加到桌面小部件'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 应弹出添加桌面小部件指引对话框
      expect(find.text('添加桌面小部件指引'), findsOneWidget);
      expect(find.textContaining('长按空白处，在弹出的菜单中选择「微件」或「小部件 (Widgets)」'), findsOneWidget);

      // 点击“我知道了”关闭弹窗
      await tester.tap(find.text('我知道了'));
      await tester.pumpAndSettle();
      expect(find.text('添加桌面小部件指引'), findsNothing);
    });
  });
}
