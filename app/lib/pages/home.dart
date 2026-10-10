import 'dart:math';

import 'package:flutter/material.dart';
import 'package:xbb/core/core.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:xbb/components/clipboard/view_clipboard_history.dart';
import 'package:xbb/components/common/settings.dart';
import 'package:xbb/components/notes/view_posts.dart';
import 'package:xbb/components/notes/view_repos.dart';
import 'package:xbb/components/task/view_tasks.dart';
import 'package:xbb/components/trackers/view_tracker.dart';
import 'package:xbb/controller/app_launch.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/pages/chat/chat_page.dart';
import 'package:xbb/pages/checkin/checkin_calendar_page.dart';
import 'package:xbb/pages/home_interactive_nav_bar.dart';
import 'package:xbb/utils/color_picker.dart' show PaletteColorPickerButton;
import 'package:xbb/utils/text_input.dart';

enum HomeTabIndex { notes, tracker, task, clipboard, chat, checkin, settings }

enum FeatureSection { efficiency, records, ai }

extension FeatureSectionExt on FeatureSection {
  String get title {
    switch (this) {
      case FeatureSection.efficiency:
        return 'section_efficiency'.tr;
      case FeatureSection.records:
        return 'section_records'.tr;
      case FeatureSection.ai:
        return 'section_ai'.tr;
    }
  }

  IconData get icon {
    switch (this) {
      case FeatureSection.efficiency:
        return Icons.bolt_outlined;
      case FeatureSection.records:
        return Icons.auto_stories_outlined;
      case FeatureSection.ai:
        return Icons.auto_awesome_outlined;
    }
  }

  IconData get selectedIcon {
    switch (this) {
      case FeatureSection.efficiency:
        return Icons.bolt;
      case FeatureSection.records:
        return Icons.auto_stories;
      case FeatureSection.ai:
        return Icons.auto_awesome;
    }
  }

  List<HomeTabIndex> get candidateTabs {
    switch (this) {
      case FeatureSection.efficiency:
        return [HomeTabIndex.task, HomeTabIndex.checkin, HomeTabIndex.tracker];
      case FeatureSection.records:
        return [HomeTabIndex.notes, HomeTabIndex.clipboard];
      case FeatureSection.ai:
        return [HomeTabIndex.chat];
    }
  }
}

FeatureSection? sectionForTab(HomeTabIndex tab) {
  for (final section in FeatureSection.values) {
    if (section.candidateTabs.contains(tab)) {
      return section;
    }
  }
  return null;
}

IconData iconDataForTab(HomeTabIndex tab) {
  switch (tab) {
    case HomeTabIndex.notes:
      return AppFeatureMetaEnum.enableNotes.gIcon;
    case HomeTabIndex.tracker:
      return AppFeatureMetaEnum.enableTracker.gIcon;
    case HomeTabIndex.task:
      return Icons.check_box_rounded;
    case HomeTabIndex.clipboard:
      return AppFeatureMetaEnum.enableClipboardBackup.gIcon;
    case HomeTabIndex.chat:
      return AppFeatureMetaEnum.enableChat.gIcon;
    case HomeTabIndex.checkin:
      return AppFeatureMetaEnum.enableCheckin.gIcon;
    case HomeTabIndex.settings:
      return AppFeatureMetaEnum.settings.gIcon;
  }
}

IconData _iconDataForTab(HomeTabIndex tab) => iconDataForTab(tab);

String titleForTab(HomeTabIndex tab) {
  switch (tab) {
    case HomeTabIndex.notes:
      return 'home_bar_title_note'.tr;
    case HomeTabIndex.tracker:
      return 'home_bar_title_tracker'.tr;
    case HomeTabIndex.task:
      return 'home_bar_title_task'.tr;
    case HomeTabIndex.clipboard:
      return 'home_bar_title_clipboard'.tr;
    case HomeTabIndex.chat:
      return 'home_bar_title_chat'.tr;
    case HomeTabIndex.checkin:
      return 'home_bar_title_checkin'.tr;
    case HomeTabIndex.settings:
      return 'home_bar_title_setting'.tr;
  }
}

String _titleForTab(HomeTabIndex tab) => titleForTab(tab);

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  final SettingController settingController = Get.find<SettingController>();
  final AppLaunchController appLaunchController = Get.find<AppLaunchController>();

  HomeTabIndex _selectedTab = HomeTabIndex.notes;
  final Map<FeatureSection, HomeTabIndex> _sectionActiveTabs = {};
  Worker? _launchWorker;

  List<HomeTabIndex> get _activeIndices {
    List<HomeTabIndex> indices = [];
    if (settingController.taskEnabled) indices.add(HomeTabIndex.task);
    if (settingController.notesEnabled) indices.add(HomeTabIndex.notes);
    if (settingController.trackerEnabled) indices.add(HomeTabIndex.tracker);
    if (settingController.checkinEnabled) indices.add(HomeTabIndex.checkin);
    if (settingController.chatEnabled) indices.add(HomeTabIndex.chat);
    if (settingController.clipboardBackupEnabled) indices.add(HomeTabIndex.clipboard);
    return indices;
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabFromStartupIndex(settingController.homeStartupTabIndex);
    final requestedTab = _tabFromLaunchId(appLaunchController.takePendingHomeTab());
    if (requestedTab != null) {
      _selectedTab = requestedTab;
    }
    _recordSectionTab(_selectedTab);

    _launchWorker = ever<String?>(appLaunchController.pendingHomeTab, (tabId) {
      final requested = _tabFromLaunchId(tabId);
      if (requested == null) return;
      final activeIndices = _activeIndices;
      if (activeIndices.contains(requested) && mounted) {
        _onTabChanged(requested);
      }
      appLaunchController.clearPendingHomeTab();
    });
  }

  @override
  void dispose() {
    _launchWorker?.dispose();
    super.dispose();
  }

  void _recordSectionTab(HomeTabIndex tab) {
    final section = sectionForTab(tab);
    if (section != null) {
      _sectionActiveTabs[section] = tab;
    }
  }

  void _onTabChanged(HomeTabIndex tab) {
    _recordSectionTab(tab);
    setState(() => _selectedTab = tab);
  }

  void _onSectionSelected(FeatureSection section) {
    final activeIndices = _activeIndices;
    final sectionTabs = section.candidateTabs.where((t) => activeIndices.contains(t)).toList();
    if (sectionTabs.isEmpty) return;

    final remembered = _sectionActiveTabs[section];
    if (remembered != null && sectionTabs.contains(remembered)) {
      _onTabChanged(remembered);
    } else {
      _onTabChanged(sectionTabs.first);
    }
  }

  HomeTabIndex? _tabFromLaunchId(String? tabId) {
    switch (tabId) {
      case taskHomeTabId:
        return HomeTabIndex.task;
      case checkinHomeTabId:
        return HomeTabIndex.checkin;
      default:
        return null;
    }
  }

  HomeTabIndex _tabFromStartupIndex(int tabIndex) {
    switch (tabIndex) {
      case AppHomeStartupTabIndex.tracker:
        return HomeTabIndex.tracker;
      case AppHomeStartupTabIndex.task:
        return HomeTabIndex.task;
      case AppHomeStartupTabIndex.clipboard:
        return HomeTabIndex.clipboard;
      case AppHomeStartupTabIndex.chat:
        return HomeTabIndex.chat;
      case AppHomeStartupTabIndex.checkin:
        return HomeTabIndex.checkin;
      case AppHomeStartupTabIndex.settings:
        return HomeTabIndex.settings;
      case AppHomeStartupTabIndex.notes:
      default:
        return HomeTabIndex.notes;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeIndices = _activeIndices;
      if (activeIndices.isEmpty && _selectedTab != HomeTabIndex.settings) {
        return const SizedBox.shrink();
      }

      var selected = _selectedTab;
      if (selected != HomeTabIndex.settings && !activeIndices.contains(selected)) {
        selected = activeIndices.isNotEmpty ? activeIndices.first : HomeTabIndex.settings;
      }

      return _HomePage(
        selectedTab: selected,
        activeIndices: activeIndices,
        sectionActiveTabs: _sectionActiveTabs,
        onTabChanged: _onTabChanged,
        onSectionSelected: _onSectionSelected,
      );
    });
  }
}

class _HomePage extends GetResponsiveView {
  _HomePage({
    required this.selectedTab,
    required this.activeIndices,
    required this.sectionActiveTabs,
    required this.onTabChanged,
    required this.onSectionSelected,
  });

  final HomeTabIndex selectedTab;
  final List<HomeTabIndex> activeIndices;
  final Map<FeatureSection, HomeTabIndex> sectionActiveTabs;
  final ValueChanged<HomeTabIndex> onTabChanged;
  final ValueChanged<FeatureSection> onSectionSelected;

  final SettingController settingController = Get.find<SettingController>();

  bool get _hasSidebar => selectedTab == HomeTabIndex.notes || selectedTab == HomeTabIndex.chat;

  @override
  Widget? phone() {
    final activeSections = FeatureSection.values.where((section) {
      return section.candidateTabs.any((tab) => activeIndices.contains(tab));
    }).toList();

    final showColorController = [HomeTabIndex.notes, HomeTabIndex.tracker, HomeTabIndex.chat].contains(selectedTab);

    return PieCanvas(
      child: Scaffold(
        drawer: _hasSidebar
            ? Drawer(
                width: Get.width * 0.85,
                child: SafeArea(child: _FeatureSidebar(index: selectedTab)),
              )
            : null,
        appBar: AppBar(
          title: _AppBarTitle(index: selectedTab),
          titleSpacing: _hasSidebar ? 0.0 : 16.0,
          actions: [
            if (showColorController)
              Obx(
                () => PaletteColorPickerButton(
                  selectedTag: settingController.colorTag,
                  onSelected: (newTag) {
                    settingController.updateAppSetting(colorTag: newTag);
                  },
                ),
              ),
            IconButton(
              tooltip: 'home_bar_title_setting'.tr,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Get.to(
                  () => Scaffold(
                    appBar: AppBar(title: Text('home_bar_title_setting'.tr)),
                    body: const SafeArea(child: CommonSettings()),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _RightMain(index: selectedTab),
        bottomNavigationBar: activeSections.isEmpty
            ? null
            : MobileInteractiveNavigationBar(
                selectedTab: selectedTab,
                activeIndices: activeIndices,
                activeSections: activeSections,
                sectionActiveTabs: sectionActiveTabs,
                onTabChanged: onTabChanged,
                onSectionSelected: onSectionSelected,
              ),
      ),
    );
  }

  @override
  Widget? desktop() {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            selectedTab: selectedTab,
            activeIndices: activeIndices,
            onTabChanged: onTabChanged,
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _DesktopHeader(tab: selectedTab),
                const Divider(height: 1),
                Expanded(
                  child: Row(
                    children: [
                      if (_hasSidebar)
                        SizedBox(
                          width: min(max(Get.width * 0.3, 280.0), 400.0),
                          child: _FeatureSidebar(index: selectedTab),
                        ),
                      if (_hasSidebar) const VerticalDivider(width: 1),
                      Flexible(child: _RightMain(index: selectedTab)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedTab,
    required this.activeIndices,
    required this.onTabChanged,
  });

  final HomeTabIndex selectedTab;
  final List<HomeTabIndex> activeIndices;
  final ValueChanged<HomeTabIndex> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingController = Get.find<SettingController>();
    final activeSections = FeatureSection.values.where((section) {
      return section.candidateTabs.any((tab) => activeIndices.contains(tab));
    }).toList();

    return Container(
      width: 200,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'XBB',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Obx(
                      () => PaletteColorPickerButton(
                        selectedTag: settingController.colorTag,
                        onSelected: (newTag) {
                          settingController.updateAppSetting(colorTag: newTag);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              children: [
                for (final section in activeSections) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 4.0),
                    child: Text(
                      section.title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  for (final tab in section.candidateTabs.where((t) => activeIndices.contains(t)))
                    _DesktopSidebarTile(
                      icon: _iconDataForTab(tab),
                      title: _titleForTab(tab),
                      isSelected: tab == selectedTab,
                      onTap: () => onTabChanged(tab),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: _DesktopSidebarTile(
              icon: AppFeatureMetaEnum.settings.gIcon,
              title: 'home_bar_title_setting'.tr,
              isSelected: selectedTab == HomeTabIndex.settings,
              onTap: () => onTabChanged(HomeTabIndex.settings),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebarTile extends StatelessWidget {
  const _DesktopSidebarTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = isSelected ? colorScheme.secondaryContainer : Colors.transparent;
    final foregroundColor = isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: foregroundColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureSidebar extends StatelessWidget {
  const _FeatureSidebar({required this.index});
  final HomeTabIndex index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case HomeTabIndex.notes:
        return const ViewRepos();
      case HomeTabIndex.chat:
        return const ChatSessionPanel();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _RightMain extends StatelessWidget {
  const _RightMain({required this.index});
  final HomeTabIndex index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case HomeTabIndex.notes:
        return const ViewPosts();
      case HomeTabIndex.tracker:
        return const ViewTracker();
      case HomeTabIndex.task:
        return const ViewTasks();
      case HomeTabIndex.settings:
        return const CommonSettings();
      case HomeTabIndex.clipboard:
        return const ViewClipboardHistory();
      case HomeTabIndex.chat:
        return const ChatPage();
      case HomeTabIndex.checkin:
        return const CheckinCalendarPage();
    }
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({required this.tab});
  final HomeTabIndex tab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (tab == HomeTabIndex.notes)
            const Flexible(child: RepoQuickSwitcher())
          else
            Text(
              _titleForTab(tab),
              style: Theme.of(context).textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.index});
  final HomeTabIndex index;

  @override
  Widget build(BuildContext context) {
    if (index == HomeTabIndex.notes) {
      return const RepoQuickSwitcher();
    }
    return Text(_titleForTab(index));
  }
}
