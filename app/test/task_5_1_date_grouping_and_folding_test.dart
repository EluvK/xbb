import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/presentation/clipboard/clipboard_date_group_view.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';

void main() {
  group('TASK-5.1: 剪贴板按日期自动分组与按天折叠/展开', () {
    test('groupedClipboardEntriesProvider 正确将多条记录按本地日期聚合分组并降序排列', () {
      final now = DateTime.now();
      final todayMorning = DateTime(now.year, now.month, now.day, 9, 30);
      final todayAfternoon = DateTime(now.year, now.month, now.day, 14, 20);
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayEvening = DateTime(yesterday.year, yesterday.month, yesterday.day, 20, 10);
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      final items = [
        DataItem<ClipboardHistoryEntry>(
          'id-1',
          todayMorning,
          todayMorning,
          'user1',
          null,
          null,
          body: ClipboardHistoryEntry(data: 'Today 1', capturedAt: todayMorning, localOnly: true),
        ),
        DataItem<ClipboardHistoryEntry>(
          'id-2',
          todayAfternoon,
          todayAfternoon,
          'user1',
          null,
          null,
          body: ClipboardHistoryEntry(data: 'Today 2', capturedAt: todayAfternoon, localOnly: false),
        ),
        DataItem<ClipboardHistoryEntry>(
          'id-3',
          yesterdayEvening,
          yesterdayEvening,
          'user1',
          null,
          null,
          body: ClipboardHistoryEntry(data: 'Yesterday 1', capturedAt: yesterdayEvening, localOnly: true),
        ),
        DataItem<ClipboardHistoryEntry>(
          'id-4',
          threeDaysAgo,
          threeDaysAgo,
          'user1',
          null,
          null,
          body: ClipboardHistoryEntry(data: 'Old 1', capturedAt: threeDaysAgo, localOnly: true),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          filteredClipboardEntriesProvider.overrideWithValue(items),
        ],
      );

      final groups = container.read(groupedClipboardEntriesProvider);

      expect(groups.length, 3);
      // 第一个组是今天，包含两条，且按时间降序（Today 2 先于 Today 1）
      expect(groups[0].entries.length, 2);
      expect(groups[0].entries[0].body.data, 'Today 2');
      expect(groups[0].entries[1].body.data, 'Today 1');

      // 第二个组是昨天
      expect(groups[1].entries.length, 1);
      expect(groups[1].entries[0].body.data, 'Yesterday 1');

      // 第三个组是三天前
      expect(groups[2].entries.length, 1);
      expect(groups[2].entries[0].body.data, 'Old 1');
    });

    test('clipboardDateHeaderLabel 正确返回“今天”、“昨天”与星期格式', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final todayLabelZh = clipboardDateHeaderLabel(today, isZh: true);
      expect(todayLabelZh.contains('今天'), isTrue);

      final todayLabelEn = clipboardDateHeaderLabel(today, isZh: false);
      expect(todayLabelEn.contains('Today'), isTrue);

      final yesterdayLabelZh = clipboardDateHeaderLabel(yesterday, isZh: true);
      expect(yesterdayLabelZh.contains('昨天'), isTrue);

      final yesterdayLabelEn = clipboardDateHeaderLabel(yesterday, isZh: false);
      expect(yesterdayLabelEn.contains('Yesterday'), isTrue);
    });

    test('collapsedClipboardDatesProvider 正确管理折叠与展开状态', () {
      final container = ProviderContainer();
      final notifier = container.read(collapsedClipboardDatesProvider.notifier);

      expect(container.read(collapsedClipboardDatesProvider), isEmpty);

      notifier.toggle('2026-10-11');
      expect(container.read(collapsedClipboardDatesProvider), contains('2026-10-11'));

      notifier.toggle('2026-10-11');
      expect(container.read(collapsedClipboardDatesProvider), isEmpty);

      notifier.collapseAll(['2026-10-10', '2026-10-11']);
      expect(container.read(collapsedClipboardDatesProvider).length, 2);

      notifier.expandAll();
      expect(container.read(collapsedClipboardDatesProvider), isEmpty);
    });

    testWidgets('ClipboardDateGroupView 能够展开/收起条目并正确展示数量', (tester) async {
      final now = DateTime.now();
      final group = ClipboardDateGroup(
        dateKey: formatClipboardDateKey(now),
        date: DateTime(now.year, now.month, now.day),
        entries: [
          DataItem<ClipboardHistoryEntry>(
            'id-1',
            now,
            now,
            'user1',
            null,
            null,
            body: ClipboardHistoryEntry(data: '测试剪贴板第一条', capturedAt: now, localOnly: true),
          ),
          DataItem<ClipboardHistoryEntry>(
            'id-2',
            now,
            now,
            'user1',
            null,
            null,
            body: ClipboardHistoryEntry(data: '测试剪贴板第二条', capturedAt: now, localOnly: false),
          ),
        ],
      );

      bool isCollapsed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return ClipboardDateGroupView(
                    group: group,
                    isCollapsed: isCollapsed,
                    onToggleCollapse: () {
                      setState(() {
                        isCollapsed = !isCollapsed;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 验证数量显示
      expect(find.text('2'), findsOneWidget);
      expect(find.text('测试剪贴板第一条'), findsOneWidget);
      expect(find.text('测试剪贴板第二条'), findsOneWidget);

      // 点击头部折叠
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 折叠后，第一条与第二条被收起
      final secondCardFinder = find.text('测试剪贴板第一条');
      expect(secondCardFinder, findsNothing);

      // 再次点击头部展开
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('测试剪贴板第一条'), findsOneWidget);
    });
  });
}
