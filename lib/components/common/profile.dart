import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';
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
          Card(
            margin: const EdgeInsets.all(12.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [_selfAvatar(), _switchUserButton()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selfAvatar() {
    // settingController.currentUserAvatarUrl.value,
    return _avatar(predefinedAvatar[0].url, size: 36.0);
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

  Widget _avatar(String url, {double size = 30.0}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(width: 2.0, color: Colors.lightGreen.shade700),
      ),
      child: CircleAvatar(
        backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
        radius: size,
        backgroundImage: NetworkImage(url),
      ),
    );
  }
}
