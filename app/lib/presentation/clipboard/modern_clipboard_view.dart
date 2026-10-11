import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class ModernClipboardView extends ConsumerWidget {
  const ModernClipboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entries = ref.watch(filteredClipboardEntriesProvider);
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
          // 列表内容
          Expanded(
            child: entriesAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : entries.isEmpty
                    ? const ModernEmptyState(
                        icon: Icons.content_paste_off_rounded,
                        title: '无剪贴板记录',
                        subtitle: '复制文本后即可在此处查看历史、快捷复用或备份',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          final entry = item.body;
                          return ModernCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ModernBadge(
                                      label: entry.localOnly ? '本地隐私 (ADR-0002)' : '已云端同步',
                                      color: entry.localOnly ? Colors.teal : Colors.blue,
                                      icon: entry.localOnly ? Icons.lock_outline : Icons.cloud_done_outlined,
                                    ),
                                    Text(
                                      entry.capturedAt?.toLocal().toString().split('.').first ?? '',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant.withAlpha(140),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  entry.data,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
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
                                      onPressed: () => ref.read(clipboardRepositoryProvider).delete(item.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
