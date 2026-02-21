import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/acl_editor.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/view_widget.dart';

class RepoEditor extends StatefulWidget {
  const RepoEditor({super.key, required this.repoItem});
  final RepoDataItem repoItem;

  @override
  State<RepoEditor> createState() => _RepoEditorState();
}

class _RepoEditorState extends State<RepoEditor> {
  late Repo _editedRepo;
  late final bool isSelfRepo;
  late final bool canEditRepoInfo;
  final RepoController repoController = Get.find<RepoController>();
  final UserManagerController userManagerController = Get.find<UserManagerController>();
  Future<List<Permission>>? _initialPermissionsFuture;

  @override
  void initState() {
    _editedRepo = widget.repoItem.body.copyWith();
    isSelfRepo = userManagerController.selfProfile.value?.userId == widget.repoItem.owner;
    _initialPermissionsFuture = repoController.getAclRefresh(widget.repoItem.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
        child: FutureBuilder(
          future: _initialPermissionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Error loading ACLs: ${snapshot.error}');
            } else {
              final initialPermissions = snapshot.data as List<Permission>;
              return ListView(
                children: [_editRepo(initialPermissions), const Divider(), _editRepoAcl(initialPermissions)],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _editRepo(List<Permission> initialPermissions) {
    bool canEditRepoInfo =
        isSelfRepo ||
        initialPermissions.any(
          (perm) =>
              perm.accessLevel == AccessLevel.write ||
              perm.accessLevel == AccessLevel.update ||
              perm.accessLevel == AccessLevel.fullAccess,
        );
    if (canEditRepoInfo) {
      return Column(
        children: [
          Text('update_repo_info'.tr, style: Theme.of(context).textTheme.titleMedium),
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
    } else {
      return Column(
        children: [
          Text('repo_info'.tr, style: Theme.of(context).textTheme.titleMedium),
          TextViewWidget(title: InputTitleEnum.title, value: _editedRepo.name),
          TextViewWidget(title: InputTitleEnum.description, value: _editedRepo.description ?? ''),
        ],
      );
    }
  }

  Widget _editRepoAcl(List<Permission> initialPermissions) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isSelfRepo
            ? Text('update_repo_acl'.tr, style: Theme.of(context).textTheme.titleMedium)
            : Text('repo_acl'.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        isSelfRepo
            ? AclEditor(
                schema: RepoPermissionSchema(),
                initialPermissions: initialPermissions,
                onSavePermissions: (newPermissions) async {
                  await repoController.setAcls(widget.repoItem.id, newPermissions);
                  setState(() {
                    _initialPermissionsFuture = Future.value(newPermissions);
                  });
                },
              )
            : AclViewer(schema: RepoPermissionSchema(), permissions: initialPermissions),
      ],
    );
  }
}

class RepoPermissionSchema implements PermissionSchema {
  @override
  List<(String, String)> get labels => [
    ('perm_spy'.tr, 'readOnly'),
    ('perm_subscribe'.tr, 'read/comment'),
    ('perm_share'.tr, 'read/write/update'),
    ('perm_full_access'.tr, 'All Permissions'),
  ];

  @override
  List<bool> decode(AccessLevel accessLevel) {
    switch (accessLevel) {
      case AccessLevel.none:
        return [false, false, false, false];
      case AccessLevel.read:
        return [true, false, false, false];
      case AccessLevel.read_append2:
        return [true, true, false, false];
      case AccessLevel.write:
        return [true, true, true, false];
      case AccessLevel.fullAccess:
        return [true, true, true, true];
      // unimplemented;
      case AccessLevel.read_append1:
      case AccessLevel.read_append3:
      case AccessLevel.update:
        return [false, false, false];
    }
  }

  @override
  AccessLevel encode(List<bool> accessList) {
    if (accessList[3]) {
      return AccessLevel.fullAccess;
    } else if (accessList[2]) {
      return AccessLevel.write;
    } else if (accessList[1]) {
      return AccessLevel.read_append2;
    } else if (accessList[0]) {
      return AccessLevel.read;
    } else {
      return AccessLevel.none;
    }
  }

  @override
  List<int> disableOverlappingSelections(AccessLevel accessLevel) {
    switch (accessLevel) {
      case AccessLevel.read_append2:
        return [0];
      case AccessLevel.write:
        return [0, 1];
      case AccessLevel.fullAccess:
        return [0, 1, 2];
      case AccessLevel.none:
      case AccessLevel.read_append1:
      case AccessLevel.read_append3:
      case AccessLevel.update:
      case AccessLevel.read:
        return [];
    }
  }
}
