import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xbb/components/common/ping_latency_inline.dart';
import 'package:xbb/controller/checkin_widget.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/core/update/app_update_service.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/server_health_provider.dart';
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

          // SyncStore 同步服务器与实时测速 (TASK-6.2)
          const _SyncStoreServerCard(),
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

          // 功能模块开关与默认启动页 (TASK-6.3)
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
                const Divider(),
                // 默认启动页下拉选择 (TASK-6.3)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('startup_page_title'.tr),
                  subtitle: Text('startup_page_desc'.tr),
                  trailing: DropdownButton<int>(
                    value: settings.startupTabIndex,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: AppHomeStartupTabIndex.notes, child: Text('home_bar_title_notes'.tr)),
                      DropdownMenuItem(value: AppHomeStartupTabIndex.task, child: Text('home_bar_title_task'.tr)),
                      DropdownMenuItem(value: AppHomeStartupTabIndex.checkin, child: Text('home_bar_title_checkin'.tr)),
                      DropdownMenuItem(value: AppHomeStartupTabIndex.tracker, child: Text('home_bar_title_tracker'.tr)),
                      DropdownMenuItem(value: AppHomeStartupTabIndex.clipboard, child: Text('home_bar_title_clipboard'.tr)),
                      DropdownMenuItem(value: AppHomeStartupTabIndex.chat, child: Text('home_bar_title_chat'.tr)),
                      DropdownMenuItem(value: AppHomeStartupTabIndex.settings, child: Text('home_bar_title_setting'.tr)),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(appSettingsProvider.notifier).setStartupTabIndex(val);
                      }
                    },
                  ),
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

          // 桌面小部件添加中心 (Home Widget Center - TASK-6.3)
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

                // 1. 待办事项插件快捷操作
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.checklist_rounded, size: 24),
                  title: Text('task_widget_label'.tr),
                  trailing: FilledButton.tonalIcon(
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
                ),
                const Divider(),

                // 2. 打卡项目插件快捷操作
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined, size: 24),
                  title: Text('checkin_widget_label'.tr),
                  trailing: FilledButton.tonalIcon(
                    icon: const Icon(Icons.widgets_outlined, size: 16),
                    label: Text('add_checkin_widget_title'.tr),
                    onPressed: () async {
                      final pinned = await CheckinWidgetBridge.requestPinWidget();
                      if (context.mounted) {
                        if (pinned) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('home_widget_requested_snack'.tr)),
                          );
                        } else {
                          showDialog<void>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('add_checkin_widget_title'.tr),
                              content: Text('add_checkin_widget_guide_message'.tr),
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
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 版本信息与软件在线更新 (TASK-6.4)
          const _AppVersionUpdateCard(),
        ],
      ),
    );
  }
}

/// SyncStore 同步服务器地址配置与实时 Ping 测速卡片 (TASK-6.2)
class _SyncStoreServerCard extends ConsumerStatefulWidget {
  const _SyncStoreServerCard();

  @override
  ConsumerState<_SyncStoreServerCard> createState() => _SyncStoreServerCardState();
}

class _SyncStoreServerCardState extends ConsumerState<_SyncStoreServerCard> {
  late final TextEditingController _urlController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(appSettingsProvider).syncStoreUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final text = _urlController.text.trim();
    if (text.isEmpty) return;

    await ref.read(appSettingsProvider.notifier).updateSyncStoreUrl(text);
    await ref.read(serverHealthProvider.notifier).updateServerUrl(text);
    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('syncstore_server_saved'.tr)),
      );
    }
  }

  Future<void> _handleReset() async {
    await ref.read(appSettingsProvider.notifier).resetDefaultSyncStoreUrl();
    await ref.read(serverHealthProvider.notifier).updateServerUrl('http://127.0.0.1:10101');
    _urlController.text = 'http://127.0.0.1:10101';
    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('syncstore_server_reset_done'.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final health = ref.watch(serverHealthProvider);

    // 当外部 url 变更且非正在手动编辑时同步控制器文本
    if (!_isEditing && _urlController.text != settings.syncStoreUrl) {
      _urlController.text = settings.syncStoreUrl;
    }

    final isChecking = health.state == ServerHealthState.checking;
    final isAvailable = health.state == ServerHealthState.available;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'syncstore_server_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              PingLatencyInline(
                isLoading: isChecking,
                latencyMs: isAvailable ? health.latencyMs : -1,
                onRefresh: () => ref.read(serverHealthProvider.notifier).checkHealth(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'syncstore_server_desc'.tr,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),

          // URL 输入框与保存按钮
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.cloud_outlined, size: 20),
                    hintText: 'http://127.0.0.1:10101',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                    border: OutlineInputBorder(borderRadius: AppRadius.roundedSm),
                  ),
                  onChanged: (_) {
                    if (!_isEditing) setState(() => _isEditing = true);
                  },
                  onSubmitted: (_) => _handleSave(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _handleSave,
                child: Text('save'.tr),
              ),
            ],
          ),

          // 历史地址选择 Chips (如果有)
          if (settings.syncStoreUrlHistory.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final url in settings.syncStoreUrlHistory)
                  ActionChip(
                    avatar: Icon(
                      url == settings.syncStoreUrl ? Icons.check_circle : Icons.history,
                      size: 14,
                      color: url == settings.syncStoreUrl ? theme.colorScheme.primary : null,
                    ),
                    label: Text(
                      url,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: url == settings.syncStoreUrl ? theme.colorScheme.primary : null,
                      ),
                    ),
                    onPressed: () {
                      _urlController.text = url;
                      _handleSave();
                    },
                  ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.sm),
          // 底部操作区：一键重置默认服务器
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecking
                          ? Colors.amber
                          : (isAvailable ? Colors.green : Colors.red),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isChecking
                        ? 'server_status_checking'.tr
                        : (isAvailable
                            ? '${'server_status_available'.tr} (${health.latencyMs} ms)'
                            : 'server_status_unavailable'.tr),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isAvailable ? Colors.green : (isChecking ? Colors.amber : Colors.red),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.restart_alt, size: 16),
                label: Text('syncstore_server_reset'.tr),
                onPressed: _handleReset,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 版本信息与软件在线更新卡片 (TASK-6.4)
class _AppVersionUpdateCard extends ConsumerWidget {
  const _AppVersionUpdateCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final updateState = ref.watch(appUpdateProvider);
    final hasUpdate = updateState.info?.hasUpdate ?? false;

    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'app_version_card_title'.tr,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              ModernBadge(
                label: 'v${AppUpdateService.currentVersion}',
                color: hasUpdate ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasUpdate ? 'new_version_available'.tr : 'already_latest_version'.tr,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                icon: updateState.isChecking
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.system_update_alt_rounded, size: 16),
                label: Text(
                  updateState.isChecking
                      ? 'checking_update'.tr
                      : (hasUpdate ? 'download_update_btn'.tr : 'check_update'.tr),
                ),
                onPressed: updateState.isChecking
                    ? null
                    : () {
                        if (hasUpdate && updateState.info != null) {
                          AppUpdateService.showUpdateDialog(context, updateState.info!);
                        } else {
                          ref.read(appUpdateProvider.notifier).checkUpdate(
                            context: context,
                            isManual: true,
                          );
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
