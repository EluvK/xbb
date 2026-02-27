import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/expansible_list.dart';
import 'package:xbb/utils/list_tile_card.dart';
import 'package:xbb/utils/utils.dart';

class ViewPosts extends StatelessWidget {
  const ViewPosts({super.key});

  @override
  Widget build(BuildContext context) {
    final RepoController repoController = Get.find<RepoController>();
    final PostController postController = Get.find<PostController>();
    final CommentController commentController = Get.find<CommentController>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("click add post");
          Get.toNamed('/notes/edit-post', arguments: [null]);
        },
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('refreshing posts');
          final repoId = repoController.currentRepoId.value;
          if (repoId != null) {
            await runSyncTaskWithStatus([() => postController.syncChildren(repoId)], from: 0, to: 20);
            final posts = postController.onViewPosts(filters: [ParentIdFilter(repoId)]);
            await runSyncTaskWithStatus(
              [
                ...posts.map((post) {
                  return () => commentController.syncChildren(post.id);
                }),
                () => postController.rebuildLocal(),
                () => commentController.rebuildLocal(),
              ],
              from: 20,
              to: 100,
            );
          }
        },
        child: const Column(
          children: [
            NoteSyncProgressBar(),
            Expanded(child: _ViewPosts()),
          ],
        ),
      ),
    );
  }
}

// maybe future we can add a global progress bar for everything?
class NoteSyncProgressBar extends StatelessWidget {
  const NoteSyncProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<SettingController>();

    return Obx(() {
      final progress = settingController.notesSyncProgress;
      final bool isActive = progress > 0 && progress < 100;
      return AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: isActive
            ? SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
              )
            : const SizedBox.shrink(),
      );
    });
  }
}

class _ViewPosts extends StatefulWidget {
  const _ViewPosts();

  @override
  State<_ViewPosts> createState() => __ViewPostsState();
}

class __ViewPostsState extends State<_ViewPosts> with ExpansibleListMixin {
  final postController = Get.find<PostController>();
  final repoController = Get.find<RepoController>();
  final commentController = Get.find<CommentController>();
  final settingController = Get.find<SettingController>();

  late Rx<String?> currentRepoId = repoController.currentRepoId;
  // List<DataItemFilter> currentFilters = [];
  RxList<PostDataItem> viewPosts = <PostDataItem>[].obs;
  final searchFilterTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    viewPosts = postController.registerFilterSubscription(filterKey: 'view_posts', filters: []);
  }

  @override
  void dispose() {
    postController.unregisterFilterSubscription('view_posts');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Widget body;
      if (currentRepoId.value == null) {
        body = const Center(child: Text('No repository selected.'));
      } else {
        List<DataItemFilter> filters = [ParentIdFilter(currentRepoId.value!)];
        if (repoController.getRepo(currentRepoId.value!)?.colorTag != settingController.colorTag) {
          // if the current repo matches the color tag filter, we don't need to add extra filter.
          filters.add(ColorTagFilter.fromColorTag(settingController.colorTag));
        }
        if (searchFilterTextController.text.isNotEmpty) {
          filters.add(PostContentFilter(searchFilterTextController.text));
        }
        viewPosts = postController.registerFilterSubscription(filterKey: 'view_posts', filters: filters);
        body = Column(
          children: [
            Row(
              children: [
                Expanded(child: searchFilter()),
                // todo maybe move to next line if we have more buttons, remove this row.
                IconButton(
                  onPressed: toggleAll,
                  icon: Icon(isAllExpanded() ? Icons.expand_less : Icons.expand_more),
                  tooltip: isAllExpanded() ? 'expand_less_all'.tr : 'expand_more_all'.tr,
                ),
              ],
            ),
            Expanded(child: postList(viewPosts)),
          ],
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: body,
      );
    });
  }

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
    final Map<String, List<PostDataItem>> categoryMap = {};
    for (var postItem in posts) {
      categoryMap.putIfAbsent(postItem.body.category, () => []).add(postItem);
    }

    return GroupedExpansionList(
      groupedData: categoryMap,
      controllerProvider: getController,
      tilePadding: const EdgeInsets.fromLTRB(8.0, 0.0, 12.0, 0.0),
      controlAffinity: ListTileControlAffinity.leading,
      titleBuilder: (category, _) => Text(category),
      itemBuilder: (post) => _postListCard(post),
    );
  }

  Widget _postListCard(post) {
    return ListTileCard(
      dataItem: post,
      onUpdateLocalField: ({ColorTag? colorTag, SyncStatus? syncStatus}) {
        postController.onUpdateLocalField(post.id, colorTag: colorTag, syncStatus: syncStatus);
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
      enableChildrenUpdateNumber: () =>
          commentController.onViewComments(filters: [ParentIdFilter(post.id), StatusFilter.synced]).length,
    );
  }
}

class PostContentFilter extends DataItemBodyEquatableFilter<Post> {
  final String contentRegexString;
  PostContentFilter(this.contentRegexString) : _regex = RegExp(contentRegexString, caseSensitive: false);
  final RegExp _regex;

  @override
  bool applyBody(Post body) {
    return _regex.hasMatch(body.content) || _regex.hasMatch(body.title) || _regex.hasMatch(body.category);
  }

  @override
  List<Object?> get props => [contentRegexString];
}
