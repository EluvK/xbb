import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/models/tracker/tracker_calculator.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/tracker/tracker_history_sheet.dart';
import 'package:xbb/presentation/tracker/tracker_providers.dart';
import 'package:xbb/presentation/widgets/acl_editor.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/sync/v2/uuid_service.dart';
import 'package:xbb/utils/translation.dart';

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
          'tracker_appbar_title'.tr,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'tracker_add_tooltip'.tr,
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTrackerDialog(context, ref, userId),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: trackersAsync.when(
        data: (trackers) {
          if (trackers.isEmpty) {
            return ModernEmptyState(
              icon: Icons.track_changes_rounded,
              title: 'tracker_empty_title'.tr,
              subtitle: 'tracker_empty_desc'.tr,
            );
          }

          // 按分类成组聚合
          final Map<String, List<DataItem<Tracker>>> groupedTrackers = {};
          for (final t in trackers) {
            final cat = t.body.category.trim().isEmpty ? 'tracker_default_category'.tr : t.body.category.trim();
            groupedTrackers.putIfAbsent(cat, () => []).add(t);
          }
          final sortedCategories = groupedTrackers.keys.toList()..sort();

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final int columns;
              if (maxWidth < 640) {
                columns = 1;
              } else if (maxWidth < 1024) {
                columns = 2;
              } else {
                columns = 3;
              }

              const spacing = AppSpacing.md;
              const pagePadding = AppSpacing.md;
              final availableWidth = maxWidth - (pagePadding * 2);
              final cardWidth = (availableWidth - (columns - 1) * spacing) / columns;

              final milestoneCount = trackers.where((t) => t.body.type == 'milestone').length;
              final eventCount = trackers.where((t) => t.body.type == 'event').length;
              final anniversaryCount = trackers.where((t) => t.body.type == 'anniversary').length;

              return ListView.builder(
                padding: const EdgeInsets.all(pagePadding),
                itemCount: sortedCategories.length + 1,
                itemBuilder: (context, catIndex) {
                  if (catIndex == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: ModernCard(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(Icons.insights_rounded, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: AppSpacing.xs),
                            Text('目标与指标概览简报', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Wrap(
                              spacing: 6,
                              children: [
                                ModernBadge(label: '里程碑 $milestoneCount', color: theme.colorScheme.primary),
                                ModernBadge(label: '习惯周期 $eventCount', color: Colors.indigo),
                                ModernBadge(label: '纪念日 $anniversaryCount', color: Colors.deepPurple),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final category = sortedCategories[catIndex - 1];
                  final items = groupedTrackers[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${items.length})',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: items.map((tracker) {
                          return SizedBox(
                            width: cardWidth,
                            child: ModernTrackerCard(
                              key: ValueKey('tracker-${tracker.id}'),
                              tracker: tracker,
                              userId: userId,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  );
                },
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
    final categoryCtrl = TextEditingController(text: '默认');
    final targetValCtrl = TextEditingController(text: '100');
    final periodCtrl = TextEditingController(text: '1');
    String selectedType = 'milestone';
    String goalType = 'number';
    String progressMode = 'accumulate';
    String remindType = 'per_year';
    DateTime selectedBaseDate = DateTime.now();
    bool isLunar = false;

    showAdaptiveModal(
      context,
      maxWidth: 520,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AdaptiveModalContainer(
          title: '新建追踪器',
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
                      category: categoryCtrl.text.trim().isEmpty ? '默认' : categoryCtrl.text.trim(),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '名称', prefixIcon: const Icon(Icons.title, size: 20)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '描述 (可选)', prefixIcon: const Icon(Icons.notes, size: 20)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '分类 (如 学习、健身、生活)', prefixIcon: const Icon(Icons.category_outlined, size: 20)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: ModernInputDecoration.field(ctx, labelText: '类型'),
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
                  decoration: ModernInputDecoration.field(ctx, labelText: '目标类型'),
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
                  decoration: ModernInputDecoration.field(ctx, labelText: '计算模式'),
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
                    decoration: ModernInputDecoration.field(
                      ctx,
                      labelText: goalType == 'time' ? '目标时长 (分钟数，如 120)' : '目标数值 (如 100)',
                      prefixIcon: const Icon(Icons.track_changes, size: 20),
                    ),
                  ),
                ],
              ] else if (selectedType == 'event') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: periodCtrl,
                  keyboardType: TextInputType.number,
                  decoration: ModernInputDecoration.field(
                    ctx,
                    labelText: '周期天数 (0 为自由打卡)',
                    prefixIcon: const Icon(Icons.repeat, size: 20),
                  ),
                ),
              ] else if (selectedType == 'anniversary') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: remindType,
                  decoration: ModernInputDecoration.field(ctx, labelText: '提醒与推算类型'),
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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => TrackerHistorySheet.show(context, tracker: tracker, userId: userId),
      onDoubleTap: () => _handleQuickCheckin(context, ref, tracker, records, userId),
      child: ModernCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(_getIconForType(body.type), color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          body.name,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                ModernBadge(label: _getTypeLabel(body.type)),
              ],
            ),
            if (body.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                body.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildConfigDetail(context, body.config, records),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_rounded, size: 18),
                      tooltip: '快速历史明细',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => TrackerHistorySheet.show(context, tracker: tracker, userId: userId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, size: 19),
                      tooltip: '全屏深度分析',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/tracker/view-tracker', extra: tracker),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      tooltip: '协同权限与成员',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => AclEditor.show(
                        context,
                        table: 'tracker',
                        entityId: tracker.id,
                        entityTitle: tracker.body.name,
                        ownerId: tracker.owner,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: '编辑追踪器',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showEditTrackerDialog(context, ref, tracker),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('打卡'),
                      onPressed: () => _showRecordDialog(context, ref, tracker.id, userId, body.config),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: '删除追踪器',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDeleteTracker(context, ref, tracker),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickCheckin(
    BuildContext context,
    WidgetRef ref,
    DataItem<Tracker> item,
    List<TrackerRecord> records,
    String userId,
  ) {
    HapticFeedback.mediumImpact();
    final config = item.body.config;
    final repo = ref.read(trackerRepositoryProvider);

    if (config is EventTrackerConfig) {
      repo.addRecord(
        trackerId: item.id,
        value: null,
        content: null,
        currentUserId: userId,
      );
      _showQuickFeedback(context, item.body.name);
    } else if (config is MilestoneTrackerConfig) {
      if (config.goalType == 'boolean') {
        repo.addRecord(
          trackerId: item.id,
          value: 'true',
          content: null,
          currentUserId: userId,
        );
        _showQuickFeedback(context, item.body.name);
      } else {
        // 如果有历史记录，默认复用最新一次的值快捷打卡
        final latest = records.isNotEmpty ? records.first.value : null;
        if (latest != null && latest.isNotEmpty) {
          repo.addRecord(
            trackerId: item.id,
            value: latest,
            content: null,
            currentUserId: userId,
          );
          _showQuickFeedback(context, '${item.body.name} (+$latest)');
        } else {
          // 无历史记录则直接呼出录入对话框
          _showRecordDialog(context, ref, item.id, userId, config);
        }
      }
    } else {
      _showRecordDialog(context, ref, item.id, userId, config);
    }
  }

  void _showQuickFeedback(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Text('已为 “$title” 快捷打卡成功'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDeleteTracker(BuildContext context, WidgetRef ref, DataItem<Tracker> item) async {
    final confirm = await showAdaptiveConfirmDialog(
      context,
      title: '删除追踪器 “${item.body.name}”？',
      message: '该操作将级联删除该追踪器及其所有历史打卡记录，无法恢复。',
      confirmText: '确认删除',
      isDanger: true,
    );
    if (confirm == true) {
      ref.read(trackerRepositoryProvider).deleteTracker(item.id);
    }
  }

  void _showEditTrackerDialog(BuildContext context, WidgetRef ref, DataItem<Tracker> item) {
    final body = item.body;
    final nameCtrl = TextEditingController(text: body.name);
    final descCtrl = TextEditingController(text: body.description);
    final categoryCtrl = TextEditingController(text: body.category);
    final config = body.config;

    final targetValCtrl = TextEditingController(
      text: config is MilestoneTrackerConfig ? config.targetValue : '100',
    );
    final periodCtrl = TextEditingController(
      text: config is EventTrackerConfig ? config.periodDays.toString() : '1',
    );
    String progressMode = config is MilestoneTrackerConfig ? config.progressMode : 'accumulate';

    showAdaptiveModal(
      context,
      maxWidth: 520,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AdaptiveModalContainer(
          title: '编辑追踪器',
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  TrackerConfig updatedConfig = config;
                  if (config is MilestoneTrackerConfig) {
                    updatedConfig = config.copyWith(
                      targetValue: targetValCtrl.text.trim().isEmpty ? config.targetValue : targetValCtrl.text.trim(),
                      progressMode: progressMode,
                    );
                  } else if (config is EventTrackerConfig) {
                    final p = int.tryParse(periodCtrl.text.trim()) ?? config.periodDays;
                    updatedConfig = config.copyWith(periodDays: p);
                  }

                  final updatedItem = DataItem<Tracker>(
                    item.id,
                    item.createdAt,
                    DateTime.now(),
                    item.owner,
                    null,
                    null,
                    body: body.copyWith(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      category: categoryCtrl.text.trim().isEmpty ? '默认' : categoryCtrl.text.trim(),
                      config: updatedConfig,
                    ),
                  );
                  ref.read(trackerRepositoryProvider).updateTracker(updatedItem);
                }
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '名称', prefixIcon: const Icon(Icons.title, size: 20)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '描述 (可选)', prefixIcon: const Icon(Icons.notes, size: 20)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '分类', prefixIcon: const Icon(Icons.category_outlined, size: 20)),
              ),
              if (config is MilestoneTrackerConfig && config.goalType != 'boolean') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: targetValCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: ModernInputDecoration.field(
                    ctx,
                    labelText: config.goalType == 'time' ? '目标时长 (分钟)' : '目标数值',
                    prefixIcon: const Icon(Icons.track_changes, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: progressMode,
                  decoration: ModernInputDecoration.field(ctx, labelText: '计算模式'),
                  items: const [
                    DropdownMenuItem(value: 'accumulate', child: Text('累计求和 (Accumulate)')),
                    DropdownMenuItem(value: 'latest', child: Text('最新一次值 (Latest)')),
                  ],
                  onChanged: (v) => setState(() => progressMode = v ?? 'accumulate'),
                ),
              ] else if (config is EventTrackerConfig) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: periodCtrl,
                  keyboardType: TextInputType.number,
                  decoration: ModernInputDecoration.field(
                    ctx,
                    labelText: '周期天数 (0 为自由打卡)',
                    prefixIcon: const Icon(Icons.repeat, size: 20),
                  ),
                ),
              ],
            ],
          ),
        ),
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

      showAdaptiveModal(
        context,
        maxWidth: 520,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AdaptiveModalContainer(
            title: '纪念日心情打卡',
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
            child: SizedBox(
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
                      decoration: ModernInputDecoration.field(
                        ctx,
                        hintText: '支持 Markdown，记录当下发生了什么、你的感受或想法...',
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
          ),
        ),
      );
      return;
    }

    final valCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    String labelText = '数值/状态 (可选)';
    TextInputType keyboardType = TextInputType.text;
    final bool isTimeMilestone = config is MilestoneTrackerConfig && config.goalType == 'time';

    if (config is MilestoneTrackerConfig) {
      if (config.goalType == 'time') {
        labelText = '本次时长 (分钟数)';
        keyboardType = TextInputType.number;
      } else if (config.goalType == 'number') {
        labelText = '本次数值 (如 10.5)';
        keyboardType = const TextInputType.numberWithOptions(decimal: true);
      } else if (config.goalType == 'boolean') {
        labelText = '输入 true 或 false';
      }
    }

    showAdaptiveModal(
      context,
      maxWidth: 520,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AdaptiveModalContainer(
          title: '添加打卡记录',
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isTimeMilestone) ...[
                const Text('快捷时长选项:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('+15m'),
                      avatar: const Icon(Icons.timer_outlined, size: 14),
                      onPressed: () {
                        final cur = int.tryParse(valCtrl.text.trim()) ?? 0;
                        setDialogState(() => valCtrl.text = (cur + 15).toString());
                      },
                    ),
                    ActionChip(
                      label: const Text('+30m'),
                      avatar: const Icon(Icons.timer_outlined, size: 14),
                      onPressed: () {
                        final cur = int.tryParse(valCtrl.text.trim()) ?? 0;
                        setDialogState(() => valCtrl.text = (cur + 30).toString());
                      },
                    ),
                    ActionChip(
                      label: const Text('+1h (60m)'),
                      avatar: const Icon(Icons.timer_outlined, size: 14),
                      onPressed: () {
                        final cur = int.tryParse(valCtrl.text.trim()) ?? 0;
                        setDialogState(() => valCtrl.text = (cur + 60).toString());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: valCtrl,
                keyboardType: keyboardType,
                decoration: ModernInputDecoration.field(ctx, labelText: labelText, prefixIcon: const Icon(Icons.pin, size: 20)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '备注/笔记 (可选)', prefixIcon: const Icon(Icons.notes, size: 20)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
