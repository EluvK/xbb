import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/repo.dart';

class NewPostEditor extends StatefulWidget {
  const NewPostEditor({super.key});

  @override
  State<NewPostEditor> createState() => _NewPostEditorState();
}

class _NewPostEditorState extends State<NewPostEditor> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();

  String title = '';
  String content = '';
  late String targetRepo = repoController.currentRepo.value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _titleWidget(),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _editorWidget(),
        )),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _toolsWidget(),
        ),
      ],
    );
  }

  Widget _titleWidget() {
    return Column(
      children: [
        TextField(
          minLines: 1,
          maxLines: 3,
          controller: TextEditingController(text: title),
          onChanged: (value) {
            title = value;
          },
        )
      ],
    );
  }

  Widget _editorWidget() {
    return TextField(
      expands: true,
      maxLines: null,
      textAlignVertical: TextAlignVertical.top,
      controller: TextEditingController(text: content),
      onChanged: (value) {
        content = value;
      },
    );
  }

  Widget _toolsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(onPressed: () {}, child: const Text('保存草稿')),
        const VerticalDivider(),
        Flexible(
          child: DropdownButtonFormField(
            items: repoController.repoList().map((e) {
              return DropdownMenuItem(value: e.id, child: Text(e.name));
            }).toList(),
            onChanged: (value) {
              targetRepo = value!;
            },
            value: targetRepo,
          ),
        ),
        TextButton(
          onPressed: () {
            postController.savePost(title, content, targetRepo);
            Get.back();
          },
          child: const Text('保存到存储库'),
        )
      ],
    );
  }
}
