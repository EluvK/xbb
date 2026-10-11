import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/tracker/tracker_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class ModernTrackerView extends ConsumerWidget {
  const ModernTrackerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trackersAsync = ref.watch(trackersStreamProvider);
    final userId = ref.watch(authProvider).userId;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '目标追踪',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '新建追踪器',
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTrackerDialog(context, ref, userId),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: trackersAsync.when(
        data: (trackers) {
          if (trackers.isEmpty) {
            return const ModernEmptyState(
              icon: Icons.track_changes_rounded,
              title: '暂无目标追踪器',
              subtitle: '点击右上角 “+” 创建你的习惯周期、里程碑或重要纪念日',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: trackers.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final tracker = trackers[index];
              return _buildTrackerCard(context, ref, tracker, userId);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildTrackerCard(
    BuildContext context,
    WidgetRef ref,
    DataItem<Tracker> tracker,
    String userId,
  ) {
    final theme = Theme.of(context);
    final body = tracker.body;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getIconForType(body.type), color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    body.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ModernBadge(label: _getTypeLabel(body.type)),
            ],
          ),
          if (body.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              body.description,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          _buildConfigDetail(context, body.config),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('记录打卡'),
                onPressed: () => _showRecordDialog(context, ref, tracker.id, userId),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => ref.read(trackerRepositoryProvider).deleteTracker(tracker.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigDetail(BuildContext context, TrackerConfig config) {
    final theme = Theme.of(context);
    return config.when(
      event: (periodDays) => Row(
        children: [
          Icon(Icons.repeat, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            periodDays > 0 ? '周期: 每 $periodDays 天一次' : '周期: 自由打卡',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      milestone: (goalType, targetValue, progressMode) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('目标: $targetValue ($goalType)', style: theme.textTheme.bodySmall),
              Text('模式: $progressMode', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: 0.35, // 演示进度
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
      anniversary: (baseDate, isLunar, remindType) {
        final now = DateTime.now();
        final diffDays = now.difference(baseDate).inDays.abs();
        final isPast = now.isAfter(baseDate);
        return Row(
          children: [
            Icon(Icons.cake_outlined, size: 16, color: Colors.pinkAccent),
            const SizedBox(width: 8),
            Text(
              isPast ? '已过去 $diffDays 天' : '还剩 $diffDays 天',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            ModernBadge(label: isLunar ? '农历' : '公历'),
          ],
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event_repeat_rounded;
      case 'milestone':
        return Icons.flag_rounded;
      case 'anniversary':
        return Icons.favorite_rounded;
      default:
        return Icons.track_changes_rounded;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'event':
        return '习惯周期';
      case 'milestone':
        return '里程碑';
      case 'anniversary':
        return '纪念日';
      default:
        return '追踪器';
    }
  }

  void _showRecordDialog(BuildContext context, WidgetRef ref, String trackerId, String userId) {
    final valCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: valCtrl, decoration: const InputDecoration(labelText: '数值/状态 (可选)', isDense: true)),
            const SizedBox(height: 12),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: '备注 (可选)', isDense: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              ref.read(trackerRepositoryProvider).addRecord(
                    trackerId: trackerId,
                    value: valCtrl.text.trim().isEmpty ? null : valCtrl.text.trim(),
                    content: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    currentUserId: userId,
                  );
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showCreateTrackerDialog(BuildContext context, WidgetRef ref, String userId) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'event';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新建追踪器'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', isDense: true)),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述 (可选)', isDense: true)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: '类型', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'event', child: Text('习惯周期 (Event)')),
                  DropdownMenuItem(value: 'milestone', child: Text('阶段里程碑 (Milestone)')),
                  DropdownMenuItem(value: 'anniversary', child: Text('重要纪念日 (Anniversary)')),
                ],
                onChanged: (v) => setState(() => selectedType = v ?? 'event'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  TrackerConfig config;
                  if (selectedType == 'milestone') {
                    config = const TrackerConfig.milestone(
                      goalType: 'number',
                      targetValue: '100',
                      progressMode: 'accumulate',
                    );
                  } else if (selectedType == 'anniversary') {
                    config = TrackerConfig.anniversary(
                      baseDate: DateTime.now(),
                      isLunar: false,
                      remindType: 'per_year',
                    );
                  } else {
                    config = const TrackerConfig.event(periodDays: 1);
                  }

                  final now = DateTime.now();
                  final newTracker = DataItem<Tracker>(
                    UuidService.v7(),
                    now,
                    now,
                    userId,
                    null,
                    null,
                    body: Tracker(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      category: '默认',
                      type: selectedType,
                      config: config,
                    ),
                    syncStatus: SyncStatus.pending,
                  );
                  ref.read(trackerRepositoryProvider).saveTracker(newTracker);
                }
                Navigator.pop(ctx);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }
}
