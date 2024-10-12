import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/pages/edit_post.dart';

class PostsAppBar extends StatefulWidget {
  const PostsAppBar({super.key});

  @override
  State<PostsAppBar> createState() => _PostsAppBarState();
}

class _PostsAppBarState extends State<PostsAppBar> {
  final settingController = Get.find<SettingController>();
  final repoController = Get.find<RepoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AppBar(
        title: Text(
            repoController.repoName(settingController.currentRepoId.value) ??
                ''),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EditPostPage()));
              },
              icon: const Icon(Icons.add))
        ],
      );
    });
  }
}
