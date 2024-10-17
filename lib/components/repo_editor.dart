import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/repo.dart';

class RepoEditor extends StatefulWidget {
  const RepoEditor({super.key, required this.repoId});
  final String? repoId;

  @override
  State<RepoEditor> createState() => _RepoEditorState();
}

class _RepoEditorState extends State<RepoEditor> {
  final repoController = Get.find<RepoController>();

  late String name = '';

  @override
  Widget build(BuildContext context) {
    if (widget.repoId == null) {
      return buildEditRepoWidget();
    } else {
      return FutureBuilder(
          future: repoController.getRepo(widget.repoId!),
          builder: (context, repoData) {
            if (repoData.hasData) {
              var repo = repoData.data!;
              name = repo.name;
              return buildEditRepoWidget();
            } else {
              return const CircularProgressIndicator();
            }
          });
    }
  }

  Widget buildEditRepoWidget() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _nameWidget(),
        ),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _settingWidget(),
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _toolsWidget(),
        )
      ],
    );
  }

  Widget _nameWidget() {
    return TextField(
      minLines: 1,
      maxLines: 3,
      controller: TextEditingController(text: name),
      decoration: const InputDecoration(labelText: 'Repo Name:'),
      onChanged: (value) {
        name = value;
      },
    );
  }

  Widget _settingWidget() {
    return const Placeholder();
  }

  Widget _toolsWidget() {
    return TextButton(
      onPressed: () {
        repoController.saveRepo(widget.repoId, name);
      },
      child: const Text('保存 Repo'),
    );
  }
}
