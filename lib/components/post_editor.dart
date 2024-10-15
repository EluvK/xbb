import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/repo.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({super.key, this.postId});
  final String? postId;

  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();

  late String title = '';
  late String content = '';
  late String targetRepo = repoController.currentRepo.value;
  late String targetCategory = 'uncategorized';

  late Set<String> candidateCategory;

  @override
  void initState() {
    candidateCategory = postController.repoPostList
        .map((post) => post.category.toString())
        .toSet();
    if (!candidateCategory.contains('uncategorized')) {
      candidateCategory.add('uncategorized');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.postId == null) {
      return buildEditPostWidget();
    } else {
      return FutureBuilder(
        future: postController.getPost(widget.postId!),
        builder: (context, postData) {
          if (postData.hasData) {
            var post = postData.data!;
            title = post.title;
            content = post.content;
            targetRepo = post.repoId;
            targetCategory = post.category;
            return buildEditPostWidget();
          } else {
            return const CircularProgressIndicator();
          }
        },
      );
    }
  }

  Widget buildEditPostWidget() {
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

  Widget newPost() {
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
        // repo dropdown
        Flexible(
          child: DropdownButtonFormField(
            items: repoController.repoList.map((e) {
              return DropdownMenuItem(value: e.id, child: Text(e.name));
            }).toList(),
            onChanged: (value) {
              targetRepo = value!;
            },
            value: targetRepo,
          ),
        ),
        const VerticalDivider(),
        // try:
        Flexible(
          child: Autocomplete(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return candidateCategory;
              }
              var matched = candidateCategory.where((String category) {
                return category.contains(textEditingValue.text.toLowerCase());
              }).toList();
              if (!candidateCategory.contains(textEditingValue.text)) {
                matched.insert(
                    matched.length, "[new] ${textEditingValue.text}");
              }
              if (matched.isEmpty) {
                return {"[new] ${textEditingValue.text}"};
                // return Iterable<String>.generate(5, (index) => '$index');
              }
              return matched;
            },
            initialValue: TextEditingValue(text: targetCategory),
            optionsViewOpenDirection: OptionsViewOpenDirection.up,
            onSelected: (String selection) {
              print('selected $selection');
              if (selection.startsWith('[new] ')) {
                selection = selection.substring(6);
              }
              targetCategory = selection;
              print('targetCategory: $targetCategory');
            },
          ),
        ),

        const VerticalDivider(),
        // TextButton(onPressed: () {}, child: const Text('保存草稿')),
        TextButton(
          onPressed: () {
            postController.savePost(
                widget.postId, title, content, targetRepo, targetCategory);
          },
          child: const Text('保存到存储库'),
        )
      ],
    );
  }
}
