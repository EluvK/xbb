import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/repo.dart';

class DrawerRepos extends StatefulWidget {
  const DrawerRepos({super.key});

  @override
  State<DrawerRepos> createState() => _DrawerReposState();
}

class _DrawerReposState extends State<DrawerRepos> {
  final repoController = Get.find<RepoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        children: [
          const Text('Repos'),
          for (var repo in repoController.repoList)
            ListTile(
              title: Text(repo.name),
              onTap: () {
                repoController.setCurrentRepo(repo.id);
              },
              selected: repoController.currentRepo.value == repo.id,
            ),
        ],
      );
    });
  }
}
