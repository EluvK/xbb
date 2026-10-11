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
import 'package:xbb/presentation/checkin/modern_checkin_view.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-4.3: 恢复防误触二次确认与核心业务校验规则', () {
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

    test('CheckinRepository 业务校验：禁止预打未来日期与禁止补打创建前的历史日期', () async {
      // 1. 创建事件，创建日期为 2026-10-10
      await checkinRepo.createEvent(
        name: '俯卧撑',
        description: '每日 50 个',
        colorValue: Colors.deepOrange.value,
        currentUserId: 'user-001',
      );
      final events = await checkinRepo.watchEvents().first;
      final eventId = events.first.id;

      // 2. 校验一：禁止预打未来日期 (ADR-0003)
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(
        () => checkinRepo.checkin(
          eventId: eventId,
          targetDate: tomorrow,
          currentUserId: 'user-001',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('ADR-0003'),
        )),
      );

      // 3. 校验二：禁止补打创建日期 (events.first.createdAt) 之前的历史日期
      final dayBeforeCreation = events.first.createdAt.subtract(const Duration(days: 2));
      expect(
        () => checkinRepo.checkin(
          eventId: eventId,
          targetDate: dayBeforeCreation,
          currentUserId: 'user-001',
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('不能补打事件创建前的日期'),
        )),
      );

      // 4. 正常打卡：创建日期当天或之后被允许
      final ok = await checkinRepo.checkin(
        eventId: eventId,
        targetDate: events.first.createdAt,
        currentUserId: 'user-001',
      );
      expect(ok, isTrue);
    });

    testWidgets('ModernCheckinView 撤销打卡必须二次确认，点取消不影响数据，点撤销才真正删除', (tester) async {
      final now = DateTime.now();
      final todayKey = CheckinRepository.formatLocalDayKey(now);

      final events = [
        DataItem<CheckinEvent>(
          'ev-pushups',
          now,
          now,
          'user-001',
          null,
          null,
          body: const CheckinEvent(name: '俯卧撑', description: '', colorValue: 0xFFFF5722),
          syncStatus: SyncStatus.synced,
        ),
      ];

      final records = [
        DataItem<CheckinRecord>(
          'rec-1',
          now,
          now,
          'user-001',
          'ev-pushups',
          null,
          body: CheckinRecord(
            eventId: 'ev-pushups',
            createdAtUtc: now.toUtc(),
            localDayKey: todayKey,
            timezoneOffsetMinutes: 0,
          ),
          syncStatus: SyncStatus.synced,
        ),
      ];

      bool undoCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            dbChangeNotifierProvider.overrideWithValue(dbChangeNotifier),
            checkinEventsStreamProvider.overrideWith((ref) => Stream.value(events)),
            checkinRecordsStreamProvider.overrideWith((ref) => Stream.value(records)),
            checkinMonthlyCountsStreamProvider.overrideWith((ref) => Stream.value({'ev-pushups': 1})),
          ],
          child: const MaterialApp(
            home: ModernCheckinView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 1. 点击已打卡的卡片项
      expect(find.widgetWithText(ModernCard, '俯卧撑'), findsOneWidget);
      await tester.tap(find.widgetWithText(ModernCard, '俯卧撑'));
      await tester.pumpAndSettle();

      // 2. 验证弹出二次确认对话框 (Undo confirmation dialog)
      expect(find.text('撤销打卡'), findsOneWidget);
      expect(find.text('确认撤销「俯卧撑」的打卡记录吗？'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('撤销'), findsOneWidget);

      // 3. 点击“取消”，对话框关闭，不执行任何撤销删除
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(find.text('撤销打卡'), findsNothing);
      expect(find.widgetWithText(ModernCard, '俯卧撑'), findsOneWidget);

      // 4. 再次点击，这次点击“撤销”
      await tester.tap(find.widgetWithText(ModernCard, '俯卧撑'));
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(FilledButton, '撤销');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('确认撤销「俯卧撑」的打卡记录吗？'), findsNothing);
    });
  });
}
