import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/view_posts.dart';
import 'package:xbb/components/notes/view_repos.dart';

final List<Tab> homeTabs = <Tab>[
  const Tab(text: 'Notes', icon: Icon(Icons.library_books_rounded)),
  const Tab(text: 'Todo', icon: Icon(Icons.check_box_rounded)),
  const Tab(text: 'Todo', icon: Icon(Icons.check_box_rounded)),
  const Tab(text: 'Todo', icon: Icon(Icons.check_box_rounded)),
];

class HomePageWrapper extends StatefulWidget {
  const HomePageWrapper({super.key});

  @override
  State<HomePageWrapper> createState() => _HomePageWrapperState();
}

class _HomePageWrapperState extends State<HomePageWrapper> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: homeTabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {
        _currentIndex = _tabController.index;
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
    return _HomePage(tabController: _tabController, currentIndex: _currentIndex, tabs: homeTabs);
  }
}

class _HomePage extends GetResponsiveView {
  _HomePage({required this.tabController, required this.currentIndex, required this.tabs});
  final TabController tabController;
  final int currentIndex;
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
            Expanded(child: _LeftMain(index: currentIndex)),
          ],
        ),
      ),
      appBar: AppBar(title: _AppBar(index: currentIndex)),
      body: _RightMain(index: currentIndex),
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
                TabBar.secondary(tabs: tabs, controller: tabController),
                const Divider(),
                Expanded(child: _LeftMain(index: currentIndex)),
              ],
            ),
          ),
          const VerticalDivider(),
          Flexible(child: _RightMain(index: currentIndex)),
        ],
      ),
    );
  }
}

class _LeftMain extends StatelessWidget {
  const _LeftMain({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const ViewRepos();
      case 1:
        return const Placeholder();
      default:
        return const Placeholder();
    }
  }
}

class _RightMain extends StatelessWidget {
  const _RightMain({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const ViewPosts();
      case 1:
        return const Placeholder();
      default:
        return const Placeholder();
    }
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return const Text('App Bar');
  }
}
