import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/pages/drawer.dart';
import 'package:xbb/pages/posts.dart';

class HomePage extends GetResponsiveView {
  HomePage({super.key});

  @override
  Widget? phone() {
    final settingController = Get.find<SettingController>();
    final postController = Get.find<PostController>();
    return Scaffold(
      drawer: const DrawerPage(),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: PostsAppBar(),
      ),
      body: RefreshIndicator(
          onRefresh: () async {
            return await postController
                .pullPosts(settingController.currentRepoId.value);
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
