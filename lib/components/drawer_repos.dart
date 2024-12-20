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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('my_repos'.tr),
              IconButton(
                onPressed: () async {
                  await repoController.pullRepos();
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'refresh_tooltip'.tr,
              ),
            ],
          ),
          Column(
            children: [
              for (var repo in repoController.myRepoList) reposListItem(repo),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("subscribe_repos".tr),
              IconButton(
                onPressed: () async {
                  await repoController.pullSubscribeRepos();
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'refresh_tooltip'.tr,
              )
            ],
          ),
          Column(
            children: [
              for (var repo in repoController.subscribeRepoList)
                reposListItem(repo),
            ],
          ),
        ],
      );
      return ListView(
        padding: EdgeInsets.zero,
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
      title: Row(
        children: [
          Flexible(
            child: Text(repo.name),
          ),
          if (repo.unreadCount > 0)
            Transform.translate(
                offset: const Offset(0, -6),
                child: Text("✨${repo.unreadCount} ",
                    style: const TextStyle(fontSize: 12))),
        ],
      ),
      // subtitle: Text(repo.updatedAt.toLocal().toIso8601String()),
      onTap: () {
        repoController.setCurrentRepo(repo.id);
        Get.back();
        setState(() {});
      },
      selected: repoController.currentRepoId.value == repo.id,
    );
  }
}
