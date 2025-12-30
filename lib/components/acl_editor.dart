import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/user.dart';

abstract class PermissionSchema {
  List<String> get labels;
  // from access level to this labels' bool list
  List<bool> decode(AccessLevel accessLevel);
  // from this labels' bool list to access level
  AccessLevel encode(List<bool> selections);

  // disable overlapping selections
  List<int> disableOverlappingSelections(AccessLevel accessLevel);
}

class AclEditor extends StatefulWidget {
  final PermissionSchema schema;
  final List<Permission> initialPermissions;

  final Future<void> Function(List<Permission>) onSavePermissions;

  const AclEditor({super.key, required this.schema, required this.initialPermissions, required this.onSavePermissions});

  @override
  State<AclEditor> createState() => _AclEditorState();
}

class _AclEditorState extends State<AclEditor> {
  final UserManagerController userManagerController = Get.find<UserManagerController>();

  late List<Permission> _authList;
  late List<UserProfile> _otherList;

  @override
  void initState() {
    _authList = widget.initialPermissions.where((p) {
      return userManagerController.friends.contains(p.user);
    }).toList();
    _otherList = userManagerController.userProfiles
        .where((profile) => !_authList.any((p) => p.user == profile.userId))
        .toList();
    super.initState();
  }

  void _onToggle(int userIndex, int labelIndex) {
    setState(() {
      final currentPermission = _authList[userIndex];
      final currentSelections = widget.schema.decode(currentPermission.accessLevel);
      currentSelections[labelIndex] = !currentSelections[labelIndex];
      final newAccessLevel = widget.schema.encode(currentSelections);
      _authList[userIndex] = Permission(user: currentPermission.user, accessLevel: newAccessLevel);
      if (newAccessLevel == AccessLevel.none) {
        _otherList.add(userManagerController.getUserProfile(currentPermission.user)!);
        _authList.removeAt(userIndex);
      }
    });
  }

  bool _isModified() {
    if (_authList.length != widget.initialPermissions.length) {
      return true;
    }
    for (int i = 0; i < _authList.length; i++) {
      if (_authList[i].user != widget.initialPermissions[i].user ||
          _authList[i].accessLevel != widget.initialPermissions[i].accessLevel) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        const Divider(),
        if (_authList.isEmpty)
          Padding(padding: const EdgeInsets.all(16.0), child: Text('No members with permissions yet.'.tr)),
        if (_authList.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _authList.length,
            itemBuilder: (context, index) => _buildUserRow(index),
          ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Divider()),
        if (_otherList.isNotEmpty) _buildPendingArea(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isModified()
                ? () async {
                    await widget.onSavePermissions(_authList);
                  }
                : null,
            child: const Text('保存权限变更'),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          flex: 2,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: Text('成员')),
          ),
        ),
        ...widget.schema.labels.map((l) => Expanded(child: Center(child: Text(l)))),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildUserRow(int index) {
    final user = _authList[index];
    final userProfile = userManagerController.getUserProfile(user.user);
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              buildUserAvatar(context, userProfile?.avatarUrl, size: 16, selected: true),
              const SizedBox(height: 4),
              Text(userProfile?.name ?? 'Unknown User', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        ...List.generate(
          widget.schema.labels.length,
          (pIndex) => Expanded(
            child: Checkbox(
              value: widget.schema.decode(user.accessLevel)[pIndex],
              onChanged: widget.schema.disableOverlappingSelections(user.accessLevel).contains(pIndex)
                  ? null
                  : (_) => _onToggle(index, pIndex),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
          onPressed: () => setState(() {
            _otherList.add(userManagerController.getUserProfile(user.user)!);
            _authList.removeAt(index);
          }),
        ),
      ],
    );
  }

  Widget _buildPendingArea() {
    return Column(
      children: [
        Text('Add Members'.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8,
          children: _otherList.map((u) {
            final userProfile = userManagerController.getUserProfile(u.userId);
            return ActionChip(
              label: Column(
                children: [
                  buildUserAvatar(context, userProfile?.avatarUrl, size: 16, selected: false),
                  const SizedBox(width: 4),
                  Text(userProfile?.name ?? 'Unknown User', style: const TextStyle(fontSize: 12)),
                ],
              ),
              onPressed: () {
                setState(() {
                  _authList.add(Permission(user: u.userId, accessLevel: AccessLevel.none));
                  _otherList.removeWhere((profile) => profile.userId == u.userId);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
