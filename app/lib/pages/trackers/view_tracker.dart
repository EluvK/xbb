import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/models/tracker/tracker_calculator.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/tracker/tracker_providers.dart';
import 'package:xbb/presentation/widgets/acl_editor.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

/// 独立的追踪器全屏详情与深度时序分析页 (ViewTrackerDetailPage)
class ViewTrackerDetailPage extends ConsumerStatefulWidget {
  final DataItem<Tracker>? trackerItem;
  final String? trackerId;

  const ViewTrackerDetailPage({
    super.key,
    this.trackerItem,
    this.trackerId,
  });

  @override
  ConsumerState<ViewTrackerDetailPage> createState() => _ViewTrackerDetailPageState();
}

class _ViewTrackerDetailPageState extends ConsumerState<ViewTrackerDetailPage> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  DateTime _recordTimestamp = DateTime.now();
  bool _isEditingRecord = false;
  String? _editingRecordId;
  bool _showRecordInput = false;

  @override
  void dispose() {
    _valueController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _resetInputState() {
    setState(() {
      _showRecordInput = false;
      _isEditingRecord = false;
      _editingRecordId = null;
      _recordTimestamp = DateTime.now();
      _valueController.clear();
      _contentController.clear();
    });
  }

  void _startEditRecord(DataItem<TrackerRecord> rec) {
    setState(() {
      _showRecordInput = true;
      _isEditingRecord = true;
      _editingRecordId = rec.id;
      _recordTimestamp = rec.body.timestamp;
      _valueController.text = rec.body.value ?? '';
      _contentController.text = rec.body.content ?? '';
    });
  }

  Future<void> _submitRecord(DataItem<Tracker> tracker, String userId) async {
    final valueText = _valueController.text.trim();
    final contentText = _contentController.text.trim();

    if (_isEditingRecord && _editingRecordId != null) {
      final records = ref.read(trackerRecordsProvider(tracker.id)).value ?? [];
      final old = records.where((r) => r.id == _editingRecordId).firstOrNull;
      if (old != null) {
        final updated = old.updatedBody(
          old.body.copyWith(
            timestamp: _recordTimestamp,
            value: valueText.isNotEmpty ? valueText : null,
            content: contentText.isNotEmpty ? contentText : null,
          ),
        );
        await ref.read(trackerRepositoryProvider).updateRecord(updated);
      }
    } else {
      await ref.read(trackerRepositoryProvider).addRecord(
        trackerId: tracker.id,
        currentUserId: userId,
        value: valueText.isNotEmpty ? valueText : null,
        content: contentText.isNotEmpty ? contentText : null,
        timestamp: _recordTimestamp,
      );
    }
    _resetInputState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = ref.watch(authProvider).userId;

    // 解析当前选中的 Tracker
    final state = GoRouterState.of(context);
    DataItem<Tracker>? tracker = widget.trackerItem ?? (state.extra is DataItem<Tracker> ? state.extra as DataItem<Tracker> : null);
    final targetId = widget.trackerId ?? state.uri.queryParameters['id'] ?? tracker?.id;

    if (tracker == null && targetId != null) {
      final trackers = ref.watch(trackersStreamProvider).value ?? [];
      tracker = trackers.where((t) => t.id == targetId).firstOrNull;
    }

    if (tracker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('追踪器详情')),
        body: const ModernEmptyState(
          icon: Icons.track_changes_outlined,
          title: '未找到指定追踪器',
          subtitle: '请返回列表重新选择',
        ),
      );
    }

    final t = tracker.body;
    final recordsAsync = ref.watch(trackerRecordsProvider(tracker.id));
    final records = recordsAsync.value ?? [];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(t.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: '权限与协作者',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              AclEditor.show(
                context,
                table: 'tracker',
                entityId: tracker!.id,
                entityTitle: tracker.body.name,
                ownerId: tracker.owner,
              );
            },
          ),
          IconButton(
            tooltip: _showRecordInput ? '取消' : '添加记录',
            icon: Icon(_showRecordInput ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                if (_showRecordInput) {
                  _resetInputState();
                } else {
                  _showRecordInput = true;
                }
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部核心指标进度卡片
            ModernCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.category.isEmpty ? '默认' : t.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        t.type.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                      const Spacer(),
                      Text(
                        '总记录 ${records.length} 次',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                  if (t.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.description,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _buildProgressIndicator(context, tracker, records),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 记录录入/编辑输入面板
            if (_showRecordInput) ...[
              ModernCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_calendar_rounded, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _isEditingRecord ? '编辑打卡记录' : '新增打卡记录',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (t.type == 'milestone') ...[
                      TextField(
                        controller: _valueController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: ModernInputDecoration.field(
                          context,
                          labelText: '完成数值 / 时长 (分钟)',
                          prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // 快捷时长按钮
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('+15m'),
                            onPressed: () => setState(() => _valueController.text = '15'),
                          ),
                          ActionChip(
                            label: const Text('+30m'),
                            onPressed: () => setState(() => _valueController.text = '30'),
                          ),
                          ActionChip(
                            label: const Text('+60m'),
                            onPressed: () => setState(() => _valueController.text = '60'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    TextField(
                      controller: _contentController,
                      maxLines: t.type == 'anniversary' ? 4 : 2,
                      decoration: ModernInputDecoration.field(
                        context,
                        labelText: t.type == 'anniversary' ? '纪念日心情 / Markdown 随笔' : '备注文字 (可选)',
                        prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => _submitRecord(tracker!, userId),
                        child: Text(_isEditingRecord ? '保存修改' : '确认添加'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 历史明细流水时间线
            Row(
              children: [
                Icon(Icons.timeline_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text('历史时序流水', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            if (records.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: ModernEmptyState(
                  icon: Icons.history_rounded,
                  title: '暂无打卡记录',
                  subtitle: '点击右上角 “+” 记下第一笔吧',
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final rec = records[index];
                  final dt = rec.body.timestamp.toLocal();
                  final timeLabel = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                  return ModernCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.check, size: 14, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(timeLabel, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  if (rec.body.value != null && rec.body.value!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    ModernBadge(label: rec.body.value!, color: theme.colorScheme.primary),
                                  ],
                                ],
                              ),
                              if (rec.body.content != null && rec.body.content!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(rec.body.content!, style: theme.textTheme.bodySmall),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          tooltip: '编辑',
                          onPressed: () => _startEditRecord(rec),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
                          tooltip: '删除',
                          onPressed: () => ref.read(trackerRepositoryProvider).deleteRecord(rec.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, DataItem<Tracker> tracker, List<DataItem<TrackerRecord>> records) {
    final theme = Theme.of(context);
    final cfg = tracker.body.config;
    final rawRecords = records.map((e) => e.body).toList();

    return cfg.map(
      milestone: (c) {
        final progress = TrackerCalculator.calculateMilestone(config: c, records: rawRecords);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.displayCurrent} / ${progress.displayTarget}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  progress.percentText,
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.progress.clamp(0.0, 1.0),
                minHeight: 8,
              ),
            ),
          ],
        );
      },
      event: (c) {
        final status = TrackerCalculator.calculateEvent(config: c, records: rawRecords);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('距上次打卡：${status.passedDays}天前', style: theme.textTheme.bodyMedium),
            ModernBadge(
              label: status.statusText,
              color: status.statusColor,
            ),
          ],
        );
      },
      anniversary: (c) {
        final status = TrackerCalculator.calculateAnniversary(config: c);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status.titleText, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(status.subtitleText, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
          ],
        );
      },
    );
  }
}
