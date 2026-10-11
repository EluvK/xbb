import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/checkin_widget.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/checkin_repository.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/presentation/checkin/edit_checkin_event_dialog.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier() : super(const AuthState(userId: 'user-001', isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-4.4: 完善事件管理（编辑/颜色挑选/级联删除）与桌面插件', () {
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

    test('updateEvent 正确修改事件名称、描述与专属颜色并写入 Outbox', () async {
      await checkinRepo.createEvent(
        name: '瑜伽',
        description: '晨间拉伸',
        colorValue: Colors.purple.value,
        currentUserId: 'user-001',
      );
      final events = await checkinRepo.watchEvents().first;
      final eventId = events.first.id;

      // 修改事件
      final newColor = Colors.cyan.value;
      await checkinRepo.updateEvent(
        eventId: eventId,
        name: '普拉提',
        description: '核心力量训练',
        colorValue: newColor,
        currentUserId: 'user-001',
      );

      final updatedEvents = await checkinRepo.watchEvents().first;
      expect(updatedEvents.first.body.name, '普拉提');
      expect(updatedEvents.first.body.description, '核心力量训练');
      expect(updatedEvents.first.body.colorValue, newColor);

      // 验证 Outbox 表中有 PUT 记录
      final outboxRows = await db.query(
        'outbox',
        where: 'table_name = ? AND entity_id = ?',
        whereArgs: ['checkin_event', eventId],
      );
      expect(outboxRows.isNotEmpty, isTrue);
    });

    test('deleteEvent 执行级联删除事务：彻底清除事件及所有关联打卡记录，并在 Outbox 产生 DELETE 事件', () async {
      // 1. 创建事件与打卡记录
      await checkinRepo.createEvent(
        name: '游泳',
        description: '每周三次',
        colorValue: Colors.blue.value,
        currentUserId: 'user-001',
      );
      final events = await checkinRepo.watchEvents().first;
      final eventId = events.first.id;

      final today = DateTime.now();
      await checkinRepo.checkin(
        eventId: eventId,
        targetDate: today,
        currentUserId: 'user-001',
        note: '游了 1000 米',
      );

      final recordsBefore = await checkinRepo.watchRecords().first;
      expect(recordsBefore.length, 1);
      final recordId = recordsBefore.first.id;

      // 2. 级联删除该事件
      await checkinRepo.deleteEvent(eventId);

      // 3. 验证事件被清除
      final eventsAfter = await checkinRepo.watchEvents().first;
      expect(eventsAfter.isEmpty, isTrue);

      // 4. 验证关联打卡记录被级联清除
      final recordsAfter = await checkinRepo.watchRecords().first;
      expect(recordsAfter.isEmpty, isTrue);

      // 5. 验证 Outbox 表中同时存在事件与记录的 DELETE 变更事件
      final outboxDeleteRecords = await db.query(
        'outbox',
        where: 'op = ? AND entity_id IN (?, ?)',
        whereArgs: ['DELETE', eventId, recordId],
      );
      expect(outboxDeleteRecords.length, 2);
    });

    test('CheckinWidgetBridge 能够从本地数据库构建新鲜的桌面小部件快照', () async {
      // 1. 无数据时为 empty 状态
      final snapshotEmpty = await CheckinWidgetBridge.buildSnapshotForTesting(currentDb: db);
      expect(snapshotEmpty.state, checkinWidgetStateEmpty);
      expect(snapshotEmpty.eventCount, 0);

      // 2. 添加事件但未打卡
      await checkinRepo.createEvent(
        name: '冥想',
        description: '',
        colorValue: Colors.teal.value,
        currentUserId: 'user-001',
      );
      final snapshot1 = await CheckinWidgetBridge.buildSnapshotForTesting(currentDb: db);
      expect(snapshot1.state, checkinWidgetStateReady);
      expect(snapshot1.eventCount, 1);
      expect(snapshot1.checkedCount, 0);
      expect(snapshot1.items.first.eventName, '冥想');
      expect(snapshot1.items.first.isChecked, isFalse);

      // 3. 今日打卡后，快照即时更新为已打卡
      final events = await checkinRepo.watchEvents().first;
      await checkinRepo.checkin(
        eventId: events.first.id,
        targetDate: DateTime.now(),
        currentUserId: 'user-001',
      );

      final snapshot2 = await CheckinWidgetBridge.buildSnapshotForTesting(currentDb: db);
      expect(snapshot2.checkedCount, 1);
      expect(snapshot2.items.first.isChecked, isTrue);
    });

    testWidgets('EditCheckinEventDialog 支持修改名称、挑选专属颜色并保存', (tester) async {
      String? savedName;
      String? savedDesc;
      int? savedColor;

      final now = DateTime.now();
      final eventItem = DataItem<CheckinEvent>(
        'ev-101',
        now,
        now,
        'user-001',
        null,
        null,
        body: const CheckinEvent(name: '背单词', description: '每日 20 个', colorValue: 0xFF009688),
        syncStatus: SyncStatus.synced,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditCheckinEventDialog(
              eventItem: eventItem,
              onSave: (name, desc, color) async {
                savedName = name;
                savedDesc = desc;
                savedColor = color;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('编辑习惯项目'), findsOneWidget);
      expect(find.text('背单词'), findsOneWidget);
      expect(find.text('专属色彩'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);

      // 1. 修改名称
      await tester.enterText(find.widgetWithText(TextField, '习惯名称'), '背单词强化');
      await tester.pump();

      // 2. 选择新的颜色（例如蓝色）
      final blueCircle = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final dec = w.decoration as BoxDecoration;
          return dec.shape == BoxShape.circle && dec.color == Colors.blue;
        }
        return false;
      });
      expect(blueCircle, findsOneWidget);
      await tester.tap(blueCircle);
      await tester.pump();

      // 3. 点击保存
      await tester.tap(find.text('保存'));
      await tester.pump();

      expect(savedName, '背单词强化');
      expect(savedColor, Colors.blue.value);
    });
  });
}
