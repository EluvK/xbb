import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/checkin_repository.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/presentation/checkin/checkin_providers.dart';
import 'package:xbb/presentation/checkin/event_filter_bar.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-4.1: 恢复事件横向过滤栏 (EventListBar) 与月度统计', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late CheckinRepository checkinRepo;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      checkinRepo = CheckinRepository(db: db, changeNotifier: dbChangeNotifier);
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('getMonthlyCheckinCounts 准确统计当月各事件打卡次数，且排除跨月记录', () async {
      // 1. 创建两个打卡事件
      await checkinRepo.createEvent(
        name: '晨跑',
        description: '每天早上 3 公里',
        colorValue: Colors.blue.value,
        currentUserId: 'user-001',
        createdAt: DateTime(2026, 9, 1),
      );
      await checkinRepo.createEvent(
        name: '阅读',
        description: '每天睡前半小时',
        colorValue: Colors.amber.value,
        currentUserId: 'user-001',
        createdAt: DateTime(2026, 9, 1),
      );

      final events = await checkinRepo.watchEvents().first;
      expect(events.length, 2);
      final runEventId = events.firstWhere((e) => e.body.name == '晨跑').id;
      final readEventId = events.firstWhere((e) => e.body.name == '阅读').id;

      // 2. 模拟打卡记录：
      // 2026-10-01 打卡 晨跑
      // 2026-10-02 打卡 晨跑
      // 2026-10-02 打卡 阅读
      // 2026-09-30 打卡 晨跑 (上个月)
      await checkinRepo.checkin(
        eventId: runEventId,
        targetDate: DateTime(2026, 10, 1),
        currentUserId: 'user-001',
      );
      await checkinRepo.checkin(
        eventId: runEventId,
        targetDate: DateTime(2026, 10, 2),
        currentUserId: 'user-001',
      );
      await checkinRepo.checkin(
        eventId: readEventId,
        targetDate: DateTime(2026, 10, 2),
        currentUserId: 'user-001',
      );
      await checkinRepo.checkin(
        eventId: runEventId,
        targetDate: DateTime(2026, 9, 30),
        currentUserId: 'user-001',
      );

      // 3. 查询 2026 年 10 月的统计
      final countsOct = await checkinRepo.getMonthlyCheckinCounts(2026, 10);
      expect(countsOct[runEventId], 2);
      expect(countsOct[readEventId], 1);

      // 4. 查询 2026 年 9 月的统计
      final countsSep = await checkinRepo.getMonthlyCheckinCounts(2026, 9);
      expect(countsSep[runEventId], 1);
      expect(countsSep[readEventId], isNull);
    });

    test('watchMonthlyCheckinCounts 随打卡与撤销打卡动作即时推进响应式统计', () async {
      await checkinRepo.createEvent(
        name: '冥想',
        description: '深呼吸',
        colorValue: Colors.teal.value,
        currentUserId: 'user-001',
        createdAt: DateTime(2026, 9, 1),
      );
      final events = await checkinRepo.watchEvents().first;
      final eventId = events.first.id;

      // 首次打卡
      await checkinRepo.checkin(
        eventId: eventId,
        targetDate: DateTime(2026, 10, 5),
        currentUserId: 'user-001',
      );
      final count1 = await checkinRepo.watchMonthlyCheckinCounts(2026, 10).first;
      expect(count1[eventId], 1);

      // 撤销打卡
      await checkinRepo.undoCheckin(
        eventId: eventId,
        dayKey: '2026-10-05',
      );
      final count2 = await checkinRepo.watchMonthlyCheckinCounts(2026, 10).first;
      expect(count2[eventId] ?? 0, 0);
    });

    testWidgets('EventFilterBar 正确呈现全部/单项事件及本月次数，支持单选/多选/全选联动', (tester) async {
      final now = DateTime(2026, 10, 10);
      final events = [
        DataItem<CheckinEvent>(
          'ev-1',
          now,
          now,
          'user-1',
          null,
          null,
          body: const CheckinEvent(name: '健身', description: '', colorValue: 0xFF2196F3),
          syncStatus: SyncStatus.synced,
        ),
        DataItem<CheckinEvent>(
          'ev-2',
          now,
          now,
          'user-1',
          null,
          null,
          body: const CheckinEvent(name: '早起', description: '', colorValue: 0xFFFF9800),
          syncStatus: SyncStatus.synced,
        ),
      ];

      final monthlyCounts = {
        'ev-1': 5,
        'ev-2': 12,
      };

      Set<String> currentSelected = {};

      Widget buildWidget(Set<String> selected) {
        return MaterialApp(
          home: Scaffold(
            body: EventFilterBar(
              events: events,
              monthlyCounts: monthlyCounts,
              selectedEventIds: selected,
              onFilterChanged: (newSet) {
                currentSelected = newSet;
              },
            ),
          ),
        );
      }

      // 1. 初次渲染，默认显示全部
      await tester.pumpWidget(buildWidget(currentSelected));
      await tester.pumpAndSettle();

      expect(find.text('全部'), findsOneWidget);
      expect(find.text('健身'), findsOneWidget);
      expect(find.text('5次'), findsOneWidget);
      expect(find.text('早起'), findsOneWidget);
      expect(find.text('12次'), findsOneWidget);

      // 2. 点击“健身”进入单项过滤
      await tester.tap(find.widgetWithText(FilterChip, '全部').first, warnIfMissed: false);
      await tester.tap(find.widgetWithText(FilterChip, '健身'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(currentSelected, {'ev-1'});

      // 3. 再次在过滤态下点击“早起”，转为多选模式（同时包含 ev-1 与 ev-2，即恢复全选）
      await tester.pumpWidget(buildWidget(currentSelected));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, '早起'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(currentSelected.contains('ev-1'), isTrue);
      expect(currentSelected.contains('ev-2'), isTrue);

      // 4. 点击“全部”按钮恢复全部状态
      await tester.tap(find.widgetWithText(FilterChip, '全部'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(currentSelected.length, 2);
    });
  });
}
