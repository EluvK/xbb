import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/post_card.dart';
import 'package:xbb/components/post_filter.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';

class PostPages extends StatelessWidget {
  const PostPages({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(color: colorScheme.surface),
      child: const Column(
        children: [
          PostFilter(),
          Expanded(child: PostCard()),
        ],
      ),
    );
  }
}

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
              Get.toNamed('/edit-post'); // no arguments to new one
            },
            icon: const Icon(Icons.add),
          )
        ],
      );
    });
  }
}
