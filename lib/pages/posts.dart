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
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
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
  String targetRepo = "";

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      targetRepo = repoController.currentRepoId.value;
      // print("targetRepo: $targetRepo");
      return AppBar(
        title: appBarTitle(),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Get.toNamed('/edit-post'); // no arguments to new one
        //     },
        //     icon: const Icon(Icons.add),
        //   ),
        // ],
      );
    });
  }

  Widget appBarTitle() {
    final colorScheme = Theme.of(context).colorScheme;
    final repoLists = [
      ...repoController.myRepoList,
      ...repoController.subscribeRepoList
    ];
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField(
        items: repoLists.map((e) {
          return DropdownMenuItem(
            value: e.id,
            child: Row(
              children: [
                Text(e.name),
                if (e.unreadCount > 0)
                  Transform.translate(
                      offset: const Offset(0, -6),
                      child: Text("✨${e.unreadCount} ",
                          style: const TextStyle(fontSize: 12))),
              ],
            ),
          );
        }).toList(),
        isExpanded: true,
        icon: const Icon(null),
        decoration: InputDecoration(
          // prefixIcon: const Icon(Icons.book),
          contentPadding: const EdgeInsets.all(0.0),
          border: const OutlineInputBorder(borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
          fillColor: colorScheme.surface,
        ),
        onChanged: (value) async {
          targetRepo = value!;
          await repoController.setCurrentRepo(targetRepo);
        },
        value: targetRepo,
      ),
    );
  }
}
