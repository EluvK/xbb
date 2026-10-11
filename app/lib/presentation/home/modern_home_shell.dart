import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/chat/modern_chat_view.dart';
import 'package:xbb/presentation/checkin/modern_checkin_view.dart';
import 'package:xbb/presentation/clipboard/modern_clipboard_view.dart';
import 'package:xbb/presentation/notes/modern_notes_view.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/presentation/settings/modern_settings_view.dart';
import 'package:xbb/presentation/task/modern_task_view.dart';
import 'package:xbb/presentation/tracker/modern_tracker_view.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

enum AppTab { notes, task, checkin, tracker, clipboard, chat, settings }

class ModernHomeShell extends ConsumerStatefulWidget {
  const ModernHomeShell({super.key});

  @override
  ConsumerState<ModernHomeShell> createState() => _ModernHomeShellState();
}

class _ModernHomeShellState extends ConsumerState<ModernHomeShell> {
  AppTab _currentTab = AppTab.notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);

    final tabs = <AppTab>[];
    if (settings.notesEnabled) tabs.add(AppTab.notes);
    if (settings.taskEnabled) tabs.add(AppTab.task);
    if (settings.checkinEnabled) tabs.add(AppTab.checkin);
    if (settings.trackerEnabled) tabs.add(AppTab.tracker);
    if (settings.clipboardEnabled) tabs.add(AppTab.clipboard);
    if (settings.chatEnabled) tabs.add(AppTab.chat);
    tabs.add(AppTab.settings);

    if (!tabs.contains(_currentTab) && tabs.isNotEmpty) {
      _currentTab = tabs.first;
    }

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
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
                            Text(
                              'XBB Workspace',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
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
          : NavigationBar(
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
    );
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
        return '笔记';
      case AppTab.task:
        return '待办';
      case AppTab.checkin:
        return '打卡';
      case AppTab.tracker:
        return '目标';
      case AppTab.clipboard:
        return '剪贴板';
      case AppTab.chat:
        return 'AI 助手';
      case AppTab.settings:
        return '设置';
    }
  }
}
