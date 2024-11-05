import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/post.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({super.key, this.postId});
  final String? postId;

  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  final settingController = Get.find<SettingController>();
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();
  @override
  Widget build(BuildContext context) {
    if (widget.postId == null) {
      // new one
      var post = Post(
        id: const Uuid().v4(),
        category: '',
        title: '',
        content: '',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        author: settingController.currentUserId.value,
        repoId: repoController.currentRepoId.value,
      );
      return _PostEditorInner(post: post);
    }
    return FutureBuilder(
      future: postController.getPostUnwrap(widget.postId!),
      builder: (context, postData) {
        if (postData.hasData) {
          var post = postData.data!;
          return _PostEditorInner(post: post);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class _PostEditorInner extends StatefulWidget {
  const _PostEditorInner({required this.post});
  final Post post;

  @override
  State<_PostEditorInner> createState() => _PostEditorInnerState();
}

class _PostEditorInnerState extends State<_PostEditorInner> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();

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

  Future<void> loadOtherRepoCandidateCategory(String repoId) async {
    candidateCategory = await postController.fetchRepoPostCategories(repoId);
    if (!candidateCategory.contains('uncategorized')) {
      candidateCategory.add('uncategorized');
    }
    if (!candidateCategory.contains(widget.post.category)) {
      widget.post.category = 'uncategorized';
    }
  }

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
          ),
        ),
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
          controller: TextEditingController(text: widget.post.title),
          decoration: const InputDecoration(labelText: 'Title:'),
          onChanged: (value) {
            widget.post.title = value;
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
      controller: TextEditingController(text: widget.post.content),
      decoration: const InputDecoration(
        labelText: 'contents:',
        alignLabelWithHint: true,
      ),
      onChanged: (value) {
        widget.post.content = value;
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
            decoration: const InputDecoration(labelText: 'repo'),
            onChanged: (value) async {
              widget.post.repoId = value!;
              await loadOtherRepoCandidateCategory(widget.post.repoId);
            },
            value: widget.post.repoId,
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
            initialValue: TextEditingValue(text: widget.post.category),
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) =>
                    TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
              decoration: const InputDecoration(labelText: 'category'),
            ),
            optionsViewOpenDirection: OptionsViewOpenDirection.up,
            onSelected: (String selection) {
              print('selected $selection');
              if (selection.startsWith('[new] ')) {
                selection = selection.substring(6);
              }
              widget.post.category = selection;
            },
          ),
        ),

        const VerticalDivider(),
        // TextButton(onPressed: () {}, child: const Text('保存草稿')),
        TextButton(
          onPressed: () {
            postController.savePost(widget.post);
          },
          child: const Text('保存到存储库'),
        )
      ],
    );
  }
}
