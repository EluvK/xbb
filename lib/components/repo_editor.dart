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
        description: '',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
        lastSyncAt: DateTime.parse(neverSyncAt),
        remoteRepo: true,
        autoSync: true,
      );
      return _RepoEditorInner(
        repo: repo,
        enableChooseMode: true,
      );
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

enum EditRepoMode { self, shared }

class _RepoEditorInner extends StatefulWidget {
  const _RepoEditorInner({required this.repo, this.enableChooseMode = false});
  final Repo repo;
  final bool enableChooseMode;

  @override
  State<_RepoEditorInner> createState() => __RepoEditorInnerState();
}

class __RepoEditorInnerState extends State<_RepoEditorInner> {
  final repoController = Get.find<RepoController>();

  EditRepoMode editMode = EditRepoMode.self;

  @override
  Widget build(BuildContext context) {
    if (widget.repo.sharedTo != null) {
      setState(() {
        editMode = EditRepoMode.shared;
      });
    }
    Widget main;
    if (editMode == EditRepoMode.self) {
      main = _selfRepoEditor();
    } else {
      main = _sharedRepoEditor();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(
          visible: widget.enableChooseMode,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _switchModeButton(),
          ),
        ),
        Expanded(child: main),
      ],
    );
  }

  Widget _sharedRepoEditor() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _sharedLinkWidget(),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _nameWidget(),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _descriptionWidget(),
        ),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _settingWidget(),
          ),
        ),
        const Divider(),
        // Expanded(child: Placeholder()),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _toolsWidget(),
        )
      ],
    );
  }

  Widget _selfRepoEditor() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _nameWidget(),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _descriptionWidget(),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _sharedLinkWidget(),
        ),
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

  Widget _switchModeButton() {
    return SegmentedButton(
      segments: const [
        ButtonSegment(
          value: EditRepoMode.self,
          icon: Icon(Icons.create_rounded),
          label: Text('self'),
        ),
        ButtonSegment(
          value: EditRepoMode.shared,
          icon: Icon(Icons.get_app_rounded),
          label: Text('shared'),
        ),
      ],
      showSelectedIcon: false,
      selected: {editMode},
      onSelectionChanged: (value) {
        setState(() {
          editMode = value.first;
        });
      },
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
      enabled: editMode == EditRepoMode.self,
    );
  }

  Widget _descriptionWidget() {
    return TextField(
      minLines: 1,
      maxLines: 3,
      controller: TextEditingController(text: widget.repo.description),
      decoration: const InputDecoration(labelText: 'Description:'),
      onChanged: (value) {
        widget.repo.description = value;
      },
      enabled: editMode == EditRepoMode.self,
    );
  }

  Widget _sharedLinkWidget() {
    Widget shared = Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: TextField(
            minLines: 1,
            maxLines: 3,
            controller: TextEditingController(text: _sharedLink(widget.repo)),
            decoration: const InputDecoration(labelText: 'Shared Link:'),
            enabled: editMode == EditRepoMode.shared,
          ),
        ),
        Visibility(
          visible: editMode != EditRepoMode.shared,
          child: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _sharedLink(widget.repo)));
              flushBar(FlushLevel.OK, "copy to clipboard", "share to others");
            },
          ),
        ),
      ],
    );
    return Visibility(
      visible: widget.repo.remoteRepo,
      child: shared,
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
        Visibility(visible: widget.repo.id != "0", child: _remoteSetting()),
        const Divider(),
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

  String _sharedLink(Repo repo) {
    return "xbb-share://${repo.owner}/${repo.id}";
  }

  Widget _toolsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        editMode == EditRepoMode.self ? _saveButton() : _subscribeButton(),
        // _deleteButton(),
      ],
    );
  }

  Widget _saveButton() {
    return TextButton(
      onPressed: () {
        repoController.saveRepo(widget.repo);
      },
      child: const Text('保存 Repo'),
    );
  }

  Widget _subscribeButton() {
    return TextButton(
      onPressed: () {
        // repoController.deleteRepo(widget.repo.id);
      },
      child: const Text('订阅 Repo'),
    );
  }

  Widget _deleteButton() {
    return TextButton(
      onPressed: () {
        // todo();
        // repoController.deleteRepo(widget.repo.id);
      },
      child: const Text('删除 Repo'),
    );
  }
}
