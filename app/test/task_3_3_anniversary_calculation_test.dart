import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/models/tracker/tracker_calculator.dart';

void main() {
  group('TASK-3.3: Anniversary 节点推算与周期计算', () {
    final now = DateTime(2026, 3, 10);

    test('场景一：按年重复 (per_year) - 距下一个周年还有 X 天', () {
      final baseDate = DateTime(2020, 5, 20); // 5月20日
      final config = AnniversaryTrackerConfig(
        baseDate: baseDate,
        isLunar: false,
        remindType: 'per_year',
      );

      final result = TrackerCalculator.calculateAnniversary(
        config: config,
        now: now, // 2026-03-10
      );

      // 2026-05-20 减去 2026-03-10: 3月有21天(10到31)，4月30天，5月20天 -> 21 + 30 + 20 = 71 天
      expect(result.daysUntilNext, 71);
      expect(result.nextMilestoneTarget, 6); // 2026 - 2020 = 第 6 周年
      expect(result.isTargetToday, isFalse);
      expect(result.titleText, '距下个周年还有 71 天');
      expect(result.subtitleText, contains('第 6 周年'));
    });

    test('场景二：按年重复 (per_year) - 当天正是周年纪念日', () {
      final baseDate = DateTime(2021, 3, 10);
      final config = AnniversaryTrackerConfig(
        baseDate: baseDate,
        isLunar: false,
        remindType: 'per_year',
      );

      final result = TrackerCalculator.calculateAnniversary(
        config: config,
        now: now, // 2026-03-10
      );

      expect(result.daysUntilNext, 0);
      expect(result.isTargetToday, isTrue);
      expect(result.titleText, '今天是周年纪念日！🎉');
      expect(result.subtitleText, contains('第 5 周年'));
    });

    test('场景三：每百天提醒 (per_100_days) - 自动推算下一个百天节点与剩余天数', () {
      // 距离 2026-03-10 刚好过去 488 天的基准日
      final baseDate = now.subtract(const Duration(days: 488));
      final config = AnniversaryTrackerConfig(
        baseDate: baseDate,
        isLunar: false,
        remindType: 'per_100_days',
      );

      final result = TrackerCalculator.calculateAnniversary(
        config: config,
        now: now,
      );

      expect(result.passedDaysSinceBase, 488);
      // 下一个节点应该是 500 天，还剩 12 天
      expect(result.nextMilestoneTarget, 500);
      expect(result.daysUntilNext, 12);
      expect(result.titleText, '下一个节点: 500 天，还有 12 天');
      expect(result.subtitleText, '已走过 488 天');
      expect(result.isTargetToday, isFalse);
    });

    test('场景四：每百天提醒 (per_100_days) - 当天刚好整百天', () {
      final baseDate = now.subtract(const Duration(days: 300));
      final config = AnniversaryTrackerConfig(
        baseDate: baseDate,
        isLunar: false,
        remindType: 'per_100_days',
      );

      final result = TrackerCalculator.calculateAnniversary(
        config: config,
        now: now,
      );

      expect(result.passedDaysSinceBase, 300);
      expect(result.nextMilestoneTarget, 300);
      expect(result.daysUntilNext, 0);
      expect(result.isTargetToday, isTrue);
      expect(result.titleText, '今天是 300 天整百纪念日！🎉');
    });

    test('场景五：T 计时 / 自由倒数 (t_minus)', () {
      final pastBase = DateTime(2026, 3, 1);
      final pastConfig = AnniversaryTrackerConfig(
        baseDate: pastBase,
        isLunar: false,
        remindType: 't_minus',
      );

      final pastResult = TrackerCalculator.calculateAnniversary(
        config: pastConfig,
        now: now,
      );

      expect(pastResult.passedDaysSinceBase, 9);
      expect(pastResult.titleText, '已过去 9 天');

      final futureBase = DateTime(2026, 3, 20);
      final futureConfig = AnniversaryTrackerConfig(
        baseDate: futureBase,
        isLunar: false,
        remindType: 't_minus',
      );

      final futureResult = TrackerCalculator.calculateAnniversary(
        config: futureConfig,
        now: now,
      );

      expect(futureResult.passedDaysSinceBase, -10);
      expect(futureResult.titleText, '还剩 10 天');
    });
  });
}
