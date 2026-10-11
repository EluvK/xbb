import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/chat/modern_chat_view.dart';
import 'package:xbb/presentation/checkin/modern_checkin_view.dart';
import 'package:xbb/presentation/clipboard/modern_clipboard_view.dart';
import 'package:xbb/presentation/notes/modern_notes_view.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/presentation/settings/modern_settings_view.dart';
import 'package:xbb/presentation/task/modern_task_view.dart';
import 'package:xbb/presentation/tracker/modern_tracker_view.dart';
import 'package:xbb/presentation/widgets/avatar_helper.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/utils/translation.dart';

enum AppTab { notes, task, checkin, tracker, clipboard, chat, settings }

class ModernHomeShell extends ConsumerStatefulWidget {
  const ModernHomeShell({super.key});

  @override
  ConsumerState<ModernHomeShell> createState() => _ModernHomeShellState();
}

class _ModernHomeShellState extends ConsumerState<ModernHomeShell> {
  AppTab _currentTab = AppTab.notes;
  bool _initializedTab = false;

  static AppTab getTabFromStartupIndex(int index) {
    return switch (index) {
      AppHomeStartupTabIndex.task => AppTab.task,
      AppHomeStartupTabIndex.checkin => AppTab.checkin,
      AppHomeStartupTabIndex.tracker => AppTab.tracker,
      AppHomeStartupTabIndex.clipboard => AppTab.clipboard,
      AppHomeStartupTabIndex.chat => AppTab.chat,
      AppHomeStartupTabIndex.settings => AppTab.settings,
      _ => AppTab.notes,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final auth = ref.watch(authProvider);

    final tabs = <AppTab>[];
    if (settings.notesEnabled) tabs.add(AppTab.notes);
    if (settings.taskEnabled) tabs.add(AppTab.task);
    if (settings.checkinEnabled) tabs.add(AppTab.checkin);
    if (settings.trackerEnabled) tabs.add(AppTab.tracker);
    if (settings.clipboardEnabled) tabs.add(AppTab.clipboard);
    if (settings.chatEnabled) tabs.add(AppTab.chat);
    tabs.add(AppTab.settings);

    if (!_initializedTab) {
      final preferredTab = getTabFromStartupIndex(settings.startupTabIndex);
      if (tabs.contains(preferredTab)) {
        _currentTab = preferredTab;
      }
      _initializedTab = true;
    }

    if (!tabs.contains(_currentTab) && tabs.isNotEmpty) {
      _currentTab = tabs.first;
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    final shellScaffold = Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: isDesktop
          ? Row(
              children: [
                // 桌面端侧边栏
                Container(
                  width: 220,
                  color: theme.colorScheme.surfaceContainerLowest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: AppRadius.roundedSm,
                              ),
                              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'XBB Workspace',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                          children: [
                            for (final tab in tabs)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: ModernCard(
                                  selected: tab == _currentTab,
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                  onTap: () => setState(() => _currentTab = tab),
                                  child: Row(
                                    children: [
                                      Icon(_getIconForTab(tab), size: 18, color: tab == _currentTab ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          _getTitleForTab(tab),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: tab == _currentTab ? FontWeight.bold : FontWeight.normal,
                                            color: tab == _currentTab ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // 桌面端左下角用户头像与进入个人中心入口
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () => context.push('/profile'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            child: Row(
                              children: [
                                UserAvatarWidget(
                                  avatar: auth.avatar,
                                  fallbackName: auth.nickname.isNotEmpty ? auth.nickname : auth.username,
                                  radius: 16,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        auth.nickname.isNotEmpty ? auth.nickname : auth.username,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        auth.isLoggedIn ? '@${auth.username}' : 'offline_guest'.tr,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildCurrentTabView()),
              ],
            )
          : _buildCurrentTabView(),
      bottomNavigationBar: isDesktop
          ? null
          : PieMenu(
              theme: PieTheme(
                overlayColor: Colors.black38,
                pointerColor: theme.colorScheme.primary.withAlpha(120),
                buttonTheme: PieButtonTheme(
                  backgroundColor: theme.colorScheme.surface,
                  iconColor: theme.colorScheme.onSurface,
                ),
                buttonThemeHovered: PieButtonTheme(
                  backgroundColor: theme.colorScheme.primary,
                  iconColor: Colors.white,
                ),
              ),
              actions: [
                for (final tab in tabs)
                  PieAction(
                    tooltip: Text(_getTitleForTab(tab)),
                    onSelect: () => setState(() => _currentTab = tab),
                    child: Icon(_getIconForTab(tab)),
                  ),
              ],
              child: NavigationBar(
                selectedIndex: tabs.indexOf(_currentTab).clamp(0, tabs.length - 1),
                onDestinationSelected: (idx) {
                  if (idx >= 0 && idx < tabs.length) {
                    setState(() => _currentTab = tabs[idx]);
                  }
                },
                destinations: [
                  for (final tab in tabs)
                    NavigationDestination(
                      icon: Icon(_getIconForTab(tab)),
                      label: _getTitleForTab(tab),
                    ),
                ],
              ),
            ),
    );

    return isDesktop ? shellScaffold : PieCanvas(child: shellScaffold);
  }

  Widget _buildCurrentTabView() {
    switch (_currentTab) {
      case AppTab.notes:
        return const ModernNotesView();
      case AppTab.task:
        return const ModernTaskView();
      case AppTab.checkin:
        return const ModernCheckinView();
      case AppTab.tracker:
        return const ModernTrackerView();
      case AppTab.clipboard:
        return const ModernClipboardView();
      case AppTab.chat:
        return const ModernChatView();
      case AppTab.settings:
        return const ModernSettingsView();
    }
  }

  IconData _getIconForTab(AppTab tab) {
    switch (tab) {
      case AppTab.notes:
        return Icons.auto_stories_outlined;
      case AppTab.task:
        return Icons.checklist_rounded;
      case AppTab.checkin:
        return Icons.event_available_outlined;
      case AppTab.tracker:
        return Icons.track_changes_outlined;
      case AppTab.clipboard:
        return Icons.content_paste_outlined;
      case AppTab.chat:
        return Icons.auto_awesome_outlined;
      case AppTab.settings:
        return Icons.settings_outlined;
    }
  }

  String _getTitleForTab(AppTab tab) {
    switch (tab) {
      case AppTab.notes:
        return 'home_bar_title_notes'.tr;
      case AppTab.task:
        return 'home_bar_title_task'.tr;
      case AppTab.checkin:
        return 'home_bar_title_checkin'.tr;
      case AppTab.tracker:
        return 'home_bar_title_tracker'.tr;
      case AppTab.clipboard:
        return 'home_bar_title_clipboard'.tr;
      case AppTab.chat:
        return 'home_bar_title_chat'.tr;
      case AppTab.settings:
        return 'home_bar_title_setting'.tr;
    }
  }
}
