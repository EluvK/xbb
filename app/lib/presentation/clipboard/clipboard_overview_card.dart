import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class ClipboardOverviewCard extends ConsumerWidget {
  const ClipboardOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(clipboardOverviewStatsProvider);

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '剪贴板概览',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '本地优先 · 隐私防护',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatMetricBox(
                  label: '总数',
                  value: stats.total,
                  color: theme.colorScheme.primary,
                  icon: Icons.all_inbox_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatMetricBox(
                  label: '仅本地',
                  value: stats.localOnly,
                  color: Colors.teal,
                  icon: Icons.lock_outline,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatMetricBox(
                  label: '已同步',
                  value: stats.synced,
                  color: Colors.blue,
                  icon: Icons.cloud_done_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatMetricBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatMetricBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
