import 'package:flutter/material.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

/// 响应式活跃任务概览统计卡片
class TaskOverviewCard extends StatelessWidget {
  final int totalCount;
  final int doneCount;
  final VoidCallback? onToggleCollapse;
  final bool isCollapsed;

  const TaskOverviewCard({
    super.key,
    required this.totalCount,
    required this.doneCount,
    this.onToggleCollapse,
    this.isCollapsed = false,
  });

  int get todoCount => totalCount - doneCount;
  double get ratio => totalCount == 0 ? 0.0 : doneCount / totalCount;
  String get percentText => '${(ratio * 100).toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDoneAll = totalCount > 0 && doneCount == totalCount;

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDoneAll ? Icons.task_alt_rounded : Icons.insights_rounded,
                    size: 20,
                    color: isDoneAll ? Colors.green : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '任务概览与进度',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  ModernBadge(
                    label: percentText,
                    color: isDoneAll ? Colors.green : theme.colorScheme.primary,
                  ),
                  if (onToggleCollapse != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: isCollapsed ? '展开概览' : '收起概览',
                      icon: Icon(
                        isCollapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onToggleCollapse,
                    ),
                ],
              ),
            ],
          ),
          if (!isCollapsed) ...[
            const SizedBox(height: AppSpacing.sm),
            // 平滑动画进度条
            ClipRRect(
              borderRadius: AppRadius.roundedSm,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: ratio),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDoneAll ? Colors.green : theme.colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 统计指标 Chips
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: '总任务',
                    value: totalCount,
                    icon: Icons.format_list_bulleted_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatBox(
                    label: '已完成',
                    value: doneCount,
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatBox(
                    label: '待处理',
                    value: todoCount,
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
