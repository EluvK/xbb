import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/list_tile_card.dart';

class ViewRepos extends StatelessWidget {
  const ViewRepos({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: const Column(
        children: [
          // Text('repositories'),
          _ToolLists(),
          Expanded(child: _RepoLists()),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<RepoDataItem> repos = repoController.onViewRepos(
        filters: [ColorTagFilter.fromColorTag(settingController.colorTag)],
      );
      print("build repo card repo number: ${repos.length}");
      if (repos.isEmpty) {
        return const Center(child: Text('No repositories found.'));
      }
      return ListView.builder(
        itemCount: repos.length,
        itemBuilder: (context, index) {
          var repo = repos[index];
          return ListTileCard(
            dataItem: repo,
            onUpdateLocalField: () => repoController.onUpdateLocalField(repo.id),
            title: repo.body.name,
            subtitle: repo.body.description,
            onTap: () {
              setState(() {
                repoController.onSelectRepo(repo.id);
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
        },
      );
    });
  }
}

class _ToolLists extends StatefulWidget {
  const _ToolLists();

  @override
  State<_ToolLists> createState() => __ToolListsState();
}

class __ToolListsState extends State<_ToolLists> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // const Divider(),
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
                await repoController.trySyncAll();
                await postController.trySyncAll();
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }
}
