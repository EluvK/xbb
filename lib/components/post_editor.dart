import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/post.dart';
import 'package:xbb/utils/markdown.dart';
import 'package:xbb/utils/rich_editor.dart';
import 'package:xbb/utils/utils.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({super.key, this.post});
  final Post? post;

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
        if (widget.post == null) {
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
        return _PostEditorInner(
          post: widget.post!,
          initCandidateCategory: candidateCategory,
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
  TextEditingController categoryTextEditingController = TextEditingController();
  TextEditingController contentTextEditingController = TextEditingController();

  reloadCandidateCategory(String repoId) async {
    candidateCategory = await postController.fetchRepoPostCategories(repoId);
    print('reload: ${candidateCategory.join(',')}');
  }

  @override
  void initState() {
    contentTextEditingController.text = widget.post.content;
    categoryTextEditingController.text = widget.post.category;
    contentTextEditingController.addListener(() {
      setState(() {
        widget.post.content = contentTextEditingController.text;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    contentTextEditingController.dispose();
    categoryTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    candidateCategory = widget.initCandidateCategory;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: _titleWidget(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: _editorWidget(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
          child: _toolsWidget(),
        ),
      ],
    );
  }

  Widget _titleWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TextField(
          minLines: 1,
          maxLines: 3,
          controller: TextEditingController(text: widget.post.title),
          decoration: InputDecoration(
            labelText: 'Title:',
            hoverColor: colorScheme.surface.withOpacity(0.2),
          ),
          onChanged: (value) {
            widget.post.title = value;
          },
        )
      ],
    );
  }

  Widget _editorWidget() {
    // var contentEditor = TextField(
    //   expands: true,
    //   maxLines: null,
    //   textAlignVertical: TextAlignVertical.top,
    //   controller: contentTextEditingController,
    //   decoration: const InputDecoration(
    //     labelText: 'contents:',
    //     alignLabelWithHint: true,
    //   ),
    // );
    var contentEditor = RichEditor(
      textEditingController: contentTextEditingController,
    );

    return isMobile()
        ? contentEditor
        : Row(
            children: [
              Flexible(child: contentEditor),
              const VerticalDivider(),
              Flexible(
                  child: ListView(
                children: [
                  MarkdownRenderer(data: contentTextEditingController.text)
                ],
              )),
            ],
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
              return DropdownMenuItem(
                value: e.id,
                child: Text(e.name, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'repo',
              labelStyle: TextStyle(fontSize: 14),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
              isCollapsed: true,
              border: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            onChanged: (value) async {
              widget.post.repoId = value!;
              print('select repo:$value');
              await reloadCandidateCategory(value);
            },
            value: widget.post.repoId,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
          child: Text('/'),
        ),
        // try:
        Flexible(
          child: Autocomplete(
            optionsViewOpenDirection: OptionsViewOpenDirection.up,
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
            initialValue:
                TextEditingValue(text: categoryTextEditingController.text),
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) =>
                    TextFormField(
              style: const TextStyle(fontSize: 14),
              strutStyle: const StrutStyle(fontSize: 16),
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
              decoration: const InputDecoration(
                labelText: 'category',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                floatingLabelStyle: TextStyle(fontSize: 14),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                isCollapsed: true,
                border: OutlineInputBorder(borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            onSelected: (String selection) {
              while (selection.startsWith('⭐')) {
                selection = selection.substring(1);
              }
              setState(() {
                categoryTextEditingController.text = selection;
                widget.post.category = selection;
              });
              print('onSelected category ${widget.post.category}');
            },
          ),
        ),
        const VerticalDivider(width: 6),
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
