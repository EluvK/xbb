import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/common/avatar.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/user.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: SizedBox(width: 340, child: ProfileBody())),
    );
  }
}

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  TextEditingController avatarUrlController = TextEditingController();
  FocusNode avatarUrlFocus = FocusNode();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final UserManagerController userManagerController = Get.find<UserManagerController>();
  late final UserProfile currentProfile;

  String? _selectAssetAvatarName; // whether select from predefined avatars

  bool _passwordVisible = false;
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    currentProfile = userManagerController.selfProfile.value!;
    if (currentProfile.avatarUrl == null) {
      _selectAssetAvatarName = Avatar.defaultAvatar().name;
    } else {
      if (currentProfile.avatarUrl!.startsWith('assets://')) {
        _selectAssetAvatarName = currentProfile.avatarUrl;
      } else if (currentProfile.avatarUrl!.startsWith('http')) {
        _selectAssetAvatarName = null;
        avatarUrlController.text = currentProfile.avatarUrl!;
      }
    }

    nameController = TextEditingController(text: currentProfile.name);
    passwordController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('edit_profile'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _avatarEditor(),
        const SizedBox(height: 10),
        const Divider(),
        const SizedBox(height: 10),
        TextField(
          controller: nameController,
          decoration: InputDecoration(border: const OutlineInputBorder(), labelText: 'change_nick_name'.tr),
          onChanged: (value) {
            setState(() {
              _isChanged = true;
            });
          },
        ),
        const SizedBox(height: 20),
        TextField(
          controller: passwordController,
          onChanged: (value) {
            setState(() {
              _isChanged = true;
            });
          },
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: 'change_password'.tr,
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
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              onPressed: _isChanged
                  ? () {
                      final newProfile = UpdateUserProfileRequest(
                        name: nameController.text,
                        password: passwordController.text.isNotEmpty ? passwordController.text : null,
                        avatarUrl:
                            _selectAssetAvatarName ??
                            (avatarUrlController.text.isNotEmpty ? avatarUrlController.text : null),
                      );
                      userManagerController.updateSelfProfile(newProfile);
                      Navigator.pop(context);
                    }
                  : null,
              child: Text('save'.tr),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatarEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: _selectAssetAvatarName != null && !avatarUrlFocus.hasFocus ? 1.0 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select Avatar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    _selectAssetAvatarName != null ? _selectAssetAvatarName!.substring(ASSETS_PREFIX.length) : '',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              _avatarMatrix(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Opacity(
          opacity: _selectAssetAvatarName == null || avatarUrlFocus.hasFocus ? 1.0 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Or enter a web URL:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextField(
                controller: avatarUrlController,
                focusNode: avatarUrlFocus,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: 'input_optional_avatar_url'.tr,
                ),
                minLines: 1,
                maxLines: 3,
                onChanged: (value) {
                  if (value.isNotEmpty && value.startsWith('http')) {
                    setState(() {
                      _selectAssetAvatarName = null;
                      _isChanged = true;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarMatrix() {
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
            children: predefinedAvatarList().map((avatar) {
              return InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  setState(() {
                    _selectAssetAvatarName = avatar.name;
                    avatarUrlController.clear();
                    _isChanged = true;
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
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
