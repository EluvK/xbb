import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/new_markdown_renderer.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/markdown.dart';
import 'package:xbb/utils/rich_editor.dart';
import 'package:xbb/utils/utils.dart';

class PostEditor extends StatefulWidget {
  const PostEditor({super.key, this.postItem});
  final PostDataItem? postItem;

  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();

  @override
  Widget build(BuildContext context) {
    if (widget.postItem == null) {
      // new one
      var post = Post(category: 'uncategorized', title: '', content: '', repoId: repoController.currentRepoId.value!);
      return _PostEditorInner(post: post, existPostId: null);
    }
    var postItem = widget.postItem!;
    return _PostEditorInner(post: postItem.body, existPostId: postItem.id);
  }
}

class _PostEditorInner extends StatefulWidget {
  const _PostEditorInner({required this.post, this.existPostId});
  final Post post;
  final String? existPostId;

  @override
  State<_PostEditorInner> createState() => _PostEditorInnerState();
}

class _PostEditorInnerState extends State<_PostEditorInner> {
  final repoController = Get.find<RepoController>();
  final postController = Get.find<PostController>();

  late Set<String> candidateCategory;
  TextEditingController categoryTextEditingController = TextEditingController();
  TextEditingController contentTextEditingController = TextEditingController();

  late Post editPost;

  reloadCandidateCategory(String repoId) async {
    // todo
    candidateCategory = <String>{}; // mock a empty set for now
    // candidateCategory = await postController.fetchRepoPostCategories(repoId);
    print('reload: ${candidateCategory.join(',')}');
  }

  @override
  void initState() {
    editPost = widget.post;
    contentTextEditingController.text = editPost.content;
    categoryTextEditingController.text = editPost.category;
    contentTextEditingController.addListener(() {
      setState(() {
        editPost = editPost.copyWith(content: contentTextEditingController.text);
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
    reloadCandidateCategory(editPost.repoId);
    return Column(
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: _titleWidget()),
        Expanded(
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), child: _editorWidget()),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0), child: _toolsWidget()),
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
          controller: TextEditingController(text: editPost.title),
          decoration: InputDecoration(labelText: 'Title:', hoverColor: colorScheme.surface.withOpacity(0.2)),
          onChanged: (value) {
            editPost = editPost.copyWith(title: value);
          },
        ),
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
    var contentEditor = RichEditor(textEditingController: contentTextEditingController);

    return isMobile()
        ? contentEditor
        : Row(
            children: [
              Flexible(child: contentEditor),
              const VerticalDivider(),
              Flexible(
                child: ListView(
                  children: [MarkdownRenderer(data: contentTextEditingController.text)],
                ), // still use no-edit renderer
              ),
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
            items: repoController.onViewRepos().map((e) {
              return DropdownMenuItem(
                value: e.id,
                child: Text(e.body.name, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'repo',
              labelStyle: TextStyle(fontSize: 14),
              contentPadding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 10.0),
              isCollapsed: true,
              border: OutlineInputBorder(borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            onChanged: (value) async {
              editPost = editPost.copyWith(repoId: value!);
              print('select repo:$value');
              await reloadCandidateCategory(value);
            },
            value: editPost.repoId,
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0), child: Text('/')),
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
            initialValue: TextEditingValue(text: categoryTextEditingController.text),
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) => TextFormField(
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
                contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
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
                editPost = editPost.copyWith(category: selection);
              });
              print('onSelected category ${editPost.category}');
            },
          ),
        ),
        const VerticalDivider(width: 6),
        // TextButton(onPressed: () {}, child: const Text('保存草稿')),
        TextButton(
          onPressed: () {
            if (widget.existPostId != null) {
              postController.updateData(widget.existPostId!, editPost);
            } else {
              postController.addData(editPost);
            }
            Get.offAllNamed('/');
          },
          child: const Text(' 保存 '),
        ),
      ],
    );
  }
}
