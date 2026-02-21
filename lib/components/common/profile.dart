import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/user.dart';

class CommonProfile extends StatefulWidget {
  const CommonProfile({super.key});

  @override
  State<CommonProfile> createState() => _CommonProfileState();
}

class _CommonProfileState extends State<CommonProfile> {
  final settingController = Get.find<SettingController>();

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
          userManagerController.selfProfile.value?.name ?? 'unknown_user'.tr,
          style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
        ),
      );
    });
  }

  Widget _selfAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Obx(() {
      Widget selfAvatar = buildUserAvatar(context, userManagerController.selfProfile.value?.avatarUrl, size: 36.0);
      return InkWell(
        onTap: () {
          Get.toNamed('/profile');
        },
        customBorder: const CircleBorder(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            selfAvatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primaryContainer, width: 2),
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.edit_rounded, size: 14, color: colorScheme.onPrimary),
              ),
            ),
          ],
        ),
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
