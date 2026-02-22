import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/list_tile_card.dart';
import 'package:xbb/utils/utils.dart';

class ViewPosts extends StatelessWidget {
  const ViewPosts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("click add post");
          Get.toNamed('/notes/edit-post', arguments: [null]);
        },
        child: const Icon(Icons.add),
      ),
      body: const _ViewPosts(),
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
  final settingController = Get.find<SettingController>();

  bool _allExpanded = true;
  bool _isAllExpanded() {
    for (var controller in _controllers.values) {
      if (!controller.isExpanded) {
        return false;
      }
    }
    return true;
  }

  final Map<String, ExpansibleController> _controllers = {};
  bool _isProcessing = false;
  void _toggleAll(bool expand) {
    for (var controller in _controllers.values) {
      if (expand) {
        controller.expand();
      } else {
        controller.collapse();
      }
    }
  }

  void _handleToggle() async {
    if (_isProcessing) return;
    _isProcessing = true;
    setState(() {
      _allExpanded = !_allExpanded;
    });
    _toggleAll(_allExpanded);
    await Future.delayed(const Duration(milliseconds: 300));
    _isProcessing = false;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentRepoId = repoController.currentRepoId.value;
      Widget body;
      if (currentRepoId == null) {
        body = const Center(child: Text('No repository selected.'));
      } else {
        List<DataItemFilter> filters = [ParentIdFilter(currentRepoId)];
        if (repoController
            .onViewRepos(
              filters: [
                IdsFilter([currentRepoId]),
                ColorTagFilter.fromColorTag(settingController.colorTag),
              ],
            )
            .isEmpty) {
          // if the current repo matches the color tag filter, we don't need to add extra filter.
          filters.add(ColorTagFilter.fromColorTag(settingController.colorTag));
        }
        if (searchFilterTextController.text.isNotEmpty) {
          filters.add(PostContentFilter(searchFilterTextController.text));
        }
        print("filters length: ${filters.length}");
        List<PostDataItem> posts = postController.onViewPosts(filters: filters);
        print("build post card post number: ${posts.length}");
        body = Column(
          children: [
            Row(
              children: [
                Expanded(child: searchFilter()),
                // todo maybe move to next line if we have more buttons, remove this row.
                IconButton(
                  onPressed: _handleToggle,
                  icon: Icon(_isAllExpanded() ? Icons.expand_less : Icons.expand_more),
                  tooltip: _isAllExpanded() ? 'expand_less_all'.tr : 'expand_more_all'.tr,
                ),
              ],
            ),
            Expanded(child: postList(posts)),
          ],
        );
      }
      final colorScheme = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        decoration: BoxDecoration(color: colorScheme.surface),
        child: body,
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

  Widget postList(List<PostDataItem> posts) {
    print("build post card post number: ${posts.length}");
    if (posts.isEmpty) {
      return const Center(child: Text('No posts found.'));
    }

    final Map<String, List<PostDataItem>> categoryMap = {};
    for (var postItem in posts) {
      categoryMap.putIfAbsent(postItem.body.category, () => []).add(postItem);
    }

    return ListView(
      children: categoryMap.entries.map((entry) {
        final category = entry.key;
        final posts = entry.value;
        final controller = _controllers.putIfAbsent(category, () {
          final controller = ExpansibleController();
          controller.expand();
          return controller;
        });
        return ExpansionTile(
          title: Text(category),
          controller: controller,
          controlAffinity: ListTileControlAffinity.leading,
          tilePadding: const EdgeInsets.fromLTRB(8.0, 0.0, 12.0, 0.0),
          children: posts.map((post) => _postListCard(post)).toList(),
        );
      }).toList(),
    );
  }

  Widget _postListCard(post) {
    return ListTileCard(
      dataItem: post,
      onUpdateLocalField: () {
        postController.onUpdateLocalField(post.id);
        // tricky way to refresh parent repo list. should be better.
        repoController.rebuildLocal();
      },
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
