import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/clipboard/view_clipboard_history.dart';
import 'package:xbb/components/common/settings.dart';
import 'package:xbb/components/notes/view_posts.dart';
import 'package:xbb/components/notes/view_repos.dart';
import 'package:xbb/components/task/view_tasks.dart';
import 'package:xbb/components/trackers/view_tracker.dart';
import 'package:xbb/pages/chat/chat_page.dart';
import 'package:xbb/pages/checkin/checkin_calendar_page.dart';
import 'package:xbb/controller/app_launch.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/list_tile_card.dart' show ColorPickerButtons;
import 'package:xbb/utils/text_input.dart';

enum HomeTabIndex { notes, tracker, task, clipboard, chat, checkin, settings }

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  final SettingController settingController = Get.find<SettingController>();
  final AppLaunchController appLaunchController = Get.find<AppLaunchController>();

  HomeTabIndex _selectedTab = HomeTabIndex.notes;
  Worker? _launchWorker;

  final Map<HomeTabIndex, Tab> _allTabs = {
    HomeTabIndex.notes: Tab(text: 'home_bar_title_note'.tr, icon: Icon((AppFeatureMetaEnum.enableNotes.gIcon))),
    HomeTabIndex.tracker: Tab(text: 'home_bar_title_tracker'.tr, icon: Icon((AppFeatureMetaEnum.enableTracker.gIcon))),
    HomeTabIndex.task: Tab(text: 'home_bar_title_task'.tr, icon: const Icon(Icons.check_box_rounded)),
    HomeTabIndex.clipboard: Tab(
      text: 'home_bar_title_clipboard'.tr,
      icon: Icon((AppFeatureMetaEnum.enableClipboardBackup.gIcon)),
    ),
    HomeTabIndex.chat: Tab(text: 'home_bar_title_chat'.tr, icon: Icon((AppFeatureMetaEnum.enableChat.gIcon))),
    HomeTabIndex.checkin: Tab(text: 'home_bar_title_checkin'.tr, icon: Icon((AppFeatureMetaEnum.enableCheckin.gIcon))),
    HomeTabIndex.settings: Tab(text: 'home_bar_title_setting'.tr, icon: Icon((AppFeatureMetaEnum.settings.gIcon))),
  };

  List<HomeTabIndex> get _activeIndices {
    List<HomeTabIndex> indices = [];
    if (settingController.taskEnabled) indices.add(HomeTabIndex.task);
    if (settingController.notesEnabled) indices.add(HomeTabIndex.notes);
    if (settingController.trackerEnabled) indices.add(HomeTabIndex.tracker);
    if (settingController.checkinEnabled) indices.add(HomeTabIndex.checkin);
    if (settingController.chatEnabled) indices.add(HomeTabIndex.chat);
    if (settingController.clipboardBackupEnabled) indices.add(HomeTabIndex.clipboard);
    indices.add(HomeTabIndex.settings);
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
    _launchWorker = ever<String?>(appLaunchController.pendingHomeTab, (tabId) {
      final requested = _tabFromLaunchId(tabId);
      if (requested == null) return;
      final activeIndices = _activeIndices;
      if (activeIndices.contains(requested) && mounted) {
        setState(() => _selectedTab = requested);
      }
      appLaunchController.clearPendingHomeTab();
    });
  }

  @override
  void dispose() {
    _launchWorker?.dispose();
    super.dispose();
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
      if (activeIndices.isEmpty) return const SizedBox.shrink();

      var selected = _selectedTab;
      if (!activeIndices.contains(selected)) {
        selected = activeIndices.first;
      }
      final tabs = activeIndices.map((e) => _allTabs[e]!).toList();

      return _HomePage(
        selectedTab: selected,
        tabs: tabs,
        activeIndices: activeIndices,
        onTabChanged: (tab) {
          setState(() => _selectedTab = tab);
        },
      );
    });
  }
}

class _HomePage extends GetResponsiveView {
  _HomePage({required this.selectedTab, required this.tabs, required this.activeIndices, required this.onTabChanged});

  final HomeTabIndex selectedTab;
  final List<Tab> tabs;
  final List<HomeTabIndex> activeIndices;
  final ValueChanged<HomeTabIndex> onTabChanged;

  bool get _hasSidebar => selectedTab == HomeTabIndex.notes || selectedTab == HomeTabIndex.chat;

  @override
  Widget? phone() {
    return Scaffold(
      drawer: _hasSidebar
          ? Drawer(
              width: Get.width * 0.85,
              child: SafeArea(child: _FeatureSidebar(index: selectedTab)),
            )
          : null,
      appBar: AppBar(title: _AppBarTitle(index: selectedTab), titleSpacing: 0.0),
      body: _RightMain(index: selectedTab),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndices.indexOf(selectedTab),
        onDestinationSelected: (index) {
          final tab = activeIndices[index];
          if (tab != selectedTab) onTabChanged(tab);
        },
        destinations: tabs
            .map((tab) => NavigationDestination(icon: tab.icon ?? const Icon(Icons.circle), label: tab.text ?? ''))
            .toList(),
      ),
    );
  }

  @override
  Widget? desktop() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: activeIndices.indexOf(selectedTab),
            onDestinationSelected: (index) => onTabChanged(activeIndices[index]),
            labelType: NavigationRailLabelType.all,
            destinations: tabs
                .map(
                  (tab) => NavigationRailDestination(
                    icon: tab.icon ?? const Icon(Icons.circle),
                    label: Text(tab.text ?? ''),
                  ),
                )
                .toList(),
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

class _GlobalColorController extends StatefulWidget {
  const _GlobalColorController();

  @override
  State<_GlobalColorController> createState() => _GlobalColorControllerState();
}

class _GlobalColorControllerState extends State<_GlobalColorController> {
  final settingController = Get.find<SettingController>();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ColorPickerButtons(
          selectedTag: settingController.colorTag,
          onSelected: (newTag) {
            setState(() {
              settingController.updateAppSetting(colorTag: newTag);
            });
          },
        ),
      ),
    );
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

  bool get _showColorController => [HomeTabIndex.notes, HomeTabIndex.tracker, HomeTabIndex.chat].contains(tab);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (tab == HomeTabIndex.notes) const Flexible(child: RepoQuickSwitcher()) else Text(_titleForTab(tab)),
          if (_showColorController) const _GlobalColorController(),
        ],
      ),
    );
  }

  String _titleForTab(HomeTabIndex tab) {
    switch (tab) {
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
      default:
        return '';
    }
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.index});
  final HomeTabIndex index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case HomeTabIndex.notes:
        return const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: RepoQuickSwitcher()),
            _GlobalColorController(),
          ],
        );
      case HomeTabIndex.tracker:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('home_bar_title_tracker'.tr), const _GlobalColorController()],
        );
      case HomeTabIndex.chat:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('home_bar_title_chat'.tr), const _GlobalColorController()],
        );
      case HomeTabIndex.task:
        return Text('home_bar_title_task'.tr);
      case HomeTabIndex.settings:
        return Text('home_bar_title_setting'.tr);
      case HomeTabIndex.clipboard:
        return Text('home_bar_title_clipboard'.tr);
      case HomeTabIndex.checkin:
        return Text('home_bar_title_checkin'.tr);
    }
  }
}
