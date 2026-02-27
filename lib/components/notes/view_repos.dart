import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/expansible_list.dart';
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

class RepoQuickSwitcher extends StatelessWidget {
  const RepoQuickSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final repoController = Get.find<RepoController>();
    final postController = Get.find<PostController>();
    final settingController = Get.find<SettingController>();

    return Obx(() {
      final taggedReposId = postController.getPostDetails(
        selector: (post) => post.id,
        filters: [ColorTagFilter.fromColorTag(settingController.colorTag)],
      );
      final repos = repoController.getRepoDetails(
        selector: (repo) => repo,
        filters: [
          OrFilter([ColorTagFilter.fromColorTag(settingController.colorTag), IdsFilter(taggedReposId.toList())]),
          StatusFilter.notHidden,
        ],
      );

      if (repos.isEmpty) {
        return const Text('...');
      }

      final current = repos.firstWhereOrNull((r) => r.id == repoController.currentRepoId.value);
      final title = current?.body.name ?? 'Select Repo';

      return PopupMenuButton<RepoDataItem>(
        tooltip: 'Switch repository',
        itemBuilder: (ctx) => repos.map((r) => PopupMenuItem(value: r, child: Text(r.body.name))).toList(),
        onSelected: (r) {
          repoController.onSelectRepo(r.id);
          settingController.updateUserInterfaceHistoryCache(notesLastOpenedRepoId: r.id);
          if (MediaQuery.of(context).size.width < 600) {
            final scaffoldState = Scaffold.maybeOf(context);
            if (scaffoldState != null && scaffoldState.isDrawerOpen) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      );
    });
  }
}

class _RepoLists extends StatefulWidget {
  const _RepoLists();

  @override
  State<_RepoLists> createState() => __RepoListsState();
}

class __RepoListsState extends State<_RepoLists> with ExpansibleListMixin {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();
  final settingController = Get.find<SettingController>();
  final userManagerController = Get.find<UserManagerController>();

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
      final taggedRepoIds = postController
          .getPostDetails(
            selector: (post) => post.body.repoId,
            filters: [ColorTagFilter.fromColorTag(settingController.colorTag)],
          )
          .toSet();
      final repos = repoController.getRepoDetails(
        selector: (repo) => repo,
        filters: [
          OrFilter([ColorTagFilter.fromColorTag(settingController.colorTag), IdsFilter(taggedRepoIds.toList())]),
          StatusFilter.notHidden,
        ],
      );
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
      return GroupedExpansionList<String, RepoDataItem>(
        groupedData: sortedKeys.asMap().map((index, ownerId) => MapEntry(ownerId, reposByOwner[ownerId]!)),
        controllerProvider: getController,
        tilePadding: const EdgeInsets.fromLTRB(2.0, 0.0, 12.0, 0.0),
        controlAffinity: ListTileControlAffinity.trailing,
        titleBuilder: (ownerId, _) => _buildUserTitle(ownerId),
        itemBuilder: (repo) => _repoListTileCard(repo),
      );
    });
  }

  Widget _buildUserTitle(String ownerId) {
    bool isSelf = ownerId == userManagerController.selfProfile.value?.userId;
    UserProfile? ownerProfile = isSelf
        ? userManagerController.selfProfile.value
        : userManagerController.userProfiles.firstWhereOrNull((p) => p.userId == ownerId);
    return Row(
      children: [
        isSelf
            ? const Icon(Icons.star, color: Colors.orangeAccent)
            : const Icon(Icons.share_outlined, color: Colors.blueAccent),
        const SizedBox(width: 4.0),
        buildUserAvatar(context, ownerProfile?.avatarUrl, size: 16, selected: false),
        const SizedBox(width: 8.0),
        Text(ownerProfile?.name ?? 'Unknown User'),
      ],
    );
  }

  Widget _repoListTileCard(RepoDataItem repo) {
    return ListTileCard(
      dataItem: repo,
      onUpdateLocalField: ({ColorTag? colorTag, SyncStatus? syncStatus}) =>
          repoController.onUpdateLocalField(repo.id, colorTag: colorTag, syncStatus: syncStatus),
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
                await runSyncTaskWithStatus(
                  [
                    () => repoController.syncOwned(),
                    () => repoController.syncGranted(),
                    () => repoController.rebuildLocal(),
                    () => repoController.syncAcls(),
                    () => postController.syncOwned(),
                  ],
                  from: 0.0,
                  to: 50.0,
                );
                final reposId = repoController.getRepoDetails(
                  selector: (repo) => repo.id,
                  filters: [StatusFilter.notHidden],
                );
                await runSyncTaskWithStatus(
                  [
                    ...reposId.map((repoId) {
                      return () => postController.syncChildren(repoId);
                    }),
                    () => postController.rebuildLocal(),
                  ],
                  from: 50.0,
                  to: 100.0,
                );
              },
              icon: const Icon(Icons.refresh),
            ),
            const Spacer(),
            IconButton(
              onPressed: toggleAll,
              icon: Icon(isAllExpanded() ? Icons.expand_less : Icons.expand_more),
              tooltip: isAllExpanded() ? 'expand_less_all'.tr : 'expand_more_all'.tr,
            ),
          ],
        ),
      ],
    );
  }
}
