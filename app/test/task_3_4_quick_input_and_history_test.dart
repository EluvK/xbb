import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/tracker_repository.dart';
import 'package:xbb/models/tracker/model.dart' hide TrackerRepository;
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-3.4: 快捷录入、历史流水明细管理与追踪器编辑', () {
    late Database db;
    late DatabaseChangeNotifier changeNotifier;
    late TrackerRepository repository;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      changeNotifier = DatabaseChangeNotifier();
      repository = TrackerRepository(db: db, changeNotifier: changeNotifier);
    });

    tearDown(() async {
      await db.close();
    });

    test('场景一：添加多条打卡流水并按时间倒序查询历史流水明细', () async {
      final trackerId = UuidService.v7();
      final now = DateTime.now();

      // 创建 Tracker
      final trackerItem = DataItem<Tracker>(
        trackerId,
        now,
        now,
        'test-user-34',
        null,
        null,
        body: const Tracker(
          name: '阅读',
          description: '每日阅读打卡',
          category: '学习',
          type: 'milestone',
          config: TrackerConfig.milestone(
            goalType: 'time',
            targetValue: '600',
            progressMode: 'accumulate',
          ),
        ),
      );
      await repository.saveTracker(trackerItem);

      // 添加两条历史记录
      await repository.addRecord(
        trackerId: trackerId,
        value: '30',
        content: '第一章',
        currentUserId: 'test-user-34',
        timestamp: DateTime(2026, 3, 1, 10, 0),
      );
      await repository.addRecord(
        trackerId: trackerId,
        value: '45',
        content: '第二章',
        currentUserId: 'test-user-34',
        timestamp: DateTime(2026, 3, 2, 10, 0),
      );

      final records = await repository.getRecordsByTracker(trackerId);
      expect(records.length, 2);
      // 验证按时间戳倒序排序
      expect(records.first.body.value, '45');
      expect(records.first.body.content, '第二章');
      expect(records.last.body.value, '30');
    });

    test('场景二：编辑已有历史流水记录 (updateRecord)', () async {
      final trackerId = UuidService.v7();
      await repository.addRecord(
        trackerId: trackerId,
        value: '15',
        content: '草稿备注',
        currentUserId: 'test-user-34',
      );

      final recordsBefore = await repository.getRecordsByTracker(trackerId);
      final target = recordsBefore.first;

      // 修改数值和内容
      final updatedItem = DataItem<TrackerRecord>(
        target.id,
        target.createdAt,
        DateTime.now(),
        target.owner,
        target.parentId,
        null,
        body: target.body.copyWith(
          value: '60',
          content: '修改后的完整笔记',
        ),
      );
      await repository.updateRecord(updatedItem);

      final recordsAfter = await repository.getRecordsByTracker(trackerId);
      expect(recordsAfter.first.body.value, '60');
      expect(recordsAfter.first.body.content, '修改后的完整笔记');
    });

    test('场景三：单条历史流水删除 (deleteRecord)', () async {
      final trackerId = UuidService.v7();
      await repository.addRecord(
        trackerId: trackerId,
        value: '20',
        content: '将被删除的记录',
        currentUserId: 'test-user-34',
      );

      final recordsBefore = await repository.getRecordsByTracker(trackerId);
      expect(recordsBefore.length, 1);
      final recordId = recordsBefore.first.id;

      await repository.deleteRecord(recordId);

      final recordsAfter = await repository.getRecordsByTracker(trackerId);
      expect(recordsAfter, isEmpty);
    });

    test('场景四：编辑追踪器本身配置 (updateTracker)', () async {
      final trackerId = UuidService.v7();
      final now = DateTime.now();

      final trackerItem = DataItem<Tracker>(
        trackerId,
        now,
        now,
        'test-user-34',
        null,
        null,
        body: const Tracker(
          name: '原名称',
          description: '原描述',
          category: '默认',
          type: 'event',
          config: TrackerConfig.event(periodDays: 3),
        ),
      );
      await repository.saveTracker(trackerItem);

      // 更新追踪器配置
      final updatedTracker = DataItem<Tracker>(
        trackerItem.id,
        trackerItem.createdAt,
        DateTime.now(),
        trackerItem.owner,
        null,
        null,
        body: trackerItem.body.copyWith(
          name: '新名称已更新',
          category: '健身',
          config: const TrackerConfig.event(periodDays: 7),
        ),
      );
      await repository.updateTracker(updatedTracker);

      // 查询验证
      final streamFuture = repository.watchTrackers().first;
      final trackers = await streamFuture;
      final found = trackers.firstWhere((t) => t.id == trackerId);

      expect(found.body.name, '新名称已更新');
      expect(found.body.category, '健身');
      expect((found.body.config as EventTrackerConfig).periodDays, 7);
    });
  });
}
