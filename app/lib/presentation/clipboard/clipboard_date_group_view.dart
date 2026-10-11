import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

String clipboardDateHeaderLabel(DateTime date, {bool isZh = true}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final target = DateTime(date.year, date.month, date.day);

  final dateKey = formatClipboardDateKey(date);

  if (target == today) {
    return isZh ? '$dateKey · 今天' : '$dateKey · Today';
  }
  if (target == yesterday) {
    return isZh ? '$dateKey · 昨天' : '$dateKey · Yesterday';
  }

  const zhWeekdays = <int, String>{
    DateTime.monday: '星期一',
    DateTime.tuesday: '星期二',
    DateTime.wednesday: '星期三',
    DateTime.thursday: '星期四',
    DateTime.friday: '星期五',
    DateTime.saturday: '星期六',
    DateTime.sunday: '星期日',
  };

  const enWeekdays = <int, String>{
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
    DateTime.sunday: 'Sun',
  };

  final weekdayStr = isZh ? (zhWeekdays[date.weekday] ?? '') : (enWeekdays[date.weekday] ?? '');
  return '$dateKey · $weekdayStr';
}

class ClipboardDateGroupView extends ConsumerWidget {
  final ClipboardDateGroup group;
  final bool isCollapsed;
  final bool? isZh;
  final VoidCallback? onToggleCollapse;
  final Widget? trailingHeaderAction;
  final Widget Function(BuildContext context, dynamic item)? itemBuilder;

  const ClipboardDateGroupView({
    super.key,
    required this.group,
    required this.isCollapsed,
    this.isZh,
    this.onToggleCollapse,
    this.trailingHeaderAction,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final effectiveIsZh = isZh ?? (Localizations.maybeLocaleOf(context)?.languageCode.startsWith('zh') ?? true);
    final headerTitle = clipboardDateHeaderLabel(group.date, isZh: effectiveIsZh);
    final selectedIds = ref.watch(selectedClipboardIdsProvider);
    final groupIds = group.entries.map((e) => e.id as String).toList();
    final isAllSelected = groupIds.isNotEmpty && groupIds.every(selectedIds.contains);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 分组头部
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onToggleCollapse ??
              () => ref.read(collapsedClipboardDatesProvider.notifier).toggle(group.dateKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: isCollapsed ? 0.0 : 0.25,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  headerTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${group.entries.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Spacer(),
                if (trailingHeaderAction != null)
                  trailingHeaderAction!
                else
                  TextButton(
                    onPressed: () {
                      ref.read(selectedClipboardIdsProvider.notifier).toggleGroup(groupIds);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      isAllSelected ? (effectiveIsZh ? '取消当天' : 'Unselect Day') : (effectiveIsZh ? '全选当天' : 'Select Day'),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // 分组内容（折叠时平滑收起）
        if (!isCollapsed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(group.entries.length, (index) {
                final item = group.entries[index];
                if (itemBuilder != null) {
                  return itemBuilder!(context, item);
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ClipboardEntryCard(item: item),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class ClipboardEntryCard extends ConsumerWidget {
  final dynamic item;
  final bool? isSelected;
  final ValueChanged<bool>? onSelectChanged;

  const ClipboardEntryCard({
    super.key,
    required this.item,
    this.isSelected,
    this.onSelectChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entry = item.body as ClipboardHistoryEntry;
    final timeStr = entry.capturedAt?.toLocal().toString().split('.').first ?? '';
    final selectedIds = ref.watch(selectedClipboardIdsProvider);
    final selected = isSelected ?? selectedIds.contains(item.id as String);

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: selected,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    if (onSelectChanged != null) {
                      onSelectChanged!(val ?? false);
                    } else {
                      ref.read(selectedClipboardIdsProvider.notifier).toggle(item.id as String);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ModernBadge(
                label: entry.localOnly ? '本地隐私 (ADR-0002)' : '已云端同步',
                color: entry.localOnly ? Colors.teal : Colors.blue,
                icon: entry.localOnly ? Icons.lock_outline : Icons.cloud_done_outlined,
              ),
              const Spacer(),
              Text(
                timeStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Text(
              entry.data,
              style: theme.textTheme.bodyMedium,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (entry.localOnly)
                TextButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('备份上云'),
                  onPressed: () {
                    ref.read(clipboardRepositoryProvider).syncToCloud(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已确认并入队同步')),
                    );
                  },
                ),
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制'),
                onPressed: () {
                  ref.read(clipboardRepositoryProvider).copyToClipboard(entry.data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制到系统剪贴板')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => ref.read(clipboardRepositoryProvider).delete(item.id as String),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
