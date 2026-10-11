import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/presentation/task/task_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

/// 归档历史管理主视图
class TaskHistoryView extends ConsumerStatefulWidget {
  final int initialPageSize;
  final int pageSizeIncrement;

  const TaskHistoryView({
    super.key,
    this.initialPageSize = 5,
    this.pageSizeIncrement = 5,
  });

  @override
  ConsumerState<TaskHistoryView> createState() => _TaskHistoryViewState();
}

class _TaskHistoryViewState extends ConsumerState<TaskHistoryView> {
  late int _currentLimit;
  final Set<String> _expandedSegmentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.initialPageSize;
  }

  void _loadMore() {
    setState(() {
      _currentLimit += widget.pageSizeIncrement;
    });
  }

  void _toggleExpanded(String segmentId) {
    setState(() {
      if (_expandedSegmentIds.contains(segmentId)) {
        _expandedSegmentIds.remove(segmentId);
      } else {
        _expandedSegmentIds.add(segmentId);
      }
    });
  }

  Future<void> _confirmDeleteSegment(BuildContext context, String segmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除历史记录'),
        content: const Text('确认删除此段归档历史吗？删除后本地与云端将同步永久移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(taskRepositoryProvider).deleteArchivedSegment(segmentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segmentsAsync = ref.watch(archivedSegmentsCumulativeProvider(_currentLimit));

    return segmentsAsync.when(
      data: (segments) {
        if (segments.isEmpty) {
          return const ModernEmptyState(
            icon: Icons.archive_outlined,
            title: '无归档记录',
            subtitle: '当活动清单中已完成的任务被归档后，将按历史时间段在此陈列',
          );
        }

        final hasMore = segments.length >= _currentLimit;

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: segments.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            if (index == segments.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(
                  child: hasMore
                      ? OutlinedButton.icon(
                          onPressed: _loadMore,
                          icon: const Icon(Icons.expand_more_rounded, size: 18),
                          label: const Text('加载更多历史 (Load more history)'),
                        )
                      : Text(
                          '— 已加载全部历史记录 —',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
                          ),
                        ),
                ),
              );
            }

            final segment = segments[index];
            final tasks = decodeTaskItems(segment.body.tasks);
            final isExpanded = _expandedSegmentIds.contains(segment.id);

            return _ArchivedSegmentTile(
              key: ValueKey('segment-${segment.id}'),
              segment: segment,
              tasks: tasks,
              isExpanded: isExpanded,
              onToggleExpanded: () => _toggleExpanded(segment.id),
              onDelete: () => _confirmDeleteSegment(context, segment.id),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载历史失败: $e')),
    );
  }
}

/// 单个归档历史段落卡片，支持展开/折叠与单段删除
class _ArchivedSegmentTile extends StatelessWidget {
  final DataItem<CheckList> segment;
  final List<TaskItem> tasks;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onDelete;

  const _ArchivedSegmentTile({
    super.key,
    required this.segment,
    required this.tasks,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final archivedAt = segment.body.archivedAt ?? segment.createdAt;
    final timeStr = archivedAt.toLocal().toString().split('.').first;
    final doneTasksCount = tasks.where((t) => t.done).length;

    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 卡片头部（点击可折叠/展开）
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: AppRadius.roundedMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '归档时间: $timeStr',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '包含 ${tasks.length} 项任务 ($doneTasksCount 项已完成)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ModernBadge(
                    label: '${tasks.length} 项',
                    color: theme.colorScheme.primaryContainer,
                  ),
                  IconButton(
                    tooltip: '删除此历史段落',
                    icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error.withAlpha(180)),
                    onPressed: onDelete,
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // 展开的任务项列表
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: tasks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Text('该历史段没有任务项', style: theme.textTheme.bodySmall),
                    )
                  : Column(
                      children: tasks.map((task) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                task.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 16,
                                color: task.done ? Colors.green : theme.colorScheme.onSurfaceVariant.withAlpha(120),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  task.content,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    decoration: task.done ? TextDecoration.lineThrough : null,
                                    color: task.done
                                        ? theme.colorScheme.onSurfaceVariant.withAlpha(130)
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (task.doneAt != null)
                                Text(
                                  task.doneAt!.toLocal().toString().split('.').first.split(' ').last,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 底部抽屉模式展示归档历史
class TaskHistorySheet extends StatelessWidget {
  const TaskHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const TaskHistorySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        children: [
          // 顶部把手与标题
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '已归档清单历史',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
              ],
            ),
          ),
          const Expanded(
            child: TaskHistoryView(),
          ),
        ],
      ),
    );
  }
}
