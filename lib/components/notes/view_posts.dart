import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/list_tile_card.dart';
import 'package:xbb/utils/utils.dart';

class ViewPosts extends StatelessWidget {
  const ViewPosts({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: _ViewPosts(),
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
      List<DataItemFilter> filters = [ParentIdFilter(currentRepoId)];
      if (searchFilterTextController.text.isNotEmpty) {
        filters.add(PostContentFilter(searchFilterTextController.text));
      }
      print("filters length: ${filters.length}");
      List<PostDataItem> posts = postController.onViewPosts(filters: filters);
      print("build post card post number: ${posts.length}");
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        decoration: BoxDecoration(color: colorScheme.surface),
        child: Column(
          children: [
            searchFilter(),
            posts.isEmpty ? const Center(child: Text('No posts found.')) : postCategoryLists(posts),
          ],
        ),
      );
    });
  }

  final searchFilterTextController = TextEditingController();
  Widget searchFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 8.0),
      child: TextField(
        controller: searchFilterTextController,
        onTapOutside: (event) {
          print('onTapOutside');
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onChanged: (value) {
          print('onChanged $value');
          setState(() {});
        },
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: '搜索',
          suffixIcon: IconButton(
            onPressed: () {
              searchFilterTextController.text = '';
              setState(() {});
            },
            icon: const Icon(Icons.clear_rounded),
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
      ),
    );
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
            return ListTileCard(
              dataItem: post,
              onUpdateLocalField: () => postController.onUpdateLocalField(post.id),
              title: post.body.title,
              subtitle: "updated at ${readableDateStr(post.updatedAt)}",
              onTap: () {
                Get.toNamed('/notes/view-post', arguments: [post]);
              },
              enableLongPressPreview: post.body.content.length <= 300
                  ? post.body.content
                  : '${post.body.content.substring(0, 300)}...',
              onEditButton: () => Get.toNamed('/notes/edit-post', arguments: [post]),
              onDeleteButton: () => postController.deleteData(post.id),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class PostContentFilter extends DataItemBodyFilter<Post> {
  final String contentRegexString;
  PostContentFilter(this.contentRegexString);
  @override
  bool applyBody(Post body) {
    final regex = RegExp(contentRegexString, caseSensitive: false);
    return regex.hasMatch(body.content) || regex.hasMatch(body.title) || regex.hasMatch(body.category);
  }
}
