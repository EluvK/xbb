import 'dart:convert';
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
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-4.2: 恢复专属多色日历点与打卡文字备注 (Note)', () {
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

    test('checkin 支持持久化文字备注 Note 与自定义发生时间', () async {
      await checkinRepo.createEvent(
        name: '夜跑',
        description: '操场 10 圈',
        colorValue: Colors.deepPurple.value,
        currentUserId: 'user-001',
      );
      final events = await checkinRepo.watchEvents().first;
      final eventId = events.first.id;

      final customTime = DateTime(2026, 10, 11, 20, 45);
      final noteText = '今日跑步 5 公里，心率平稳状态极佳';

      final ok = await checkinRepo.checkin(
        eventId: eventId,
        targetDate: DateTime(2026, 10, 11),
        currentUserId: 'user-001',
        note: noteText,
        recordTime: customTime,
      );
      expect(ok, isTrue);

      final records = await checkinRepo.watchRecords().first;
      expect(records.length, 1);
      final r = records.first.body;
      expect(r.note, noteText);
      expect(r.createdAtUtc, customTime.toUtc());

      // 验证 SQLite checkin_record 表持久化
      final rows = await db.query('checkin_record', where: 'id = ?', whereArgs: [records.first.id]);
      expect(rows.length, 1);
      final body = jsonDecode(rows.first['body'] as String) as Map<String, dynamic>;
      expect(body['note'], noteText);
    });

    test('updateRecordDetails 支持微调打卡时间与修改文字备注', () async {
      await checkinRepo.createEvent(
        name: '背单词',
        description: 'GRE 50 个',
        colorValue: Colors.indigo.value,
        currentUserId: 'user-001',
        createdAt: DateTime(2026, 10, 1),
      );
      final events = await checkinRepo.watchEvents().first;
      final eventId = events.first.id;

      await checkinRepo.checkin(
        eventId: eventId,
        targetDate: DateTime(2026, 10, 10),
        currentUserId: 'user-001',
        note: '初次打卡',
      );

      final records = await checkinRepo.watchRecords().first;
      final recordId = records.first.id;

      final updatedTime = DateTime(2026, 10, 10, 22, 15);
      final newNote = '复习了 60 个单词，完成 List 12';

      await checkinRepo.updateRecordDetails(
        recordId: recordId,
        recordTime: updatedTime,
        note: newNote,
      );

      final updatedRecords = await checkinRepo.watchRecords().first;
      expect(updatedRecords.first.body.note, newNote);
      expect(updatedRecords.first.body.createdAtUtc, updatedTime.toUtc());
    });

    testWidgets('ModernCheckinView 正确渲染打卡备注 Note、时间并提供编辑入口', (tester) async {
      final now = DateTime.now();
      final ev1Color = Colors.blue.value;
      final ev2Color = Colors.orange.value;

      final events = [
        DataItem<CheckinEvent>(
          'ev-run',
          now,
          now,
          'user-001',
          null,
          null,
          body: CheckinEvent(name: '晨跑', description: '健康生活', colorValue: ev1Color),
          syncStatus: SyncStatus.synced,
        ),
        DataItem<CheckinEvent>(
          'ev-read',
          now,
          now,
          'user-001',
          null,
          null,
          body: CheckinEvent(name: '读书', description: '深度思考', colorValue: ev2Color),
          syncStatus: SyncStatus.synced,
        ),
      ];

      final todayKey = CheckinRepository.formatLocalDayKey(now);
      final records = [
        DataItem<CheckinRecord>(
          'rec-1',
          DateTime(now.year, now.month, now.day, 7, 30),
          DateTime(now.year, now.month, now.day, 7, 30),
          'user-001',
          'ev-run',
          null,
          body: CheckinRecord(
            eventId: 'ev-run',
            createdAtUtc: DateTime(now.year, now.month, now.day, 7, 30).toUtc(),
            localDayKey: todayKey,
            timezoneOffsetMinutes: 0,
            note: '晨跑 5km 状态很好',
          ),
          syncStatus: SyncStatus.synced,
        ),
        DataItem<CheckinRecord>(
          'rec-2',
          DateTime(now.year, now.month, now.day, 21, 15),
          DateTime(now.year, now.month, now.day, 21, 15),
          'user-001',
          'ev-read',
          null,
          body: CheckinRecord(
            eventId: 'ev-read',
            createdAtUtc: DateTime(now.year, now.month, now.day, 21, 15).toUtc(),
            localDayKey: todayKey,
            timezoneOffsetMinutes: 0,
            note: '读完第二章',
          ),
          syncStatus: SyncStatus.synced,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            dbChangeNotifierProvider.overrideWithValue(dbChangeNotifier),
            checkinEventsStreamProvider.overrideWith((ref) => Stream.value(events)),
            checkinRecordsStreamProvider.overrideWith((ref) => Stream.value(records)),
            checkinMonthlyCountsStreamProvider.overrideWith((ref) => Stream.value({'ev-run': 1, 'ev-read': 1})),
          ],
          child: const MaterialApp(
            home: ModernCheckinView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 1. 验证备注文本被渲染在卡片中
      expect(find.text('晨跑 5km 状态很好'), findsOneWidget);
      expect(find.text('读完第二章'), findsOneWidget);

      // 2. 验证完成时间被渲染 (07:30 与 21:15)
      expect(find.text('07:30'), findsOneWidget);
      expect(find.text('21:15'), findsOneWidget);

      // 3. 验证编辑记录按钮存在
      final editButtons = find.byIcon(Icons.edit_outlined);
      expect(editButtons, findsNWidgets(2));

      // 4. 点击编辑按钮弹出编辑记录对话框
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('编辑记录'), findsOneWidget);
      expect(find.text('打卡备注'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);

      // 5. 修改备注并点击取消
      await tester.enterText(find.widgetWithText(TextField, '打卡备注'), '更新后的晨跑心得');
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(find.textContaining('编辑记录'), findsNothing);

      // 6. 验证日历单元格中包含多色彩点阵列 (ev1Color 与 ev2Color)
      final blueDotFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Color(ev1Color);
        }
        return false;
      });
      final orangeDotFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.shape == BoxShape.circle && box.color == Color(ev2Color);
        }
        return false;
      });

      expect(blueDotFinder, findsWidgets);
      expect(orangeDotFinder, findsWidgets);
    });
  });
}
