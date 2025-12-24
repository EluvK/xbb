import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart' show UpdateUserProfileRequest, UserProfile;
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/utils/predefined.dart';

class CommonProfile extends StatefulWidget {
  const CommonProfile({super.key});

  @override
  State<CommonProfile> createState() => _CommonProfileState();
}

class _CommonProfileState extends State<CommonProfile> {
  final settingController = Get.find<NewSettingController>();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: ListView(
        children: [
          const _SelfProfile(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Divider(color: Colors.grey.shade400),
          ),
          const FriendProfiles(),
        ],
      ),
    );
  }
}

class _SelfProfile extends StatefulWidget {
  const _SelfProfile();

  @override
  State<_SelfProfile> createState() => _SelfProfileState();
}

class _SelfProfileState extends State<_SelfProfile> {
  final userManagerController = Get.find<UserManagerController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _selfAvatar(context),
            Column(children: [_selfUserName(context), _switchUserButton()]),
          ],
        ),
      ),
    );
  }

  Widget _selfUserName(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(
          userManagerController.selfProfile.value?.name ?? 'unknown'.tr,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
      );
    });
  }

  Widget _selfAvatar(BuildContext context) {
    return Obx(() {
      Widget selfAvatar = buildUserAvatar(context, userManagerController.selfProfile.value?.avatarUrl, size: 36.0);
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return _EditProfileDialog(
                currentProfile: userManagerController.selfProfile.value!,
                onSave: (newProfile) {
                  setState(() {
                    userManagerController.updateSelfProfile(newProfile);
                  });
                },
              );
            },
          );
        },
        customBorder: const CircleBorder(),
        child: selfAvatar,
      );
    });
  }

  Widget _switchUserButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Get.toNamed('/login');
      },
      label: Text('change_user'.tr),
      icon: const Icon(Icons.login_rounded),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final UserProfile currentProfile;
  final Function(UpdateUserProfileRequest) onSave;
  const _EditProfileDialog({required this.currentProfile, required this.onSave});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  TextEditingController avatarUrlController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String? _selectAssetAvatarName;

  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentProfile.avatarUrl != null && widget.currentProfile.avatarUrl!.startsWith('assets://')) {
      _selectAssetAvatarName = widget.currentProfile.avatarUrl;
    } else if (widget.currentProfile.avatarUrl != null && widget.currentProfile.avatarUrl!.startsWith('http')) {
      _selectAssetAvatarName = null;
      avatarUrlController.text = widget.currentProfile.avatarUrl!;
    }
    nameController = TextEditingController(text: widget.currentProfile.name);
    passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('edit_profile'.tr, style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
              _avatarMatrix(),
              TextField(
                controller: avatarUrlController,
                decoration: InputDecoration(labelText: 'input_optional_avatar_url'.tr),
                minLines: 1,
                maxLines: 3,
                onChanged: (value) {
                  if (value.isNotEmpty && value.startsWith('http')) {
                    setState(() {
                      _selectAssetAvatarName = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 20.0),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'name'.tr),
              ),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'password'.tr,
                  suffixIcon: IconButton(
                    icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_passwordVisible,
              ),
              const SizedBox(height: 20.0),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarMatrix() {
    print('building avatar matrix');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double totalWidth = constraints.maxWidth;
          double cardWidth = 48.0;
          int maxCardCountPerRow = min((totalWidth / cardWidth).toInt(), 12);
          double spacing = (totalWidth - (maxCardCountPerRow * cardWidth)) / (maxCardCountPerRow + 1);
          return Wrap(
            spacing: spacing,
            runSpacing: 8.0,
            alignment: WrapAlignment.start,
            children: predefinedAvatar.map((avatar) {
              return InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  setState(() {
                    _selectAssetAvatarName = avatar.name;
                    avatarUrlController.clear();
                  });
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: buildUserAvatar(
                        context,
                        avatar.url,
                        size: 24.0,
                        selected: _selectAssetAvatarName == avatar.name,
                      ),
                    ),
                    // Text(avatar.name),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () {
        final newProfile = UpdateUserProfileRequest(
          name: nameController.text,
          password: passwordController.text.isNotEmpty ? passwordController.text : null,
          avatarUrl: _selectAssetAvatarName ?? (avatarUrlController.text.isNotEmpty ? avatarUrlController.text : null),
        );
        widget.onSave(newProfile);
        Navigator.pop(context);
      },
      child: Text('save'.tr),
    );
  }
}

class FriendProfiles extends StatefulWidget {
  const FriendProfiles({super.key});

  @override
  State<FriendProfiles> createState() => _FriendProfilesState();
}

class _FriendProfilesState extends State<FriendProfiles> {
  @override
  Widget build(BuildContext context) {
    final userManagerController = Get.find<UserManagerController>();
    return Column(
      children: [
        Text('friend_profiles'.tr),
        Row(
          children: [
            IconButton(
              onPressed: () async {
                print('refresh friend profiles');
                await userManagerController.fetchAndUpdateUserProfiles();
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'refresh'.tr,
            ),
          ],
        ),
        Obx(() {
          var list = Column(
            children: userManagerController.userProfiles
                .map(
                  (profile) => ListTile(
                    leading: buildUserAvatar(context, profile.avatarUrl, size: 20.0, selected: false),
                    // trailing: profile.userId == userManagerController.selfProfile.userId
                    //     ? const Icon(Icons.person_rounded, size: 20.0)
                    //     : null,
                    title: Text(profile.name),
                    subtitle: Text(profile.userId),
                  ),
                )
                .toList(),
          );
          return list;
        }),
      ],
    );
  }
}
