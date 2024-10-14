import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/pages/drawer.dart';
import 'package:xbb/pages/posts.dart';

class HomePage extends GetResponsiveView {
  HomePage({super.key});

  @override
  Widget? phone() {
    return const Scaffold(
      drawer: DrawerPage(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: PostsAppBar(),
      ),
      body: PostPages(),
    );
  }

  @override
  Widget? desktop() {
    return const Placeholder();
  }
}
