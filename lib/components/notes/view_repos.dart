import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/notes/model.dart';

class ViewRepos extends StatelessWidget {
  const ViewRepos({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 350,
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
      decoration: BoxDecoration(color: colorScheme.surface),
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<RepoDataItem> repos = repoController.onViewRepos(null);
      print("build repo card repo number: ${repos.length}");
      if (repos.isEmpty) {
        return const Center(child: Text('No repositories found.'));
      }
      return ListView.builder(
        itemCount: repos.length,
        itemBuilder: (context, index) {
          var repo = repos[index];
          return repoCardItem(repo: repo);
        },
      );
    });
  }

  Widget repoCardItem({required RepoDataItem repo}) {
    return Card(
      child: ListTile(
        title: Text(repo.body.name),
        subtitle: Text(repo.id, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () {
          postController.onSelectPost(repo.id);
          // Get.toNamed('/view-posts', arguments: [repo.id]);
        },
        onLongPress: () {
          repoController.deleteData(repo.id);
        },
        trailing: repoController.currentRepoId.value == repo.id
            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
            : null,
      ),
    );
  }
}

class _ToolLists extends StatefulWidget {
  const _ToolLists();

  @override
  State<_ToolLists> createState() => __ToolListsState();
}

class __ToolListsState extends State<_ToolLists> {
  final repoController = Get.find<RepoController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('tools'),
        Row(
          children: [
            IconButton(
              onPressed: () {
                repoController.addData(Repo(name: "name", status: "normal", description: "description"));
              },
              icon: Icon(Icons.add),
            ),
            IconButton(
              onPressed: () {
                repoController.trySyncAll();
              },
              icon: Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }
}
