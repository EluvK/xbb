import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/sync.dart';
import 'package:xbb/pages/drawer.dart';
import 'package:xbb/pages/posts.dart';

class HomePage extends GetResponsiveView {
  HomePage({super.key});

  @override
  Widget? phone() {
    final syncController = Get.find<SyncController>();
    return Scaffold(
      drawer: const DrawerPage(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: PostsAppBar(),
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            await syncController.checkSyncInfo();
            return Future<void>.delayed(const Duration(seconds: 1));
          },
          notificationPredicate: (ScrollNotification notification) {
            if (notification.depth != 0) {
              return false;
            }
            return true;
          },
          child: const PostPages()),
    );
  }

  @override
  Widget? desktop() {
    return const Placeholder();
  }
}
