import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/models/tracker/tracker_calculator.dart';

void main() {
  group('TASK-3.2: Event 周期倒计时与红绿渐变超时报警', () {
    final now = DateTime(2026, 3, 10, 12, 0);

    test('场景一：从未打卡记录时，显示“从未记录”', () {
      const config = EventTrackerConfig(periodDays: 3);
      final result = TrackerCalculator.calculateEvent(
        config: config,
        records: [],
        now: now,
      );

      expect(result.lastRecordTime, isNull);
      expect(result.statusText, '从未记录');
      expect(result.isOverdue, isFalse);
      expect(result.progress, 0.0);
    });

    test('场景二：今天刚打卡，剩余天数满额，安全绿指示 (progress = 1.0)', () {
      const config = EventTrackerConfig(periodDays: 4);
      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 10, 8, 30),
        ),
      ];

      final result = TrackerCalculator.calculateEvent(
        config: config,
        records: records,
        now: now,
      );

      expect(result.passedDays, 0);
      expect(result.remainingDays, 4);
      expect(result.isOverdue, isFalse);
      expect(result.progress, 1.0);
      expect(result.statusText, '剩余 4 天');
      // progress = 1.0 对应纯绿色
      expect(result.statusColor, const Color(0xff4caf50));
    });

    test('场景三：半程临近状态，颜色平滑插值为黄绿混合 (progress = 0.5)', () {
      const config = EventTrackerConfig(periodDays: 4);
      // 2 天前打卡
      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 8, 10, 0),
        ),
      ];

      final result = TrackerCalculator.calculateEvent(
        config: config,
        records: records,
        now: now,
      );

      expect(result.passedDays, 2);
      expect(result.remainingDays, 2);
      expect(result.isOverdue, isFalse);
      expect(result.progress, 0.5);
      expect(result.statusText, '剩余 2 天');
      // 检查处于红色与绿色插值的中间过渡色
      expect(result.statusColor.r, greaterThan(0.5));
      expect(result.statusColor.g, greaterThan(0.4));
    });

    test('场景四：今天到期状态 (passedDays == periodDays)', () {
      const config = EventTrackerConfig(periodDays: 3);
      // 3 天前打卡
      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 7, 9, 0),
        ),
      ];

      final result = TrackerCalculator.calculateEvent(
        config: config,
        records: records,
        now: now,
      );

      expect(result.passedDays, 3);
      expect(result.remainingDays, 0);
      expect(result.isOverdue, isFalse);
      expect(result.statusText, '今天到期');
      expect(result.progress, 0.0);
      expect(result.statusColor, const Color(0xfff44336)); // 纯红
    });

    test('场景五：超时逾期状态，醒目报警显示逾期天数与红色警报', () {
      const config = EventTrackerConfig(periodDays: 3);
      // 5 天前打卡，逾期 2 天
      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 5, 9, 0),
        ),
      ];

      final result = TrackerCalculator.calculateEvent(
        config: config,
        records: records,
        now: now,
      );

      expect(result.passedDays, 5);
      expect(result.remainingDays, -2);
      expect(result.isOverdue, isTrue);
      expect(result.overdueDays, 2);
      expect(result.statusText, '已逾期 2 天');
      expect(result.progress, 0.0);
      expect(result.statusColor, Colors.red);
    });

    test('场景六：自由周期打卡 (periodDays = 0)', () {
      const config = EventTrackerConfig(periodDays: 0);
      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 9, 10, 0),
        ),
      ];

      final result = TrackerCalculator.calculateEvent(
        config: config,
        records: records,
        now: now,
      );

      expect(result.passedDays, 1);
      expect(result.periodDays, 0);
      expect(result.isOverdue, isFalse);
      expect(result.statusText, '1 天前');
      expect(result.statusColor, Colors.green);
    });
  });
}
