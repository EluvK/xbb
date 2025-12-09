import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/notes/model.dart';

class ViewPosts extends StatelessWidget {
  const ViewPosts({super.key});

  @override
  Widget build(BuildContext context) {
    // final args = Get.arguments;
    // final String? repoId = args?[0];
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("click add post");
          Get.toNamed('/notes/edit-post', arguments: [null]);
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        decoration: BoxDecoration(color: colorScheme.surface),
        child: const Column(
          children: [
            // todo
            // PostFilter(),
            Expanded(child: _ViewPosts()),
          ],
        ),
      ),
    );
  }
}

class _ViewPosts extends StatefulWidget {
  const _ViewPosts();

  @override
  State<_ViewPosts> createState() => __ViewPostsState();
}

class __ViewPostsState extends State<_ViewPosts> {
  final postController = Get.find<PostController>();
  final repoController = Get.find<RepoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentRepoId = repoController.currentRepoId.value;
      if (currentRepoId == null) {
        return const Center(child: Text('No repository selected.'));
      }
      List<PostDataItem> posts = postController.onViewPosts(filters: [ParentIdFilter(currentRepoId)]);
      print("build post card post number: ${posts.length}");
      if (posts.isEmpty) {
        return const Center(child: Text('No posts found.'));
      }
      return Column(children: [postCategoryLists(posts)]);
    });
  }

  Widget postCategoryLists(List<PostDataItem> postItems) {
    final Map<String, List<PostDataItem>> categoryMap = {};
    for (var postItem in postItems) {
      categoryMap.putIfAbsent(postItem.body.category, () => []).add(postItem);
    }

    return ListView(
      shrinkWrap: true,
      children: categoryMap.entries.map((entry) {
        final category = entry.key;
        final posts = entry.value;
        return ExpansionTile(
          title: Text(category),
          initiallyExpanded: true,
          controlAffinity: ListTileControlAffinity.leading,
          tilePadding: const EdgeInsets.fromLTRB(8.0, 0.0, 12.0, 0.0),
          children: posts.map((post) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ListTile(
                title: Text(post.body.title),
                subtitle: Text(post.body.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Get.toNamed('/notes/view-post', arguments: [post]);
                },
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
