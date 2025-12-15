import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/text_input.dart';

class RepoEditor extends StatefulWidget {
  const RepoEditor({super.key, required this.repoItem});
  final RepoDataItem repoItem;

  @override
  State<RepoEditor> createState() => _RepoEditorState();
}

class _RepoEditorState extends State<RepoEditor> {
  late Repo _editedRepo;

  @override
  void initState() {
    _editedRepo = widget.repoItem.body.copyWith();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
        child: Column(
          children: [
            Expanded(child: body()),
            buttons(),
          ],
        ),
      ),
    );
  }

  Widget body() {
    return ListView(
      children: [
        Text('Repo Info', style: Theme.of(context).textTheme.titleMedium),
        TextInputWidget(
          title: InputTitleEnum.title,
          initialValue: _editedRepo.name,
          onChanged: (value) {
            _editedRepo = _editedRepo.copyWith(name: value);
          },
        ),
        TextInputWidget(
          title: InputTitleEnum.description,
          initialValue: _editedRepo.description ?? '',
          onChanged: (value) {
            _editedRepo = _editedRepo.copyWith(description: value);
          },
          optional: true,
        ),
      ],
    );
  }

  Widget buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('cancel'.tr),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            // save repo
            final repoController = Get.find<RepoController>();
            repoController.updateData(widget.repoItem.id, _editedRepo);
            Navigator.pop(context);
          },
          child: Text('save'.tr),
        ),
      ],
    );
  }
}
