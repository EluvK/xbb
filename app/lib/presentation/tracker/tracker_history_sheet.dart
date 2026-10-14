import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/presentation/tracker/tracker_providers.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

/// 追踪器历史明细流水侧滑板
class TrackerHistorySheet extends ConsumerWidget {
  final DataItem<Tracker> tracker;
  final String userId;

  const TrackerHistorySheet({
    super.key,
    required this.tracker,
    required this.userId,
  });

  static Future<void> show(
    BuildContext context, {
    required DataItem<Tracker> tracker,
    required String userId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackerHistorySheet(tracker: tracker, userId: userId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recordsAsync = ref.watch(trackerRecordsProvider(tracker.id));
    final records = recordsAsync.valueOrNull ?? <DataItem<TrackerRecord>>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部拖拽把手与标题
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                tracker.body.name,
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              ModernBadge(label: tracker.body.category),
                            ],
                          ),
                          if (tracker.body.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              tracker.body.description,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 概览与历史统计
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '历史打卡流水 (${records.length} 条)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '按时间倒序',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // 流水列表
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: ModernEmptyState(
                          icon: Icons.history_rounded,
                          title: '暂无打卡流水',
                          subtitle: '点击卡片右上角或下方按钮添加第一条打卡记录',
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (ctx, index) {
                          final item = records[index];
                          final rec = item.body;
                          return _buildRecordTile(context, ref, item, rec);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordTile(
    BuildContext context,
    WidgetRef ref,
    DataItem<TrackerRecord> item,
    TrackerRecord rec,
  ) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(rec.timestamp.toLocal());
    final hasContent = rec.content != null && rec.content!.trim().isNotEmpty;
    final hasValue = rec.value != null && rec.value!.trim().isNotEmpty;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 15, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rec.value!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: '编辑记录',
                    onPressed: () => _showEditRecordDialog(context, ref, item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: '删除记录',
                    onPressed: () => _confirmDeleteRecord(context, ref, item.id),
                  ),
                ],
              ),
            ],
          ),
          if (hasContent) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SimpleMarkdownRenderer(data: rec.content!),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditRecordDialog(
    BuildContext context,
    WidgetRef ref,
    DataItem<TrackerRecord> item,
  ) {
    final valCtrl = TextEditingController(text: item.body.value ?? '');
    final contentCtrl = TextEditingController(text: item.body.content ?? '');
    DateTime recordTime = item.body.timestamp.toLocal();

    showAdaptiveModal(
      context,
      maxWidth: 500,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AdaptiveModalContainer(
          title: '编辑打卡记录',
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                final updated = DataItem<TrackerRecord>(
                  item.id,
                  item.createdAt,
                  DateTime.now(),
                  item.owner,
                  item.parentId,
                  null,
                  body: item.body.copyWith(
                    timestamp: recordTime,
                    value: valCtrl.text.trim().isEmpty ? null : valCtrl.text.trim(),
                    content: contentCtrl.text.trim().isEmpty ? null : contentCtrl.text.trim(),
                  ),
                );
                ref.read(trackerRepositoryProvider).updateRecord(updated);
                Navigator.pop(ctx);
              },
              child: const Text('保存修改'),
            ),
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('记录时间', style: TextStyle(fontSize: 14)),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(recordTime)),
                trailing: const Icon(Icons.schedule, size: 18),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: recordTime,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null && context.mounted) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(recordTime),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        recordTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: valCtrl,
                decoration: ModernInputDecoration.field(ctx, labelText: '数值/状态 (可选)', prefixIcon: const Icon(Icons.pin, size: 20)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: ModernInputDecoration.field(
                  ctx,
                  labelText: '内容/笔记 (支持 Markdown)',
                  hintText: '输入打卡记录详情...',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRecord(BuildContext context, WidgetRef ref, String recordId) async {
    final confirm = await showAdaptiveConfirmDialog(
      context,
      title: '确认删除记录？',
      message: '删除后该条记录将从打卡历史与统计中移除。',
      confirmText: '确认删除',
      isDanger: true,
    );
    if (confirm == true) {
      ref.read(trackerRepositoryProvider).deleteRecord(recordId);
    }
  }
}
