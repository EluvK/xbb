import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';

class PostFilter extends StatefulWidget {
  const PostFilter({super.key});

  @override
  State<PostFilter> createState() => _PostFilterState();
}

class _PostFilterState extends State<PostFilter> {
  final postController = Get.find<PostController>();

  final searchFilterTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 4.0, 10.0, 8.0),
          child: searchFilter(),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  postController.markedAllAsRead();
                },
                icon: const Icon(Icons.mark_email_read_rounded),
                tooltip: '全部标记为已读',
              ),
              const SizedBox(
                  height: 30, child: VerticalDivider(thickness: 2.0)),
              buttonFilter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget searchFilter() {
    return TextField(
      controller: searchFilterTextController,
      onTapOutside: (event) {
        print('onTapOutside');
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onChanged: (value) {
        print('onChanged $value');
        postController.setViewFilter(regex: value);
        setState(() {});
      },
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: '搜索',
        suffixIcon: IconButton(
          onPressed: () {
            searchFilterTextController.text = '';
            postController.setViewFilter(regex: '');
            setState(() {});
          },
          icon: const Icon(Icons.clear_rounded),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
    );
  }

  Widget buttonFilter() {
    return Row(
      children: [
        const Text('过滤  '),
        SegmentedButton(
          segments: const [
            ButtonSegment<PostViewFilter>(
              tooltip: 'all',
              value: PostViewFilter.all,
              icon: Icon(Icons.all_inclusive_outlined),
            ),
            ButtonSegment<PostViewFilter>(
              tooltip: 'unread',
              value: PostViewFilter.unread,
              icon: Icon(Icons.mark_email_unread_rounded),
            ),
            ButtonSegment<PostViewFilter>(
              tooltip: 'like',
              value: PostViewFilter.stars,
              icon: Icon(Icons.star_rounded),
            ),
          ],
          selected: {postController.typeFilter.value},
          onSelectionChanged: (Set<PostViewFilter> newSelection) {
            postController.setViewFilter(type: newSelection.first);
            setState(() {});
          },
        ),
      ],
    );
  }
}
