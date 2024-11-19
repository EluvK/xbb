import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/model/repo.dart';

class DrawerRepos extends StatefulWidget {
  const DrawerRepos({super.key});

  @override
  State<DrawerRepos> createState() => _DrawerReposState();
}

class _DrawerReposState extends State<DrawerRepos> {
  final repoController = Get.find<RepoController>();

  @override
  Widget build(BuildContext context) {
    // print(
    //     "repoController.myRepoList.length: ${repoController.myRepoList.length}");
    // print(
    //     "repoController.subscribeRepoList.length: ${repoController.subscribeRepoList.length}");

    return Obx(() {
      var body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(child: Text('MyRepos')),
              IconButton(
                onPressed: () async {
                  await repoController.pullRepos();
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'refresh',
              ),
              IconButton(
                onPressed: () {
                  Get.toNamed('/edit-repo');
                },
                icon: const Icon(Icons.add),
                tooltip: 'New repo',
              )
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: repoController.myRepoList.length,
            itemBuilder: (context, index) {
              return reposListItem(repoController.myRepoList[index]);
            },
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subscribe"),
              IconButton(
                onPressed: () async {
                  await repoController.pullSubscribeRepos();
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'update',
              )
            ],
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: repoController.subscribeRepoList.length,
            itemBuilder: (context, index) {
              return reposListItem(repoController.subscribeRepoList[index]);
            },
          ),
        ],
      );
      return ListView(
        children: [body],
      );
    });
  }

  Widget reposListItem(Repo repo) {
    return ListTile(
      trailing: Visibility(
        visible: repo.id != '0',
        child: IconButton(
            onPressed: () {
              Get.toNamed('/edit-repo', arguments: [repo.id, repo.name]);
            },
            icon: const Icon(Icons.edit)),
      ),
      title: Text(repo.name),
      // subtitle: Text(repo.updatedAt.toLocal().toIso8601String()),
      onTap: () {
        repoController.setCurrentRepo(repo.id);
        Get.back();
      },
      selected: repoController.isCurrentRepo(repo.id),
    );
  }
}
