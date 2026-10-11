import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/clipboard/clipboard_batch_action_bar.dart';
import 'package:xbb/presentation/clipboard/clipboard_date_group_view.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class ModernClipboardView extends ConsumerWidget {
  const ModernClipboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = ref.watch(groupedClipboardEntriesProvider);
    final collapsedDates = ref.watch(collapsedClipboardDatesProvider);
    final entriesAsync = ref.watch(clipboardEntriesStreamProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '剪贴板历史',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '清空历史记录',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('清空剪贴板历史'),
                  content: const Text('确认清空本地所有剪贴板记录吗？此操作不可撤销。'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(clipboardRepositoryProvider).clearAll();
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // 搜索过滤栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: ModernSearchField(
              hintText: '搜索剪贴板文本...',
              onChanged: (v) => ref.read(clipboardSearchQueryProvider.notifier).state = v,
            ),
          ),
          // 列表内容（按日期分组并支持折叠/展开）
          Expanded(
            child: entriesAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groups.isEmpty
                    ? const ModernEmptyState(
                        icon: Icons.content_paste_off_rounded,
                        title: '无剪贴板记录',
                        subtitle: '复制文本后即可在此处查看历史、快捷复用或备份',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final isCollapsed = collapsedDates.contains(group.dateKey);
                          return ClipboardDateGroupView(
                            group: group,
                            isCollapsed: isCollapsed,
                          );
                        },
                      ),
          ),
          const ClipboardBatchActionBar(),
        ],
      ),
    );
  }
}
