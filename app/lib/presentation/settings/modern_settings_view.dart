import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/presentation/providers/sync_provider.dart';
import 'package:xbb/presentation/widgets/avatar_helper.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class ModernSettingsView extends ConsumerWidget {
  const ModernSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final auth = ref.watch(authProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('设置中心', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 用户信息与账号卡片
          ModernCard(
            onTap: () => context.push('/profile'),
            child: Row(
              children: [
                UserAvatarWidget(
                  avatar: auth.avatar,
                  fallbackName: auth.nickname.isNotEmpty ? auth.nickname : auth.username,
                  radius: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.isLoggedIn
                            ? (auth.nickname.isNotEmpty ? auth.nickname : auth.username)
                            : '本地账户 (${auth.userId})',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.isLoggedIn ? '@${auth.username} • 点击管理资料' : '离线本地单机模式 • 点击登录',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ModernBadge(
                  label: auth.isLoggedIn ? '已登录' : '离线可用',
                  color: auth.isLoggedIn ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 云端同步服务
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Local-First 同步状态', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ModernBadge(
                      label: syncStatus.state == SyncRunningState.syncing
                          ? '正在同步...'
                          : syncStatus.state == SyncRunningState.error
                              ? '同步异常'
                              : '已就绪',
                      color: syncStatus.state == SyncRunningState.error ? Colors.red : Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '基于 Rust ChangeLog 增量变更流引擎与本地 Outbox 队列，离线随时写入，联网自动同步。',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.sync, size: 16),
                      label: const Text('立即检查同步'),
                      onPressed: () {
                        ref.read(syncStatusProvider.notifier).triggerSync();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已触发增量同步检查')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 外观与主题
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('外观与排版', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('深浅模式'),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('系统')),
                      ButtonSegment(value: ThemeMode.light, label: Text('明亮')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('深邃')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (set) {
                      ref.read(appSettingsProvider.notifier).setThemeMode(set.first);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('字体缩放'),
                  subtitle: Text('${(settings.fontScale * 100).toInt()}%'),
                  trailing: SizedBox(
                    width: 160,
                    child: Slider(
                      value: settings.fontScale,
                      min: 0.8,
                      max: 1.4,
                      divisions: 6,
                      onChanged: (v) {
                        ref.read(appSettingsProvider.notifier).setFontScale(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 功能模块开关
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('功能模块管理', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('待办任务 (Task)'),
                  value: settings.taskEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(task: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('个人笔记 (Notes)'),
                  value: settings.notesEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(notes: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('目标追踪 (Tracker)'),
                  value: settings.trackerEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(tracker: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('习惯打卡 (Checkin)'),
                  value: settings.checkinEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(checkin: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('剪贴板备份 (Clipboard)'),
                  value: settings.clipboardEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(clipboard: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('AI 对话助手 (Chat)'),
                  value: settings.chatEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(chat: v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
