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
    var defaultRepo = repoController.myRepoList.firstWhere(
      (e) => (e.id == repoController.currentRepoId.value),
      orElse: () {
        return repoController.myRepoList.first;
      },
    );
    return FutureBuilder(
      future: postController.fetchRepoPostCategories(defaultRepo.id),
      builder: (context, categories) {
        if (!categories.hasData) {
          return const CircularProgressIndicator();
        }
        var candidateCategory = categories.data!;
        if (widget.postId == null) {
          // new one
          var post = Post(
            id: const Uuid().v4(),
            category: 'uncategorized',
            title: '',
            content: '',
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            author: settingController.currentUserId.value,
            repoId: defaultRepo.id,
          );
          return _PostEditorInner(
            post: post,
            initCandidateCategory: candidateCategory,
          );
        }
        return FutureBuilder(
          future: postController.getPostUnwrap(widget.postId!),
          builder: (context, postData) {
            if (!postData.hasData) {
              return const CircularProgressIndicator();
            }
            var post = postData.data!;
            return _PostEditorInner(
              post: post,
              initCandidateCategory: candidateCategory,
            );
          },
        );
      },
    );
  }
}

class _PostEditorInner extends StatefulWidget {
  const _PostEditorInner({
    required this.post,
    required this.initCandidateCategory,
  });
  final Post post;
  final Set<String> initCandidateCategory;

  @override
  State<_PostEditorInner> createState() => _PostEditorInnerState();
}

class _PostEditorInnerState extends State<_PostEditorInner> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();

  late Set<String> candidateCategory;
  TextEditingController textEditingController = TextEditingController();

  reloadCandidateCategory(String repoId) async {
    candidateCategory = await postController.fetchRepoPostCategories(repoId);
    print('reload: ${candidateCategory.join(',')}');
  }

  @override
  void initState() {
    super.initState();
    textEditingController.text = widget.post.category;
  }

  @override
  Widget build(BuildContext context) {
    candidateCategory = widget.initCandidateCategory;
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
            isExpanded: true,
            items: repoController.myRepoList.map((e) {
              return DropdownMenuItem(value: e.id, child: Text(e.name));
            }).toList(),
            decoration: const InputDecoration(labelText: 'repo'),
            onChanged: (value) async {
              widget.post.repoId = value!;
              print('select repo:$value');
              await reloadCandidateCategory(value);
            },
            value: widget.post.repoId,
          ),
        ),
        const VerticalDivider(),
        // try:
        Flexible(
          child: Autocomplete(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              print("optionsBuilder, ${candidateCategory.join(',')}");
              if (textEditingValue.text == '') {
                return candidateCategory;
              }
              var currentValue = textEditingValue.text;
              while (currentValue.startsWith('⭐')) {
                currentValue = currentValue.substring(1);
              }
              var matched = candidateCategory.where((String category) {
                return category.contains(currentValue.toLowerCase());
              }).toList();
              if (!candidateCategory.contains(currentValue)) {
                matched.insert(0, "⭐$currentValue");
              }
              return matched;
            },
            initialValue: TextEditingValue(text: textEditingController.text),
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) =>
                    TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onFieldSubmitted: (String value) {
                onFieldSubmitted();
              },
              onTap: () {
                // i need here to trigger optionsBuilders
                setState(() {
                  // so wired, but it worked... maybe the autoComplete should be more useful.
                  textEditingController.text = textEditingController.text;
                });
              },
              decoration: const InputDecoration(labelText: 'category'),
            ),
            optionsViewOpenDirection: OptionsViewOpenDirection.up,
            onSelected: (String selection) {
              while (selection.startsWith('⭐')) {
                selection = selection.substring(1);
              }
              setState(() {
                textEditingController.text = selection;
                widget.post.category = selection;
              });
              print('onSelected category ${widget.post.category}');
            },
          ),
        ),

        const VerticalDivider(),
        // TextButton(onPressed: () {}, child: const Text('保存草稿')),
        TextButton(
          onPressed: () {
            postController.savePost(widget.post);
          },
          child: const Text(' 保存 '),
        )
      ],
    );
  }
}
