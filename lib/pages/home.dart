import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar.secondary(tabs: tabs, controller: tabController),
            const Divider(),
            Expanded(child: _LeftMain(index: currentTab)),
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
            width: 300,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
                  child: Align(alignment: Alignment.centerLeft, child: _GlobalColorController()),
                ),
                const Divider(),
                TabBar.secondary(tabs: tabs, controller: tabController),
                const Divider(),
                Expanded(child: _LeftMain(index: currentTab)),
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

class _GlobalColorController extends StatefulWidget {
  const _GlobalColorController();

  @override
  State<_GlobalColorController> createState() => _GlobalColorControllerState();
}

class _GlobalColorControllerState extends State<_GlobalColorController> {
  final settingController = Get.find<NewSettingController>();
  @override
  Widget build(BuildContext context) {
    return ColorPickerButtons(
      selectedTag: settingController.colorTag,
      onChanged: (newTag) {
        setState(() {
          settingController.updateAppSetting(colorTag: newTag);
        });
      },
    );
  }
}

class _LeftMain extends StatelessWidget {
  const _LeftMain({required this.index});
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
        return const Placeholder();
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
    return const Text('App Bar');
  }
}
