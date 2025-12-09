import 'package:flutter/widgets.dart';
import 'package:xbb/models/notes/model.dart';

class RepoEditor extends StatefulWidget {
  const RepoEditor({super.key, this.repoItem});
  final RepoDataItem? repoItem;

  @override
  State<RepoEditor> createState() => _RepoEditorState();
}

class _RepoEditorState extends State<RepoEditor> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
