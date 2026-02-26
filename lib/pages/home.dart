import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/common/profile.dart';
import 'package:xbb/components/common/settings.dart';
import 'package:xbb/components/notes/view_posts.dart';
import 'package:xbb/components/notes/view_repos.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/list_tile_card.dart' show ColorPickerButtons;
import 'package:xbb/utils/text_input.dart';

enum HomeTabIndex { notes, todo, todo2, settings }

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> {
  final SettingController settingController = Get.find<SettingController>();

  HomeTabIndex _lastSelectedTab = HomeTabIndex.notes;

  final Map<HomeTabIndex, Tab> _allTabs = {
    HomeTabIndex.notes: Tab(text: 'Notes', icon: Icon((AppFeatureMetaEnum.enableNotes.gIcon))),
    HomeTabIndex.todo: const Tab(text: 'Todo', icon: Icon(Icons.check_box_rounded)),
    HomeTabIndex.todo2: const Tab(text: 'Todo', icon: Icon(Icons.check_box_rounded)),
    HomeTabIndex.settings: Tab(text: 'Settings', icon: Icon((AppFeatureMetaEnum.settings.gIcon))),
  };

  List<HomeTabIndex> get _activeIndices {
    List<HomeTabIndex> indices = [];
    if (settingController.notesEnabled) indices.add(HomeTabIndex.notes);
    // indices.add(HomeTabIndex.todo);
    indices.add(HomeTabIndex.settings);
    return indices;
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
            tabController.addListener(() {
              if (!tabController.indexIsChanging) {
                _lastSelectedTab = activeIndices[tabController.index];
              }
            });
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
                    const _GlobalColorController(),
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
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
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
      case HomeTabIndex.todo:
      case HomeTabIndex.todo2:
        return const Placeholder();
      case HomeTabIndex.settings:
        return const CommonProfile();
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
      case HomeTabIndex.todo:
      case HomeTabIndex.todo2:
        return const Placeholder();
      case HomeTabIndex.settings:
        return const CommonSettings();
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
      case HomeTabIndex.todo:
      case HomeTabIndex.todo2:
      case HomeTabIndex.settings:
        return const Text('Settings');
    }
  }
}
