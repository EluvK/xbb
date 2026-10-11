import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:xbb/models/tracker/model.dart';

/// 里程碑目标计算结果
class MilestoneProgressResult {
  final double progress; // 0.0 ~ 1.0 (适合进度条)
  final double rawProgress; // 未裁剪的真实比例 (可能 > 1.0)
  final double currentNumeric;
  final double targetNumeric;
  final String displayCurrent;
  final String displayTarget;
  final String percentText;

  const MilestoneProgressResult({
    required this.progress,
    required this.rawProgress,
    required this.currentNumeric,
    required this.targetNumeric,
    required this.displayCurrent,
    required this.displayTarget,
    required this.percentText,
  });
}

/// 周期习惯计算结果
class EventProgressResult {
  final DateTime? lastRecordTime;
  final int passedDays;
  final int periodDays;
  final double progress; // 0.0 ~ 1.0，周期倒计时进度（1.0为刚打卡，0.0为到期）
  final bool isOverdue;
  final int overdueDays;
  final int remainingDays;
  final Color statusColor;
  final String statusText;

  const EventProgressResult({
    required this.lastRecordTime,
    required this.passedDays,
    required this.periodDays,
    required this.progress,
    required this.isOverdue,
    required this.overdueDays,
    required this.remainingDays,
    required this.statusColor,
    required this.statusText,
  });
}

/// 纪念日推算结果
class AnniversaryProgressResult {
  final int passedDaysSinceBase;
  final int daysUntilNext;
  final int nextMilestoneTarget;
  final String titleText;
  final String subtitleText;

  const AnniversaryProgressResult({
    required this.passedDaysSinceBase,
    required this.daysUntilNext,
    required this.nextMilestoneTarget,
    required this.titleText,
    required this.subtitleText,
  });
}

/// 追踪器精准数据与指标计算引擎
class TrackerCalculator {
  static String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  static String _formatTimeDisplay(double minutes) {
    if (minutes <= 0) return '0分钟';
    if (minutes < 60) {
      return '${formatNumber(minutes)}分钟';
    }
    final hours = minutes / 60;
    return '${formatNumber(hours)}小时';
  }

  /// 计算 Milestone（里程碑）进度
  static MilestoneProgressResult calculateMilestone({
    required MilestoneTrackerConfig config,
    required List<TrackerRecord> records,
  }) {
    final sortedRecords = List<TrackerRecord>.from(records)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latestRecord = sortedRecords.isNotEmpty ? sortedRecords.first : null;
    final latestValue = latestRecord?.value;

    final goalType = config.goalType;
    final progressMode = config.progressMode;
    final target = double.tryParse(config.targetValue) ?? 0.0;

    double currentNumeric = 0.0;
    String displayCurrent = '0';
    String displayTarget = config.targetValue;
    double rawProgress = 0.0;

    if (goalType == 'boolean') {
      if (progressMode == 'latest') {
        final isDone = latestValue?.toLowerCase() == 'true';
        currentNumeric = isDone ? 1.0 : 0.0;
        rawProgress = isDone ? 1.0 : 0.0;
        displayCurrent = isDone ? '已完成' : '未完成';
        displayTarget = '已完成';
      } else {
        final trueCount = records.where((r) => r.value?.toLowerCase() == 'true').length;
        final total = records.length;
        currentNumeric = trueCount.toDouble();
        rawProgress = total > 0 ? (trueCount / total) : 0.0;
        displayCurrent = '$trueCount次';
        displayTarget = '$total次打卡';
      }
    } else if (goalType == 'time') {
      final targetMinutes = target;
      if (progressMode == 'latest') {
        final latestMinutes = double.tryParse(latestValue ?? '') ?? 0.0;
        currentNumeric = latestMinutes;
        rawProgress = targetMinutes > 0 ? (latestMinutes / targetMinutes) : 0.0;
        displayCurrent = _formatTimeDisplay(latestMinutes);
      } else {
        double sum = 0.0;
        for (final r in records) {
          sum += double.tryParse(r.value ?? '') ?? 0.0;
        }
        currentNumeric = sum;
        rawProgress = targetMinutes > 0 ? (sum / targetMinutes) : 0.0;
        displayCurrent = _formatTimeDisplay(sum);
      }
      displayTarget = _formatTimeDisplay(targetMinutes);
    } else {
      // number
      if (progressMode == 'latest') {
        final latest = double.tryParse(latestValue ?? '') ?? 0.0;
        currentNumeric = latest;
        rawProgress = target > 0 ? (latest / target) : 0.0;
        displayCurrent = formatNumber(latest);
      } else {
        double sum = 0.0;
        for (final r in records) {
          sum += double.tryParse(r.value ?? '') ?? 0.0;
        }
        currentNumeric = sum;
        rawProgress = target > 0 ? (sum / target) : 0.0;
        displayCurrent = formatNumber(sum);
      }
      displayTarget = formatNumber(target);
    }

    final clampedProgress = rawProgress.clamp(0.0, 1.0);
    final percentText = '${(clampedProgress * 100).toStringAsFixed(0)}%';

    return MilestoneProgressResult(
      progress: clampedProgress,
      rawProgress: rawProgress,
      currentNumeric: currentNumeric,
      targetNumeric: target,
      displayCurrent: displayCurrent,
      displayTarget: displayTarget,
      percentText: percentText,
    );
  }

  /// 计算 Event（习惯周期倒计时与状态）
  static EventProgressResult calculateEvent({
    required EventTrackerConfig config,
    required List<TrackerRecord> records,
    DateTime? now,
  }) {
    final currentNow = now ?? DateTime.now();
    DateTime? last;
    if (records.isNotEmpty) {
      final sortedRecords = List<TrackerRecord>.from(records)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      last = sortedRecords.first.timestamp.toLocal();
    }

    final period = config.periodDays;
    if (last == null) {
      return const EventProgressResult(
        lastRecordTime: null,
        passedDays: 0,
        periodDays: 0,
        progress: 0.0,
        isOverdue: false,
        overdueDays: 0,
        remainingDays: 0,
        statusColor: Colors.grey,
        statusText: '从未记录',
      );
    }

    final today = DateTime(currentNow.year, currentNow.month, currentNow.day);
    final lastDay = DateTime(last.year, last.month, last.day);
    final passedDays = today.difference(lastDay).inDays;

    if (period <= 0) {
      final statusText = passedDays == 0 ? '今天已打卡' : '$passedDays 天前';
      return EventProgressResult(
        lastRecordTime: last,
        passedDays: passedDays,
        periodDays: period,
        progress: 1.0,
        isOverdue: false,
        overdueDays: 0,
        remainingDays: 0,
        statusColor: Colors.green,
        statusText: statusText,
      );
    }

    final remainingDays = period - passedDays;
    final isOverdue = remainingDays < 0;
    final overdueDays = isOverdue ? -remainingDays : 0;

    // progress 1.0 表示刚打卡（满），0.0 表示到期/逾期
    final progress = (1.0 - (passedDays / period)).clamp(0.0, 1.0);
    // 红绿动态渐变: progress=1.0 为绿色, 0.5 为黄色, 0.0 为红色
    final statusColor = Color.lerp(Colors.red, Colors.green, progress) ?? Colors.green;

    String statusText;
    if (isOverdue) {
      statusText = '已逾期 $overdueDays 天';
    } else if (remainingDays == 0) {
      statusText = '今天到期';
    } else {
      statusText = '剩余 $remainingDays 天';
    }

    return EventProgressResult(
      lastRecordTime: last,
      passedDays: passedDays,
      periodDays: period,
      progress: progress,
      isOverdue: isOverdue,
      overdueDays: overdueDays,
      remainingDays: remainingDays,
      statusColor: isOverdue ? Colors.red : statusColor,
      statusText: statusText,
    );
  }

  /// 计算 Anniversary（重要纪念日节点推算）
  static AnniversaryProgressResult calculateAnniversary({
    required AnniversaryTrackerConfig config,
    DateTime? now,
  }) {
    final currentNow = now ?? DateTime.now();
    final base = config.baseDate.toLocal();
    final today = DateTime(currentNow.year, currentNow.month, currentNow.day);
    final baseDay = DateTime(base.year, base.month, base.day);
    final passedDaysSinceBase = today.difference(baseDay).inDays;

    if (config.remindType == 'per_year') {
      DateTime nextAnniversary = DateTime(today.year, base.month, base.day);
      if (nextAnniversary.isBefore(today)) {
        nextAnniversary = DateTime(today.year + 1, base.month, base.day);
      }
      final daysUntilNext = nextAnniversary.difference(today).inDays;
      final yearsCount = nextAnniversary.year - base.year;

      final title = daysUntilNext == 0 ? '今天是周年纪念日！' : '距下个周年还有 $daysUntilNext 天';
      final subtitle = '已度过 $passedDaysSinceBase 天 (第 $yearsCount 周年)';
      return AnniversaryProgressResult(
        passedDaysSinceBase: passedDaysSinceBase,
        daysUntilNext: daysUntilNext,
        nextMilestoneTarget: yearsCount,
        titleText: title,
        subtitleText: subtitle,
      );
    } else if (config.remindType == 'per_100_days') {
      final safePassed = math.max(0, passedDaysSinceBase);
      final nextMilestone = ((safePassed / 100).floor() + 1) * 100;
      final daysUntilNext = nextMilestone - safePassed;

      return AnniversaryProgressResult(
        passedDaysSinceBase: passedDaysSinceBase,
        daysUntilNext: daysUntilNext,
        nextMilestoneTarget: nextMilestone,
        titleText: '下一个节点: $nextMilestone 天，还有 $daysUntilNext 天',
        subtitleText: '已走过 $passedDaysSinceBase 天',
      );
    } else {
      // t_minus 或自由倒数
      final isPast = passedDaysSinceBase >= 0;
      final title = isPast ? '已过去 $passedDaysSinceBase 天' : '还剩 ${-passedDaysSinceBase} 天';
      final baseDateStr = '${base.year}-${base.month.toString().padLeft(2, '0')}-${base.day.toString().padLeft(2, '0')}';
      return AnniversaryProgressResult(
        passedDaysSinceBase: passedDaysSinceBase,
        daysUntilNext: isPast ? 0 : -passedDaysSinceBase,
        nextMilestoneTarget: 0,
        titleText: title,
        subtitleText: '基准日: $baseDateStr',
      );
    }
  }
}
