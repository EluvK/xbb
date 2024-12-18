import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/repo.dart';
import 'package:xbb/utils/double_click.dart';
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
        unreadCount: 0,
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
  final settingController = Get.find<SettingController>();

  EditRepoMode editMode = EditRepoMode.self;

  @override
  Widget build(BuildContext context) {
    if (widget.repo.sharedTo != null &&
        widget.repo.sharedTo == settingController.currentUserId.value) {
      setState(() {
        editMode = EditRepoMode.shared;
      });
    }
    if (!widget.enableChooseMode) {
      widget.repo.sharedLink = sharedLink(widget.repo.owner, widget.repo.id);
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
      segments: [
        ButtonSegment(
          value: EditRepoMode.self,
          icon: const Icon(Icons.create_rounded),
          label: Text('repo_type_self'.tr),
        ),
        ButtonSegment(
          value: EditRepoMode.shared,
          icon: const Icon(Icons.get_app_rounded),
          label: Text('repo_type_shared'.tr),
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
      decoration: InputDecoration(labelText: 'repo_name'.tr),
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
      decoration: InputDecoration(labelText: 'description'.tr),
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
            controller:
                TextEditingController(text: widget.repo.sharedLink ?? ''),
            onChanged: (value) {
              widget.repo.sharedLink = value;
            },
            decoration: InputDecoration(labelText: 'shared_link'.tr),
            enabled: editMode == EditRepoMode.shared && widget.enableChooseMode,
          ),
        ),
        Visibility(
          visible: editMode != EditRepoMode.shared && !widget.enableChooseMode,
          child: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: widget.repo.sharedLink ?? ''));
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
        // todo: remoteRepo?
        Visibility(
            visible: widget.repo.id != "0" && false, child: _remoteSetting()),
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

  Widget _toolsWidget() {
    List<Widget> buttonList = [];
    switch (editMode) {
      case EditRepoMode.self:
        buttonList.add(_saveButton());
        if (!widget.enableChooseMode) {
          buttonList.add(_deleteButton());
        }
        break;
      case EditRepoMode.shared:
        buttonList.add(_subscribeButton());
        if (!widget.enableChooseMode) {
          buttonList.add(_unsubscribeButton());
        }
        break;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttonList,
    );
  }

  Widget _saveButton() {
    return TextButton(
      onPressed: () {
        widget.repo.updatedAt = DateTime.now().toUtc();
        repoController.saveRepo(widget.repo);
        Get.toNamed('/');
      },
      child: const Text('保存 Repo'),
    );
  }

  Widget _deleteButton() {
    return DoubleClickButton(
      buttonBuilder: (onPressed) => TextButton(
        onPressed: onPressed,
        child: Text('删除 Repo', style: TextStyle(color: Colors.red[600])),
      ),
      onDoubleClick: () {
        repoController.deleteRepo(widget.repo);
        Get.toNamed('/');
      },
      firstClickHint: '删除 Repo',
      upperPosition: true,
    );
  }

  Widget _subscribeButton() {
    return TextButton(
      onPressed: () {
        print('$editMode ${widget.repo.sharedLink}');
        if (widget.repo.sharedLink != null) {
          repoController.doSubscribeRepo(widget.repo.sharedLink!).then((repo) {
            if (repo != null) {
              setState(() {
                widget.repo.name = repo.name;
                widget.repo.description = repo.description;
              });
              Get.toNamed('/');
              flushBar(FlushLevel.OK, "subscribe", "success");
            } else {
              Get.toNamed('/');
              flushBar(FlushLevel.WARNING, "subscribe", "fail");
            }
          });
        }
      },
      child: const Text('订阅 Repo'),
    );
  }

  Widget _unsubscribeButton() {
    return TextButton(
      onPressed: () {
        repoController.doUnsubscribeRepo(widget.repo.id);
        Get.toNamed('/');
      },
      child: Text('取消订阅 Repo', style: TextStyle(color: Colors.red[600])),
    );
  }
}
