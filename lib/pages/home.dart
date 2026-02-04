import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/common/profile.dart';
import 'package:xbb/components/common/settings.dart';
import 'package:xbb/components/notes/view_posts.dart';
import 'package:xbb/components/notes/view_repos.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/list_tile_card.dart' show ColorPickerButtons;

final List<Tab> homeTabs = <Tab>[
  const Tab(text: 'Notes', icon: Icon(Icons.library_books_rounded)),
  const Tab(text: 'Todo', icon: Icon(Icons.check_box_rounded)),
  const Tab(text: 'Todo', icon: Icon(Icons.check_box_rounded)),
  const Tab(text: 'Settings', icon: Icon(Icons.settings_rounded)),
];

enum HomeTabIndex { notes, todo, todo2, settings }

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  HomeTabIndex _currentTab = HomeTabIndex.notes;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: homeTabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {
        _currentTab = HomeTabIndex.values[_tabController.index];
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _HomePage(tabController: _tabController, currentTab: _currentTab, tabs: homeTabs);
  }
}

class _HomePage extends GetResponsiveView {
  _HomePage({required this.tabController, required this.currentTab, required this.tabs});
  final TabController tabController;
  final HomeTabIndex currentTab;
  final List<Tab> tabs;

  @override
  Widget? phone() {
    return Scaffold(
      drawer: Drawer(
        width: Get.width * 0.85,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBarController(tabs: tabs, tabController: tabController),
            const Divider(),
            Expanded(child: _LeftButton(index: currentTab)),
          ],
        ),
      ),
      appBar: AppBar(title: _AppBar(index: currentTab)),
      body: _RightMain(index: currentTab),
    );
  }

  @override
  Widget? desktop() {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: min(max(Get.width * 0.3, 280), 400),
            child: Column(
              children: [
                const _GlobalColorController(),
                // const Divider(),
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
      // child: TabBar.secondary(tabs: tabs, controller: tabController),
      child: TabBar(
        tabs: tabs,
        controller: tabController,
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
  final settingController = Get.find<NewSettingController>();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ColorPickerButtons(
          selectedTag: settingController.colorTag,
          onChanged: (newTag) {
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
    //   return Container(
    //     decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    //     child: _parts(),
    //   );
    // }
    // Widget _parts() {
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
    //   return Container(
    //     decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
    //     child: _parts(),
    //   );
    // }
    // Widget _parts() {
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
          // todo many work here.
          children: [Text('TODO s'), _GlobalColorController()],
        );
      case HomeTabIndex.todo:
      case HomeTabIndex.todo2:
      case HomeTabIndex.settings:
        return const Text('Settings');
    }
  }
}
