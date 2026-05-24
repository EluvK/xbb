import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/clipboard/view_clipboard_history.dart';
import 'package:xbb/components/clipboard/view_clipboard_overview.dart';
import 'package:xbb/components/common/profile.dart';
import 'package:xbb/components/common/settings.dart';
import 'package:xbb/components/notes/view_posts.dart';
import 'package:xbb/components/notes/view_repos.dart';
import 'package:xbb/components/task/view_task_overview.dart';
import 'package:xbb/components/task/view_tasks.dart';
import 'package:xbb/components/trackers/view_brief.dart';
import 'package:xbb/components/trackers/view_tracker.dart';
import 'package:xbb/controller/app_launch.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/list_tile_card.dart' show ColorPickerButtons;
import 'package:xbb/utils/text_input.dart';

enum HomeTabIndex { notes, tracker, task, clipboard, settings }

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  final SettingController settingController = Get.find<SettingController>();
  final AppLaunchController appLaunchController = Get.find<AppLaunchController>();

  HomeTabIndex _lastSelectedTab = HomeTabIndex.notes;
  Worker? _launchWorker;
  TabController? _tabController;

  final Map<HomeTabIndex, Tab> _allTabs = {
    HomeTabIndex.notes: Tab(text: 'home_bar_title_note'.tr, icon: Icon((AppFeatureMetaEnum.enableNotes.gIcon))),
    HomeTabIndex.tracker: Tab(text: 'home_bar_title_tracker'.tr, icon: Icon((AppFeatureMetaEnum.enableTracker.gIcon))),
    HomeTabIndex.task: Tab(text: 'home_bar_title_task'.tr, icon: const Icon(Icons.check_box_rounded)),
    HomeTabIndex.clipboard: Tab(
      text: 'home_bar_title_clipboard'.tr,
      icon: Icon((AppFeatureMetaEnum.enableClipboardBackup.gIcon)),
    ),
    HomeTabIndex.settings: Tab(text: 'home_bar_title_setting'.tr, icon: Icon((AppFeatureMetaEnum.settings.gIcon))),
  };

  List<HomeTabIndex> get _activeIndices {
    List<HomeTabIndex> indices = [];
    if (settingController.taskEnabled) indices.add(HomeTabIndex.task);
    if (settingController.clipboardBackupEnabled) indices.add(HomeTabIndex.clipboard);
    if (settingController.notesEnabled) indices.add(HomeTabIndex.notes);
    if (settingController.trackerEnabled) indices.add(HomeTabIndex.tracker);
    indices.add(HomeTabIndex.settings);
    return indices;
  }

  @override
  void initState() {
    super.initState();
    _lastSelectedTab = _tabFromStartupIndex(settingController.homeStartupTabIndex);
    final requestedTab = _tabFromLaunchId(appLaunchController.takePendingHomeTab());
    if (requestedTab != null) {
      _lastSelectedTab = requestedTab;
    }
    _launchWorker = ever<String?>(appLaunchController.pendingHomeTab, (tabId) {
      final requested = _tabFromLaunchId(tabId);
      if (requested == null) return;

      _lastSelectedTab = requested;
      final activeIndices = _activeIndices;
      final targetIndex = activeIndices.indexOf(requested);
      if (mounted) {
        setState(() {});
      }
      if (_tabController != null && targetIndex != -1 && _tabController!.index != targetIndex) {
        _tabController!.animateTo(targetIndex);
      }
      appLaunchController.clearPendingHomeTab();
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChanged);
    _launchWorker?.dispose();
    super.dispose();
  }

  HomeTabIndex? _tabFromLaunchId(String? tabId) {
    switch (tabId) {
      case taskHomeTabId:
        return HomeTabIndex.task;
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
      case AppHomeStartupTabIndex.settings:
        return HomeTabIndex.settings;
      case AppHomeStartupTabIndex.notes:
      default:
        return HomeTabIndex.notes;
    }
  }

  void _handleTabChanged() {
    final tabController = _tabController;
    if (tabController == null || tabController.indexIsChanging) return;
    final activeIndices = _activeIndices;
    if (tabController.index < 0 || tabController.index >= activeIndices.length) {
      return;
    }
    _lastSelectedTab = activeIndices[tabController.index];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeIndices = _activeIndices;
      final activeTabs = activeIndices.map((e) => _allTabs[e]!).toList();

      int newInitialIndex = activeIndices.indexOf(_lastSelectedTab);
      if (newInitialIndex == -1) newInitialIndex = 0;

      return DefaultTabController(
        key: ValueKey(activeIndices.length),
        length: activeTabs.length,
        initialIndex: newInitialIndex,
        child: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            if (!identical(_tabController, tabController)) {
              _tabController?.removeListener(_handleTabChanged);
              _tabController = tabController;
              _tabController?.addListener(_handleTabChanged);
            }
            return _HomePage(tabController: tabController, tabs: activeTabs, activeIndices: activeIndices);
          },
        ),
      );
    });
  }
}

class _HomePage extends GetResponsiveView {
  _HomePage({required this.tabController, required this.tabs, required this.activeIndices});

  final TabController tabController;
  final List<Tab> tabs;
  final List<HomeTabIndex> activeIndices;

  @override
  Widget? phone() {
    return ListenableBuilder(
      listenable: tabController,
      builder: (context, child) {
        final currentTab = activeIndices[tabController.index];

        return Scaffold(
          drawer: Drawer(
            width: Get.width * 0.85,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TabBarController(tabs: tabs, tabController: tabController),
                  const Divider(),
                  Expanded(child: _LeftButton(index: currentTab)),
                ],
              ),
            ),
          ),
          appBar: AppBar(title: _AppBar(index: currentTab), titleSpacing: 0.0),
          body: _RightMain(index: currentTab),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tabController.index,
            onDestinationSelected: (index) {
              if (index != tabController.index) {
                tabController.animateTo(index);
              }
            },
            destinations: tabs
                .map((tab) => NavigationDestination(icon: tab.icon ?? const Icon(Icons.circle), label: tab.text ?? ''))
                .toList(),
          ),
        );
      },
    );
  }

  @override
  Widget? desktop() {
    return ListenableBuilder(
      listenable: tabController,
      builder: (context, child) {
        final currentTab = activeIndices[tabController.index];

        return Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: min(max(Get.width * 0.3, 280), 400),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
                      child: const _GlobalColorController(),
                    ),
                    TabBarController(tabs: tabs, tabController: tabController),
                    Expanded(child: _LeftButton(index: currentTab)),
                  ],
                ),
              ),
              const VerticalDivider(),
              Flexible(child: _RightMain(index: currentTab)),
            ],
          ),
        );
      },
    );
  }
}

class TabBarController extends StatelessWidget {
  const TabBarController({super.key, required this.tabs, required this.tabController});

  final List<Tab> tabs;
  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: TabBar(
        tabs: tabs,
        controller: tabController,
        onTap: (int _) {
          if (!tabController.indexIsChanging) {
            final scaffoldState = Scaffold.maybeOf(context);
            if (scaffoldState != null && scaffoldState.isDrawerOpen) {
              Navigator.of(context).pop();
            }
          }
        },
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
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

class _LeftButton extends StatelessWidget {
  const _LeftButton({required this.index});
  final HomeTabIndex index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case HomeTabIndex.notes:
        return const ViewRepos();
      case HomeTabIndex.tracker:
        return const ViewTrackerBrief();
      case HomeTabIndex.task:
        return const ViewTaskOverview();
      case HomeTabIndex.settings:
        return const CommonProfile();
      case HomeTabIndex.clipboard:
        return const ViewClipboardOverview();
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
    }
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.index});
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
      case HomeTabIndex.task:
        return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('home_bar_title_task'.tr)]);
      case HomeTabIndex.settings:
        return Text('home_bar_title_setting'.tr);
      case HomeTabIndex.clipboard:
        return Text('home_bar_title_clipboard'.tr);
    }
  }
}
