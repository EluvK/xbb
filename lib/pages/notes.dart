import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/view_posts.dart';
import 'package:xbb/components/notes/view_repos.dart';

class NoteHomePage extends GetResponsiveView {
  NoteHomePage({super.key});

  @override
  Widget? phone() {
    return Placeholder();
    // return Scaffold(
    //   drawer: const DrawerPage(),
    //   appBar: const PreferredSize(
    //     preferredSize: Size.fromHeight(56.0),
    //     child: PostsAppBar(),
    //   ),
    //   floatingActionButton: floatAddButton(),
    //   body: refreshPostPages(),
    // );
  }

  @override
  Widget? desktop() {
    return const Scaffold(
      body: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Placeholder(),
          ViewRepos(),
          VerticalDivider(),
          Flexible(child: ViewPosts()),
        ],
      ),
    );
  }
}
