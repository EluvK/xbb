import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/models/tracker/tracker_calculator.dart';

void main() {
  group('TASK-3.1: Milestone 真实统计计算与切除 Mock', () {
    test('场景一：数值类型 (number) - 累计模式 (accumulate)', () {
      const config = MilestoneTrackerConfig(
        goalType: 'number',
        targetValue: '100',
        progressMode: 'accumulate',
      );

      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 1, 10, 0),
          value: '25.5',
        ),
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 2, 10, 0),
          value: '34.5',
        ),
      ];

      final result = TrackerCalculator.calculateMilestone(
        config: config,
        records: records,
      );

      // 25.5 + 34.5 = 60.0
      expect(result.currentNumeric, 60.0);
      expect(result.targetNumeric, 100.0);
      expect(result.progress, 0.6);
      expect(result.rawProgress, 0.6);
      expect(result.displayCurrent, '60');
      expect(result.displayTarget, '100');
      expect(result.percentText, '60%');
    });

    test('场景二：数值类型 (number) - 最新值模式 (latest)', () {
      const config = MilestoneTrackerConfig(
        goalType: 'number',
        targetValue: '80',
        progressMode: 'latest',
      );

      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 1, 10, 0),
          value: '50',
        ),
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 5, 12, 0), // 最新的记录
          value: '64',
        ),
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 2, 10, 0),
          value: '30',
        ),
      ];

      final result = TrackerCalculator.calculateMilestone(
        config: config,
        records: records,
      );

      // 应该取 2026-03-05 那条 64
      expect(result.currentNumeric, 64.0);
      expect(result.targetNumeric, 80.0);
      expect(result.progress, 0.8);
      expect(result.displayCurrent, '64');
      expect(result.percentText, '80%');
    });

    test('场景三：数值类型超额完成 (超出 100%)', () {
      const config = MilestoneTrackerConfig(
        goalType: 'number',
        targetValue: '50',
        progressMode: 'accumulate',
      );

      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 1),
          value: '30',
        ),
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 2),
          value: '40',
        ),
      ];

      final result = TrackerCalculator.calculateMilestone(
        config: config,
        records: records,
      );

      // 30 + 40 = 70. 70 / 50 = 1.4
      expect(result.rawProgress, 1.4);
      expect(result.progress, 1.0); // clamped for progress bar
      expect(result.displayCurrent, '70');
      expect(result.percentText, '100%');
    });

    test('场景四：时长类型 (time) - 累计模式与小时换算', () {
      const config = MilestoneTrackerConfig(
        goalType: 'time',
        targetValue: '120', // 120 分钟 = 2小时
        progressMode: 'accumulate',
      );

      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 1),
          value: '45',
        ),
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 2),
          value: '45',
        ),
      ];

      final result = TrackerCalculator.calculateMilestone(
        config: config,
        records: records,
      );

      // 90 分钟 / 120 分钟 = 0.75
      expect(result.currentNumeric, 90.0);
      expect(result.targetNumeric, 120.0);
      expect(result.progress, 0.75);
      expect(result.displayCurrent, '1.5小时');
      expect(result.displayTarget, '2小时');
      expect(result.percentText, '75%');
    });

    test('场景五：布尔值类型 (boolean) - 最新值与累计', () {
      const latestConfig = MilestoneTrackerConfig(
        goalType: 'boolean',
        targetValue: 'true',
        progressMode: 'latest',
      );

      final records = [
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 1),
          value: 'false',
        ),
        TrackerRecord(
          trackerId: 't1',
          timestamp: DateTime(2026, 3, 2),
          value: 'true',
        ),
      ];

      final latestResult = TrackerCalculator.calculateMilestone(
        config: latestConfig,
        records: records,
      );

      expect(latestResult.progress, 1.0);
      expect(latestResult.displayCurrent, '已完成');

      const accumulateConfig = MilestoneTrackerConfig(
        goalType: 'boolean',
        targetValue: 'true',
        progressMode: 'accumulate',
      );

      final accResult = TrackerCalculator.calculateMilestone(
        config: accumulateConfig,
        records: records,
      );

      // 1 次 true, 总计 2 次 -> 0.5
      expect(accResult.progress, 0.5);
      expect(accResult.displayCurrent, '1次');
      expect(accResult.displayTarget, '2次打卡');
    });

    test('场景六：空记录边界测试', () {
      const config = MilestoneTrackerConfig(
        goalType: 'number',
        targetValue: '100',
        progressMode: 'accumulate',
      );

      final result = TrackerCalculator.calculateMilestone(
        config: config,
        records: [],
      );

      expect(result.progress, 0.0);
      expect(result.currentNumeric, 0.0);
      expect(result.displayCurrent, '0');
      expect(result.percentText, '0%');
    });
  });
}
