import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/notes/notes_providers.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';

/// 移动端与桌面端通用的现代化顶栏快速切库下拉组件
class RepoQuickSwitcher extends ConsumerWidget {
  const RepoQuickSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final myReposAsync = ref.watch(myReposStreamProvider);
    final subscribedReposAsync = ref.watch(subscribedReposStreamProvider);
    final selectedRepoId = ref.watch(selectedRepoIdProvider);

    final myRepos = myReposAsync.value ?? [];
    final subscribedRepos = subscribedReposAsync.value ?? [];
    final allRepos = [...myRepos, ...subscribedRepos];

    final currentRepo = allRepos.where((r) => r.id == selectedRepoId).firstOrNull;
    final currentTitle = currentRepo?.body.name ?? '选择笔记本';

    return PopupMenuButton<String>(
      tooltip: '快速切换笔记本',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onSelected: (repoId) {
        ref.read(selectedRepoIdProvider.notifier).state = repoId;
        ref.read(selectedPostIdProvider.notifier).state = null;
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        // 1. 我的小本本
        if (myRepos.isNotEmpty) {
          items.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 28,
              child: Text(
                '我的小本本 (${myRepos.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          );
          for (final repo in myRepos) {
            final isSelected = repo.id == selectedRepoId;
            items.add(
              PopupMenuItem<String>(
                value: repo.id,
                height: 36,
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        repo.body.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            );
          }
        }

        // 2. 订阅的小本本
        if (subscribedRepos.isNotEmpty) {
          if (items.isNotEmpty) {
            items.add(const PopupMenuDivider(height: 12));
          }
          items.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 28,
              child: Text(
                '订阅的小本本 (${subscribedRepos.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          );
          for (final repo in subscribedRepos) {
            final isSelected = repo.id == selectedRepoId;
            items.add(
              PopupMenuItem<String>(
                value: repo.id,
                height: 36,
                child: Row(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 16,
                      color: isSelected ? theme.colorScheme.secondary : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            repo.body.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.secondary : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '来自 @${repo.owner}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check, size: 16, color: theme.colorScheme.secondary),
                  ],
                ),
              ),
            );
          }
        }

        if (items.isEmpty) {
          items.add(
            const PopupMenuItem<String>(
              enabled: false,
              child: Text('无可用笔记本'),
            ),
          );
        }

        return items;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(100)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentRepo?.owner == ref.watch(authProvider).userId
                  ? Icons.folder_outlined
                  : Icons.share_outlined,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                currentTitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
