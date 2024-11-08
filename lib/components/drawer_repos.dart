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
    print("repoController.repoList.length: ${repoController.repoList.length}");
    print("repoController.repoList: ${repoController.repoList}");

    return Obx(() {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('MyRepos'),
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
            itemCount: repoController.repoList.length,
            itemBuilder: (context, index) {
              return reposListItem(repoController.repoList[index]);
            },
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Subscribe"),
              IconButton(
                  onPressed: () {
                    //todo
                  },
                  icon: const Icon(Icons.refresh))
            ],
          )
        ],
      );
    });
  }

  Widget reposListItem(Repo repo) {
    return ListTile(
      trailing: IconButton(
          onPressed: () {
            Get.toNamed('edit-repo', arguments: [repo.id]);
          },
          icon: const Icon(Icons.edit)),
      title: Text(repo.name),
      onTap: () {
        repoController.setCurrentRepo(repo.id);
        Get.back();
      },
      selected: repoController.isCurrentRepo(repo.id),
    );
  }
}
