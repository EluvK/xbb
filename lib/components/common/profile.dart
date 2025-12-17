import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      child: Column(
        children: [
          Text('profile_page'.tr),
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

class _SelfProfile extends StatelessWidget {
  const _SelfProfile();

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
    // settingController.currentUserAvatarUrl.value,
    return _avatar(context, predefinedAvatarNames[0], size: 36.0);
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
                await userManagerController.fetchAndUpdateUserProfiles();
                setState(() {});
              },
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'refresh'.tr,
            ),
          ],
        ),
        Obx(() {
          var column = Column(
            children: userManagerController.userProfiles
                .map(
                  (profile) => ListTile(
                    leading: _avatar(context, profile.avatarUrl ?? predefinedAvatarNames[3], size: 20.0),
                    title: Text(profile.name),
                    subtitle: Text(profile.userId),
                  ),
                )
                .toList(),
          );
          return column;
        }),
      ],
    );
  }
}
