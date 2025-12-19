import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart' show UpdateUserProfileRequest;
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
  TextEditingController avatarUrlController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    var profile = userManagerController.getSelfProfile();
    if (profile.avatarUrl != null) {
      avatarUrlController.text = profile.avatarUrl!;
    }
    nameController.text = profile.name;
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
          children: [_selfAvatar(context), _switchUserButton()],
        ),
      ),
    );
  }

  Widget _selfAvatar(BuildContext context) {
    var profile = userManagerController.getSelfProfile();
    Widget avatar;
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      avatar = _avatar(context, profile.avatarUrl!, size: 36.0);
    } else {
      avatar = _avatar(context, predefinedAvatarNames[0], size: 36.0);
    }
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, StateSetter setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                  elevation: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _showEditUserInfoDialog(setState),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }

  bool _passwordVisible = false;
  Widget _showEditUserInfoDialog(StateSetter setState) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Text('edit_profile'.tr, style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12.0),
          _avatarMatrix(),
          TextField(
            controller: avatarUrlController,
            decoration: InputDecoration(labelText: 'avatar_url'.tr),
            minLines: 1,
            maxLines: 3,
          ),
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
          ElevatedButton(
            onPressed: () {
              final newProfile = UpdateUserProfileRequest(
                name: nameController.text,
                password: passwordController.text.isNotEmpty ? passwordController.text : null,
                avatarUrl: avatarUrlController.text.isNotEmpty ? avatarUrlController.text : null,
              );
              userManagerController.updateSelfProfile(newProfile);
              setState(() {});
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
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
            children: predefinedAvatar.map((avatar) {
              return InkWell(
                onTap: () {
                  setState(() {
                    avatarUrlController.text = avatar.url;
                  });
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: _avatar(context, avatar.url, size: 24.0),
                    ),
                    Text(avatar.name),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
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

// maybe move to utils/image.dart
Widget _avatar(BuildContext context, String url, {double size = 30.0}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(width: 2.0, color: Colors.lightGreen.shade700),
    ),
    child: CircleAvatar(
      backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
      radius: size,
      backgroundImage: _image(url).image,
    ),
  );
}

Image _image(String url) {
  if (url.startsWith('assets://')) {
    return Image.asset('assets/avatar/${url.substring(9)}.png');
  } else {
    return Image.network(url);
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
                    leading: _avatar(context, profile.avatarUrl ?? predefinedAvatarNames[3], size: 20.0),
                    trailing: profile.userId == userManagerController.getSelfProfile().userId
                        ? const Icon(Icons.person_rounded, size: 20.0)
                        : null,
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
