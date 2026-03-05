import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/models/tracker/model.dart';

void main() {
  group('Tracker Full Integration Tests', () {
    test('场景一：反序列化 [习惯/Event] Tracker', () {
      final json = {
        "name": "每日健身",
        "description": "保持身体健康",
        "category": "健康",
        "type": "event",
        "config": {"type": "event", "period_days": 1, "detail_unit": "duration"},
      };

      final tracker = Tracker.fromJson(json);

      expect(tracker.config, isA<EventTrackerConfig>());

      // 验证具体字段
      final config = tracker.config as EventTrackerConfig;
      expect(config.periodDays, 1);
      expect(config.detailUnit, "duration");
    });

    test('场景二：反序列化 [目标/Milestone] Tracker', () {
      final json = {
        "name": "阅读50本书",
        "description": "年度阅读计划",
        "category": "自我提升",
        "type": "milestone",
        "config": {"type": "milestone", "goal_type": "number", "target_value": "50.0"},
      };

      final tracker = Tracker.fromJson(json);

      expect(tracker.config, isA<MilestoneTrackerConfig>());

      tracker.config.maybeWhen(
        milestone: (goalType, targetValue) {
          expect(goalType, "number");
          expect(targetValue, "50.0");
        },
        orElse: () => fail("应该识别为 milestone 分支"),
      );
    });

    test('场景三：反序列化 [纪念日/Anniversary] Tracker', () {
      final json = {
        "name": "入职纪念日",
        "description": "第一份工作",
        "category": "职业",
        "type": "anniversary",
        "config": {
          "type": "anniversary",
          "base_date": "2022-03-01T00:00:00.000Z",
          "is_lunar": false,
          "remind_type": "per_year",
        },
      };

      final tracker = Tracker.fromJson(json);

      expect(tracker.config, isA<AnniversaryTrackerConfig>());

      final config = tracker.config as AnniversaryTrackerConfig;
      expect(config.baseDate.year, 2022);
      expect(config.isLunar, false);
    });

    test('边界测试：处理 Config 中缺失的 Optional 字段', () {
      final json = {
        "name": "不定期任务",
        "description": "没有固定周期",
        "category": "杂项",
        "type": "event",
        "config": {
          "type": "event",
          "period_days": null, // 测试 Option<u32> 为空的情况
          "detail_unit": "boolean",
        },
      };

      final tracker = Tracker.fromJson(json);
      final config = tracker.config as EventTrackerConfig;

      expect(config.periodDays, isNull);
    });
  });

  group('TrackerRecord Serialization Tests', () {
    test('场景一：解析带数值和笔记的完整记录', () {
      final json = {
        "tracker_id": "t-123",
        "timestamp": "2026-03-05T10:00:00.000Z",
        "value": "45.5",
        "content": "今天健身感觉不错",
      };

      final record = TrackerRecord.fromJson(json);

      expect(record.trackerId, "t-123");
      expect(record.value, "45.5");
      expect(record.content, "今天健身感觉不错");
      // 验证时间戳解析
      expect(record.timestamp.year, 2026);
      expect(record.timestamp.isUtc, true);
    });

    test('场景二：解析仅有时间戳的简单记录 (打卡场景)', () {
      final json = {"tracker_id": "t-456", "timestamp": "2026-03-05T12:00:00Z", "value": null, "content": null};

      final record = TrackerRecord.fromJson(json);

      expect(record.value, isNull);
      expect(record.content, isNull);
    });

    test('场景三：解析布尔值类型的记录', () {
      final json = {"tracker_id": "t-789", "timestamp": "2026-03-05T15:30:00Z", "value": "true", "content": "已达成目标"};

      final record = TrackerRecord.fromJson(json);

      expect(record.value, "true");
      // 模拟业务逻辑转换
      final boolValue = record.value == "true";
      expect(boolValue, isTrue);
    });

    test('序列化测试：生成的 JSON 字段应为蛇形命名', () {
      final record = TrackerRecord(
        trackerId: "t-999",
        timestamp: DateTime.parse("2026-03-05T08:00:00Z"),
        value: "120",
        content: "Running",
      );

      final json = record.toJson();

      // 验证字段名是否被正确转换为 snake_case
      expect(json.containsKey('tracker_id'), isTrue);
      expect(json['tracker_id'], "t-999");
      expect(json['value'], "120");
    });
  });
}
