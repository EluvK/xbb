import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/repo.dart';
import 'package:xbb/utils/utils.dart';

class RepoEditor extends StatefulWidget {
  const RepoEditor({super.key, required this.repoId});
  final String? repoId;

  @override
  State<RepoEditor> createState() => _RepoEditorState();
}

class _RepoEditorState extends State<RepoEditor> {
  final repoController = Get.find<RepoController>();
  final settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    if (widget.repoId == null) {
      // new onw
      var repo = Repo(
        id: const Uuid().v4(),
        name: '',
        owner: settingController.currentUserId.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSyncAt: DateTime.parse(neverSyncAt),
        remoteRepo: true,
        autoSync: true,
      );
      return _RepoEditorInner(repo: repo);
    }
    return FutureBuilder(
      future: repoController.getRepoUnwrap(widget.repoId!),
      builder: (context, repoData) {
        if (repoData.hasData) {
          var repo = repoData.data!;
          return _RepoEditorInner(repo: repo);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

class _RepoEditorInner extends StatefulWidget {
  const _RepoEditorInner({required this.repo});
  final Repo repo;

  @override
  State<_RepoEditorInner> createState() => __RepoEditorInnerState();
}

class __RepoEditorInnerState extends State<_RepoEditorInner> {
  final repoController = Get.find<RepoController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _nameWidget(),
        ),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
      controller: TextEditingController(text: widget.repo.name),
      decoration: const InputDecoration(labelText: 'Repo Name:'),
      onChanged: (value) {
        widget.repo.name = value;
      },
    );
  }

  Widget _settingWidget() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        _remoteSetting(),
        const Divider(),
        _sharedSetting(),
      ],
    );
  }

  Widget _remoteSetting() {
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const TableCell(child: Center(child: Text('remoteRepo'))),
            Switch(
              value: widget.repo.remoteRepo,
              onChanged: (value) {
                print("remoteRepo: $value");
                setState(() {
                  widget.repo.remoteRepo = value;
                  if (!value) {
                    widget.repo.autoSync = false;
                  }
                });
              },
            )
          ],
        ),
        TableRow(
          children: [
            const TableCell(child: Center(child: Text('autoSync'))),
            Switch(
              value: widget.repo.autoSync,
              onChanged: (value) {
                print("autoSync: $value");
                if (widget.repo.remoteRepo) {
                  setState(() {
                    widget.repo.autoSync = value;
                  });
                }
              },
            )
          ],
        ),
      ],
    );
  }

  Widget _sharedSetting() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'sharedLink',
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Text(_sharedLink(widget.repo)),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _sharedLink(widget.repo)));
                flushBar(FlushLevel.OK, "copy to clipboard", "share to others");
              },
            ),
          ],
        ),
      ],
    );
  }

  String _sharedLink(Repo repo) {
    return "xbb-share://${repo.owner}/${repo.id}";
  }

  Widget _toolsWidget() {
    return TextButton(
      onPressed: () {
        repoController.saveRepo(widget.repo);
      },
      child: const Text('保存 Repo'),
    );
  }
}
