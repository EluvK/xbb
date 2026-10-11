import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/clipboard_repository.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/presentation/clipboard/clipboard_batch_action_bar.dart';
import 'package:xbb/presentation/clipboard/clipboard_date_group_view.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-5.2: 剪贴板多选模式与批量云端同步/批量删除', () {
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

    test('SelectedClipboardIdsNotifier 正确管理选择集与分组全选/取消', () {
      final container = ProviderContainer();
      final notifier = container.read(selectedClipboardIdsProvider.notifier);

      expect(container.read(selectedClipboardIdsProvider), isEmpty);

      notifier.toggle('id-1');
      expect(container.read(selectedClipboardIdsProvider), contains('id-1'));

      notifier.selectGroup(['id-2', 'id-3']);
      expect(container.read(selectedClipboardIdsProvider), containsAll(['id-1', 'id-2', 'id-3']));

      // toggleGroup 当全部已选时取消
      notifier.toggleGroup(['id-2', 'id-3']);
      expect(container.read(selectedClipboardIdsProvider), contains('id-1'));
      expect(container.read(selectedClipboardIdsProvider).contains('id-2'), isFalse);

      // toggleGroup 当未全部已选时全选
      notifier.toggleGroup(['id-1', 'id-2']);
      expect(container.read(selectedClipboardIdsProvider), containsAll(['id-1', 'id-2']));

      notifier.clear();
      expect(container.read(selectedClipboardIdsProvider), isEmpty);

      notifier.setFailedIds(['id-failed']);
      expect(container.read(selectedClipboardIdsProvider), equals({'id-failed'}));
    });

    test('ClipboardRepository.syncSelectedToCloud 跳过已同步项，仅未同步项入队 Outbox', () async {
      // 准备三条记录：两条 localOnly == true，一条 localOnly == false
      final now = DateTime.now();
      final item1 = DataItem<ClipboardHistoryEntry>(
        'clip-1',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '文本一', capturedAt: now, localOnly: true),
      );
      final item2 = DataItem<ClipboardHistoryEntry>(
        'clip-2',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '文本二', capturedAt: now, localOnly: false),
      );
      final item3 = DataItem<ClipboardHistoryEntry>(
        'clip-3',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '文本三', capturedAt: now, localOnly: true),
      );

      // 先存入数据库
      for (final item in [item1, item2, item3]) {
        await db.insert('clipboard_history_entry', {
          'id': item.id,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': item.updatedAt.toIso8601String(),
          'owner': item.owner,
          'parent_id': null,
          'sync_status': item.body.localOnly ? 'local_only' : 'synced',
          'color_tag': 'default',
          'body': jsonEncode(item.body.toJson()),
        });
      }

      // 执行批量同步
      final result = await clipboardRepo.syncSelectedToCloud([item1, item2, item3]);

      expect(result.syncedCount, 2);
      expect(result.skippedCount, 1);
      expect(result.failedCount, 0);

      // 验证 Outbox 中写入了 clip-1 与 clip-3
      final outboxRows = await db.query('outbox', orderBy: 'id ASC');
      final outboxEntityIds = outboxRows.map((r) => r['entity_id']).toList();
      expect(outboxEntityIds, containsAll(['clip-1', 'clip-3']));
      expect(outboxEntityIds.contains('clip-2'), isFalse);

      // 验证本地库对应记录 localOnly 转为 false
      final rows = await db.query('clipboard_history_entry', where: 'id IN (?, ?)', whereArgs: ['clip-1', 'clip-3']);
      for (final row in rows) {
        final body = jsonDecode(row['body'] as String);
        expect(body['local_only'], isFalse);
      }
    });

    test('ClipboardRepository.deleteSelected 批量删除条目（localOnly 本地清除，非 localOnly 写入 DELETE Outbox）', () async {
      final now = DateTime.now();
      final itemLocal = DataItem<ClipboardHistoryEntry>(
        'clip-local',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '纯本地', capturedAt: now, localOnly: true),
      );
      final itemSynced = DataItem<ClipboardHistoryEntry>(
        'clip-synced',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '已同步', capturedAt: now, localOnly: false),
      );

      for (final item in [itemLocal, itemSynced]) {
        await db.insert('clipboard_history_entry', {
          'id': item.id,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': item.updatedAt.toIso8601String(),
          'owner': item.owner,
          'parent_id': null,
          'sync_status': item.body.localOnly ? 'local_only' : 'synced',
          'color_tag': 'default',
          'body': jsonEncode(item.body.toJson()),
        });
      }

      final result = await clipboardRepo.deleteSelected([itemLocal, itemSynced]);

      expect(result.deletedCount, 2);
      expect(result.failedCount, 0);

      // 验证本地表已全被删除
      final remaining = await db.query('clipboard_history_entry');
      expect(remaining, isEmpty);

      // 验证 Outbox 仅为 clip-synced 记录了 DELETE 事件
      final outboxRows = await db.query('outbox');
      expect(outboxRows.length, 1);
      expect(outboxRows.first['entity_id'], 'clip-synced');
      expect(outboxRows.first['op'], 'DELETE');
    });

    testWidgets('UI 集成：全选当天、Checkbox 勾选与底部批量操作栏联动', (tester) async {
      final now = DateTime.now();
      final item1 = DataItem<ClipboardHistoryEntry>(
        'id-1',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '条目 1', capturedAt: now, localOnly: true),
      );
      final item2 = DataItem<ClipboardHistoryEntry>(
        'id-2',
        now,
        now,
        'user-1',
        null,
        null,
        body: ClipboardHistoryEntry(data: '条目 2', capturedAt: now, localOnly: true),
      );

      final group = ClipboardDateGroup(
        dateKey: formatClipboardDateKey(now),
        date: DateTime(now.year, now.month, now.day),
        entries: [item1, item2],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            filteredClipboardEntriesProvider.overrideWithValue([item1, item2]),
            clipboardRepositoryProvider.overrideWithValue(clipboardRepo),
          ],
          child: MaterialApp(
            locale: const Locale('zh', 'CN'),
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: ClipboardDateGroupView(
                      group: group,
                      isCollapsed: false,
                      isZh: true,
                    ),
                  ),
                  const ClipboardBatchActionBar(),
                ],
              ),
            ),
          ),
        ),
      );

      // 初始状态下无选中，底部批量栏不展示已选文本
      expect(find.text('已选择 1 项'), findsNothing);
      expect(find.text('全选当天'), findsOneWidget);

      // 点击“全选当天”
      await tester.tap(find.text('全选当天'));
      await tester.pumpAndSettle();

      // 此时头部变为“取消当天”，底部栏展示“已选择 2 项”
      expect(find.text('取消当天'), findsOneWidget);
      expect(find.text('已选择 2 项'), findsOneWidget);
      expect(find.text('批量备份上云'), findsOneWidget);
      expect(find.text('批量删除'), findsOneWidget);

      // 点击“清空选择”
      await tester.tap(find.text('清空选择'));
      await tester.pumpAndSettle();

      expect(find.text('已选择 2 项'), findsNothing);
      expect(find.text('全选当天'), findsOneWidget);
    });
  });
}
