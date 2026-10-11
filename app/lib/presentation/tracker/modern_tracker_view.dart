import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/models/tracker/tracker_calculator.dart';
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
              return ModernTrackerCard(
                key: ValueKey('tracker-${tracker.id}'),
                tracker: tracker,
                userId: userId,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _showCreateTrackerDialog(BuildContext context, WidgetRef ref, String userId) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetValCtrl = TextEditingController(text: '100');
    final periodCtrl = TextEditingController(text: '1');
    String selectedType = 'milestone';
    String goalType = 'number';
    String progressMode = 'accumulate';
    String remindType = 'per_year';
    DateTime selectedBaseDate = DateTime.now();
    bool isLunar = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('新建追踪器'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', isDense: true)),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述 (可选)', isDense: true)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: '类型', isDense: true),
                  items: const [
                    DropdownMenuItem(value: 'milestone', child: Text('阶段里程碑 (Milestone)')),
                    DropdownMenuItem(value: 'event', child: Text('习惯周期 (Event)')),
                    DropdownMenuItem(value: 'anniversary', child: Text('重要纪念日 (Anniversary)')),
                  ],
                  onChanged: (v) => setState(() => selectedType = v ?? 'milestone'),
                ),
                if (selectedType == 'milestone') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: goalType,
                    decoration: const InputDecoration(labelText: '目标类型', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'number', child: Text('数值 (Number)')),
                      DropdownMenuItem(value: 'time', child: Text('时长/分钟 (Time)')),
                      DropdownMenuItem(value: 'boolean', child: Text('完成状态 (Boolean)')),
                    ],
                    onChanged: (v) => setState(() => goalType = v ?? 'number'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: progressMode,
                    decoration: const InputDecoration(labelText: '计算模式', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'accumulate', child: Text('累计求和 (Accumulate)')),
                      DropdownMenuItem(value: 'latest', child: Text('最新一次值 (Latest)')),
                    ],
                    onChanged: (v) => setState(() => progressMode = v ?? 'accumulate'),
                  ),
                  if (goalType != 'boolean') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetValCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: goalType == 'time' ? '目标时长 (分钟数，如 120)' : '目标数值 (如 100)',
                        isDense: true,
                      ),
                    ),
                  ],
                ] else if (selectedType == 'event') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: periodCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '周期天数 (0 为自由打卡)',
                      isDense: true,
                    ),
                  ),
                ] else if (selectedType == 'anniversary') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: remindType,
                    decoration: const InputDecoration(labelText: '提醒与推算类型', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'per_year', child: Text('每年重复 (按周年推算)')),
                      DropdownMenuItem(value: 'per_100_days', child: Text('每百天节点 (100/200/500天)')),
                      DropdownMenuItem(value: 't_minus', child: Text('倒计时 / 正计时')),
                    ],
                    onChanged: (v) => setState(() => remindType = v ?? 'per_year'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('基准日期', style: TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selectedBaseDate)),
                    trailing: const Icon(Icons.calendar_month, size: 20),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedBaseDate,
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedBaseDate = picked);
                      }
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('农历纪念日', style: TextStyle(fontSize: 14)),
                    value: isLunar,
                    onChanged: (v) => setState(() => isLunar = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  TrackerConfig config;
                  if (selectedType == 'milestone') {
                    config = TrackerConfig.milestone(
                      goalType: goalType,
                      targetValue: goalType == 'boolean' ? 'true' : (targetValCtrl.text.trim().isEmpty ? '100' : targetValCtrl.text.trim()),
                      progressMode: progressMode,
                    );
                  } else if (selectedType == 'anniversary') {
                    config = TrackerConfig.anniversary(
                      baseDate: selectedBaseDate,
                      isLunar: isLunar,
                      remindType: remindType,
                    );
                  } else {
                    final p = int.tryParse(periodCtrl.text.trim()) ?? 1;
                    config = TrackerConfig.event(periodDays: p);
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

class ModernTrackerCard extends ConsumerWidget {
  final DataItem<Tracker> tracker;
  final String userId;

  const ModernTrackerCard({
    super.key,
    required this.tracker,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final body = tracker.body;
    final recordsAsync = ref.watch(trackerRecordsProvider(tracker.id));
    final records = recordsAsync.valueOrNull?.map((e) => e.body).toList() ?? <TrackerRecord>[];

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
          _buildConfigDetail(context, body.config, records),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('记录打卡'),
                onPressed: () => _showRecordDialog(context, ref, tracker.id, userId, body.config),
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

  Widget _buildConfigDetail(BuildContext context, TrackerConfig config, List<TrackerRecord> records) {
    final theme = Theme.of(context);
    return config.when(
      event: (periodDays) {
        final eventResult = TrackerCalculator.calculateEvent(
          config: config as EventTrackerConfig,
          records: records,
        );

        if (periodDays <= 0) {
          return Row(
            children: [
              Icon(Icons.repeat, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '自由周期 • ${eventResult.statusText}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: eventResult.lastRecordTime == null ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      eventResult.isOverdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
                      size: 16,
                      color: eventResult.statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      eventResult.lastRecordTime == null ? '从未记录' : '${eventResult.passedDays} 天前已打卡',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: eventResult.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: eventResult.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    eventResult.statusText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: eventResult.statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: eventResult.progress,
              color: eventResult.statusColor,
              backgroundColor: eventResult.statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '周期: 每 $periodDays 天一次',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                if (eventResult.isOverdue)
                  Text(
                    '⚠️ 超时报警: 已逾期 ${eventResult.overdueDays} 天',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '剩余 ${eventResult.remainingDays} 天',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ],
        );
      },
      milestone: (goalType, targetValue, progressMode) {
        final milestoneResult = TrackerCalculator.calculateMilestone(
          config: config as MilestoneTrackerConfig,
          records: records,
        );
        final barColor = Color.lerp(Colors.red, Colors.green, milestoneResult.progress) ?? theme.colorScheme.primary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${milestoneResult.displayCurrent} / ${milestoneResult.displayTarget}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  milestoneResult.percentText,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: barColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: milestoneResult.progress,
              color: barColor,
              backgroundColor: barColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '目标: ${_getGoalTypeLabel(goalType)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  '模式: ${progressMode == 'accumulate' ? '累计' : '最新值'} (${records.length}条记录)',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        );
      },
      anniversary: (baseDate, isLunar, remindType) {
        final anniversaryResult = TrackerCalculator.calculateAnniversary(
          config: config as AnniversaryTrackerConfig,
        );

        TrackerRecord? latestNote;
        for (final r in records) {
          if (r.content != null && r.content!.trim().isNotEmpty) {
            latestNote = r;
            break;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.cake_rounded,
                      size: 18,
                      color: anniversaryResult.isTargetToday ? Colors.pink : Colors.pinkAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      anniversaryResult.titleText,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ModernBadge(label: isLunar ? '农历' : '公历'),
                    const SizedBox(width: 4),
                    ModernBadge(
                      label: remindType == 'per_year'
                          ? '每年重复'
                          : (remindType == 'per_100_days' ? '百天节点' : '倒计时'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              anniversaryResult.subtitleText,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (latestNote != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '最新心情',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SimpleMarkdownRenderer(data: latestNote.content!),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getGoalTypeLabel(String goalType) {
    switch (goalType) {
      case 'time':
        return '时长';
      case 'boolean':
        return '完成状态';
      default:
        return '数值';
    }
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

  void _showRecordDialog(
    BuildContext context,
    WidgetRef ref,
    String trackerId,
    String userId,
    TrackerConfig config,
  ) {
    final theme = Theme.of(context);

    if (config is AnniversaryTrackerConfig) {
      bool isPreview = false;
      final contentCtrl = TextEditingController();

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('纪念日心情打卡'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('记录内容 (Markdown)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, icon: Icon(Icons.edit, size: 14), label: Text('撰写')),
                          ButtonSegment(value: true, icon: Icon(Icons.preview, size: 14), label: Text('实时预览')),
                        ],
                        selected: {isPreview},
                        onSelectionChanged: (set) => setDialogState(() => isPreview = set.first),
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!isPreview)
                    TextField(
                      controller: contentCtrl,
                      minLines: 4,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: '支持 Markdown，记录当下发生了什么、你的感受或想法...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 120),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      child: contentCtrl.text.trim().isEmpty
                          ? Text('暂无预览内容，请在撰写模式下输入', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                          : SimpleMarkdownRenderer(data: contentCtrl.text),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(
                onPressed: () {
                  ref.read(trackerRepositoryProvider).addRecord(
                        trackerId: trackerId,
                        value: null,
                        content: contentCtrl.text.trim().isEmpty ? null : contentCtrl.text.trim(),
                        currentUserId: userId,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final valCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    String labelText = '数值/状态 (可选)';
    TextInputType keyboardType = TextInputType.text;
    if (config is MilestoneTrackerConfig) {
      if (config.goalType == 'time') {
        labelText = '本次时长 (分钟数，如 30)';
        keyboardType = TextInputType.number;
      } else if (config.goalType == 'number') {
        labelText = '本次数值 (如 10.5)';
        keyboardType = const TextInputType.numberWithOptions(decimal: true);
      } else if (config.goalType == 'boolean') {
        labelText = '输入 true 或 false';
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valCtrl,
              keyboardType: keyboardType,
              decoration: InputDecoration(labelText: labelText, isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: '备注 (可选)', isDense: true),
            ),
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
}
