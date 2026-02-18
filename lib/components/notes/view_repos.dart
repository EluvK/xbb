import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/list_tile_card.dart';

class ViewRepos extends StatelessWidget {
  const ViewRepos({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: const _RepoLists(),
    );
  }
}

class _RepoLists extends StatefulWidget {
  const _RepoLists();

  @override
  State<_RepoLists> createState() => __RepoListsState();
}

class __RepoListsState extends State<_RepoLists> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();
  final settingController = Get.find<NewSettingController>();
  final userManagerController = Get.find<UserManagerController>();

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
    return Column(
      children: [
        toolList(),
        Expanded(child: repoList(context)),
      ],
    );
  }

  Widget repoList(BuildContext context) {
    return Obx(() {
      List<String> taggedRepoIds = postController
          .onViewPosts(filters: [ColorTagFilter.fromColorTag(settingController.colorTag)])
          .map((post) => post.body.repoId)
          .toSet()
          .toList();
      List<RepoDataItem> repos = repoController.onViewRepos(
        filters: [
          OrFilter([ColorTagFilter.fromColorTag(settingController.colorTag), IdsFilter(taggedRepoIds)]),
          StatusFilter.notHidden,
        ],
      );
      print("build repo card repo number: ${repos.length}");
      if (repos.isEmpty) {
        return const Center(child: Text('No repositories found.'));
      }

      final Map<String, List<RepoDataItem>> reposByOwner = {};
      for (var repo in repos) {
        reposByOwner.putIfAbsent(repo.owner, () => []).add(repo);
      }
      // self repo first
      final List<String> sortedKeys = reposByOwner.keys.toList();
      sortedKeys.sort((a, b) {
        if (a == userManagerController.selfProfile.value?.userId) return -1;
        if (b == userManagerController.selfProfile.value?.userId) return 1;
        return a.compareTo(b);
      });

      return ListView(
        shrinkWrap: true,
        children: sortedKeys.map((ownerId) {
          bool isSelf = ownerId == userManagerController.selfProfile.value?.userId;
          UserProfile? ownerProfile = isSelf
              ? userManagerController.selfProfile.value
              : userManagerController.userProfiles.firstWhereOrNull((p) => p.userId == ownerId);
          List<RepoDataItem> ownerRepos = reposByOwner[ownerId]!;

          final controller = _controllers.putIfAbsent(ownerId, () {
            final controller = ExpansibleController();
            controller.expand();
            return controller;
          });
          return ExpansionTile(
            title: Row(
              children: [
                isSelf
                    ? const Icon(Icons.star, color: Colors.orangeAccent)
                    : const Icon(Icons.share_outlined, color: Colors.blueAccent),
                const SizedBox(width: 4.0),
                buildUserAvatar(context, ownerProfile?.avatarUrl, size: 16, selected: false),
                const SizedBox(width: 8.0),
                Text(ownerProfile?.name ?? 'Unknown User'),
              ],
            ),
            tilePadding: const EdgeInsets.fromLTRB(2.0, 0.0, 12.0, 0.0),
            controller: controller,
            controlAffinity: ListTileControlAffinity.trailing,
            children: ownerRepos.map((repo) => _repoListTileCard(repo)).toList(),
          );
        }).toList(),
      );
    });
  }

  Widget _repoListTileCard(RepoDataItem repo) {
    return ListTileCard(
      dataItem: repo,
      onUpdateLocalField: () => repoController.onUpdateLocalField(repo.id),
      title: repo.body.name,
      subtitle: repo.body.description,
      onTap: () {
        setState(() {
          repoController.onSelectRepo(repo.id);
          settingController.updateUserInterfaceHistoryCache(notesLastOpenedRepoId: repo.id);
        });
        // Close the drawer on phone when tab changes
        if (MediaQuery.of(context).size.width < 600) {
          Get.back();
        }
      },
      isSelected: repoController.currentRepoId.value == repo.id,
      enableSwitchArchivedStatus: false,
      onEditButton: () => Get.toNamed('/notes/edit-repo', arguments: [repo]),
      onDeleteButton: () => repoController.deleteData(repo.id),
      onDeleteButtonCondition: () => postController.onViewPosts(filters: [ParentIdFilter(repo.id)]).isEmpty,
      enableChildrenUpdateNumber: () =>
          postController.onViewPosts(filters: [ParentIdFilter(repo.id), StatusFilter.synced]).length,
    );
  }

  // ToolLists
  Widget toolList() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                repoController.addData(const Repo(name: "name", status: "normal", description: "description"));
              },
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: () async {
                await repoController.syncOwned();
                await repoController.syncGranted();
                await repoController.rebuildLocal();
                await repoController.syncAcls();
                // todo, post might sync in child granularity
                await postController.syncOwned();
                await postController.syncGranted();
                await postController.rebuildLocal();
              },
              icon: const Icon(Icons.refresh),
            ),
            const Spacer(),
            IconButton(
              onPressed: _handleToggle,
              icon: Icon(_isAllExpanded() ? Icons.expand_less : Icons.expand_more),
              tooltip: _isAllExpanded() ? 'expand_less_all'.tr : 'expand_more_all'.tr,
            ),
          ],
        ),
      ],
    );
  }
}
