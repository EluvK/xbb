import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/acl_editor.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/text_input.dart';

class RepoEditor extends StatefulWidget {
  const RepoEditor({super.key, required this.repoItem});
  final RepoDataItem repoItem;

  @override
  State<RepoEditor> createState() => _RepoEditorState();
}

class _RepoEditorState extends State<RepoEditor> {
  late Repo _editedRepo;

  @override
  void initState() {
    _editedRepo = widget.repoItem.body.copyWith();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
        child: ListView(children: [_editRepo(), _editRepoAcl()]),
      ),
    );
  }

  Widget _editRepo() {
    return Column(
      children: [
        Text('Update Repo Info'.tr, style: Theme.of(context).textTheme.titleMedium),
        TextInputWidget(
          title: InputTitleEnum.title,
          initialValue: _editedRepo.name,
          onChanged: (value) {
            _editedRepo = _editedRepo.copyWith(name: value);
          },
        ),
        TextInputWidget(
          title: InputTitleEnum.description,
          initialValue: _editedRepo.description ?? '',
          onChanged: (value) {
            _editedRepo = _editedRepo.copyWith(description: value);
          },
          optional: true,
        ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                // save repo
                final repoController = Get.find<RepoController>();
                repoController.updateData(widget.repoItem.id, _editedRepo);
                Navigator.pop(context);
              },
              child: Text('save'.tr),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget _editRepoAcl() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Update Repo ACL'.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        Text('Repo ACL editing is not implemented yet.'.tr),
        // todo fetch current permission and loading circular indicator
        // then show AclEditor when data is ready
        AclEditor(schema: RepoPermissionSchema(), initialPermissions: []),
      ],
    );
  }
}

class RepoPermissionSchema implements PermissionSchema {
  // todo carefully check the labels and access levels
  @override
  List<String> get labels => ['read&&comment'.tr, 'write'.tr, 'fullAccess'.tr];

  @override
  List<bool> decode(AccessLevel accessLevels) {
    switch (accessLevels) {
      case AccessLevel.none:
        return [false, false, false];
      case AccessLevel.read:
        return [true, false, false];
      case AccessLevel.update:
        return [true, true, false];
      case AccessLevel.create:
        return [true, true, false];
      case AccessLevel.write:
        return [true, true, false];
      case AccessLevel.fullAccess:
        return [true, true, true];
    }
  }

  @override
  AccessLevel encode(List<bool> accessList) {
    if (accessList[2]) {
      return AccessLevel.fullAccess;
    } else if (accessList[1]) {
      return AccessLevel.write;
    } else if (accessList[0]) {
      return AccessLevel.read;
    } else {
      return AccessLevel.none;
    }
  }

  @override
  List<int> merge(List<int> currentIndices) {
    if (currentIndices.contains(2)) {
      return [0, 1, 2];
    } else if (currentIndices.contains(1)) {
      return [0, 1];
    } else if (currentIndices.contains(0)) {
      return [0];
    } else {
      return [];
    }
  }
}
