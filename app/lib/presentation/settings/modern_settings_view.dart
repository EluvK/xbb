import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/presentation/providers/sync_provider.dart';
import 'package:xbb/presentation/widgets/avatar_helper.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/utils/translation.dart';

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
        title: Text('settings_center'.tr, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                            : 'account_local_user'.trParams({'id': auth.userId}),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.isLoggedIn
                            ? 'account_profile_click_hint'.trParams({'username': auth.username})
                            : 'account_login_click_hint'.tr,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ModernBadge(
                  label: auth.isLoggedIn ? 'account_logged_in'.tr : 'account_offline_ready'.tr,
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
                    Text('sync_status_title'.tr, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ModernBadge(
                      label: syncStatus.state == SyncRunningState.syncing
                          ? 'sync_status_syncing'.tr
                          : syncStatus.state == SyncRunningState.error
                              ? 'sync_status_error'.tr
                              : 'sync_status_ready'.tr,
                      color: syncStatus.state == SyncRunningState.error ? Colors.red : Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'sync_status_desc'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.sync, size: 16),
                      label: Text('sync_trigger_check'.tr),
                      onPressed: () {
                        ref.read(syncStatusProvider.notifier).triggerSync();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('sync_triggered_snack'.tr)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 外观与排版
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('appearance_and_typography'.tr, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('theme_mode_title'.tr),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(value: ThemeMode.system, label: Text('theme_mode_system'.tr)),
                      ButtonSegment(value: ThemeMode.light, label: Text('theme_mode_light'.tr)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('theme_mode_dark'.tr)),
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
                  title: Text('language_setting'.tr),
                  trailing: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'system', label: Text('language_system'.tr)),
                      ButtonSegment(value: 'zh', label: Text('language_zh'.tr)),
                      ButtonSegment(value: 'en', label: Text('language_en'.tr)),
                    ],
                    selected: {settings.languageCode},
                    onSelectionChanged: (set) {
                      ref.read(appSettingsProvider.notifier).setLanguageCode(set.first);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('font_scale_title'.tr),
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
                Text('feature_management_title'.tr, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('feature_task'.tr),
                  value: settings.taskEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(task: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('feature_notes'.tr),
                  value: settings.notesEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(notes: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('feature_tracker'.tr),
                  value: settings.trackerEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(tracker: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('feature_checkin'.tr),
                  value: settings.checkinEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(checkin: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('feature_clipboard'.tr),
                  value: settings.clipboardEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(clipboard: v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('feature_chat'.tr),
                  value: settings.chatEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).toggleFeature(chat: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 桌面系统托盘与剪贴板监听 (Desktop Tray & Clipboard)
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('tray_and_clipboard_title'.tr, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ModernBadge(
                      label: settings.clipboardListeningEnabled ? 'tray_listening'.tr : 'tray_paused'.tr,
                      color: settings.clipboardListeningEnabled ? Colors.teal : Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'tray_desc'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('tray_enable_listening'.tr),
                  subtitle: Text('tray_enable_listening_subtitle'.tr),
                  value: settings.clipboardListeningEnabled,
                  onChanged: (v) => ref.read(appSettingsProvider.notifier).setClipboardListeningEnabled(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 桌面小部件 (Desktop / Home Widget)
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('home_widget_title'.tr, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const ModernBadge(label: 'Android / iOS', color: Colors.teal),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'home_widget_desc'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.widgets_outlined, size: 16),
                      label: Text('home_widget_add_btn'.tr),
                      onPressed: () async {
                        final pinned = await TaskWidgetBridge.requestPinWidget();
                        if (context.mounted) {
                          if (pinned) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('home_widget_requested_snack'.tr)),
                            );
                          } else {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('home_widget_guide_title'.tr),
                                content: Text('home_widget_guide_content'.tr),
                                actions: [
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text('home_widget_guide_confirm'.tr),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
