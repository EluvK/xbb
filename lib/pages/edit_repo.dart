import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/repo_editor.dart';

class EditRepoPage extends StatelessWidget {
  const EditRepoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final String? repoId = args?[0];
    final String? repoName = args?[1];
    return Scaffold(
      appBar: AppBar(
          title: Text(repoName != null
              ? 'edit_repo'.trParams({'repoName': repoName})
              : 'new_repo'.tr)),
      body: RepoEditor(
        repoId: repoId,
      ),
    );
  }
}
