import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/clipboard_repository.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/presentation/clipboard/clipboard_date_group_view.dart';
import 'package:xbb/presentation/clipboard/clipboard_overview_card.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-5.3: 恢复卡片原位就地编辑与统计概览卡片', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late ClipboardRepository clipboardRepo;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      clipboardRepo = ClipboardRepository(db: db, changeNotifier: dbChangeNotifier);
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('updateEntryText 修改 localOnly 条目仅更新本地表，不写入 Outbox', () async {
      final now = DateTime.now();
      await db.insert('clipboard_history_entry', {
        'id': 'clip-local-1',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'owner': 'user-1',
        'parent_id': null,
        'sync_status': 'local_only',
        'color_tag': 'default',
        'body': jsonEncode(ClipboardHistoryEntry(data: '原始文本', capturedAt: now, localOnly: true).toJson()),
      });

      final changed = await clipboardRepo.updateEntryText('clip-local-1', '修改后的新文本');
      expect(changed, isTrue);

      // 验证本地表已更新
      final rows = await db.query('clipboard_history_entry', where: 'id = ?', whereArgs: ['clip-local-1']);
      final body = jsonDecode(rows.first['body'] as String);
      expect(body['data'], '修改后的新文本');

      // 验证 Outbox 无此记录
      final outbox = await db.query('outbox', where: 'entity_id = ?', whereArgs: ['clip-local-1']);
      expect(outbox, isEmpty);
    });

    test('updateEntryText 修改非 localOnly (已同步) 条目同时写入本地表与 Outbox PUT', () async {
      final now = DateTime.now();
      await db.insert('clipboard_history_entry', {
        'id': 'clip-synced-1',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'owner': 'user-1',
        'parent_id': null,
        'sync_status': 'synced',
        'color_tag': 'default',
        'body': jsonEncode(ClipboardHistoryEntry(data: '旧云端文本', capturedAt: now, localOnly: false).toJson()),
      });

      final changed = await clipboardRepo.updateEntryText('clip-synced-1', '新云端文本');
      expect(changed, isTrue);

      final rows = await db.query('clipboard_history_entry', where: 'id = ?', whereArgs: ['clip-synced-1']);
      final body = jsonDecode(rows.first['body'] as String);
      expect(body['data'], '新云端文本');

      // 验证 Outbox 产生了 PUT 事件
      final outbox = await db.query('outbox', where: 'entity_id = ?', whereArgs: ['clip-synced-1']);
      expect(outbox.length, 1);
      expect(outbox.first['op'], 'PUT');
    });

    test('clipboardOverviewStatsProvider 正确计算总数、仅本地数与已同步数', () async {
      final now = DateTime.now();
      final items = [
        DataItem<ClipboardHistoryEntry>(
          'id-1',
          now,
          now,
          'user1',
          null,
          null,
          body: ClipboardHistoryEntry(data: '本地 1', capturedAt: now, localOnly: true),
        ),
        DataItem<ClipboardHistoryEntry>(
          'id-2',
          now,
          now,
          'user1',
          null,
          null,
          body: ClipboardHistoryEntry(data: '本地 2', capturedAt: now, localOnly: true),
        ),
        DataItem<ClipboardHistoryEntry>(
          'id-3',
          now,
          now,
          'user1',
          null,
          null,
          body: ClipboardHistoryEntry(data: '云端 1', capturedAt: now, localOnly: false),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          clipboardEntriesStreamProvider.overrideWith((ref) => Stream.value(items)),
        ],
      );

      await container.read(clipboardEntriesStreamProvider.future);

      final stats = container.read(clipboardOverviewStatsProvider);
      expect(stats.total, 3);
      expect(stats.localOnly, 2);
      expect(stats.synced, 1);

      container.dispose();
    });

    testWidgets('ClipboardOverviewCard 正确渲染三维统计数值', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clipboardOverviewStatsProvider.overrideWithValue(
              const ClipboardOverviewStats(total: 10, localOnly: 7, synced: 3),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClipboardOverviewCard(),
            ),
          ),
        ),
      );

      expect(find.text('剪贴板概览'), findsOneWidget);
      expect(find.text('总数'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('仅本地'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('已同步'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('ClipboardEntryCard 点击编辑按钮切换为编辑态，点击取消退出编辑态', (tester) async {
      final now = DateTime.now();
      final item = DataItem<ClipboardHistoryEntry>(
        'edit-item-1',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '可以被编辑的文本', capturedAt: now, localOnly: true),
      );

      final container = ProviderContainer(
        overrides: [
          clipboardRepositoryProvider.overrideWithValue(clipboardRepo),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ClipboardEntryCard(item: item),
                ],
              ),
            ),
          ),
        ),
      );

      // 非编辑态展示原文本与“编辑”按钮
      expect(find.text('可以被编辑的文本'), findsOneWidget);
      expect(find.text('编辑'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      // 点击“编辑”按钮进入编辑态
      await tester.tap(find.text('编辑'));
      await tester.pump();

      // 验证状态变为编辑态
      expect(container.read(editingClipboardIdProvider), equals('edit-item-1'));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      // 点击“取消”按钮退出编辑态
      await tester.tap(find.text('取消'));
      await tester.pump();

      expect(container.read(editingClipboardIdProvider), isNull);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('编辑'), findsOneWidget);

      container.dispose();
    });
  });
}
