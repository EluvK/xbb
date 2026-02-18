import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

class Avatar {
  final String name;
  final String url;

  const Avatar({required this.name, required this.url});

  factory Avatar.defaultAvatar() {
    final NewSettingController settingController = Get.find<NewSettingController>();
    final url = settingController.syncStoreUrl;
    return Avatar(name: '${ASSETS_PREFIX}psyduck', url: '$url/fs/private/common/avatar/psyduck.png');
  }
}

const String ASSETS_PREFIX = 'assets://';

Iterable<Avatar> predefinedAvatarList() {
  final NewSettingController settingController = Get.find<NewSettingController>();
  final url = settingController.syncStoreUrl;
  return predefinedAvatarNamePathMap.entries.map((entry) {
    return Avatar(name: entry.key, url: '$url${entry.value}');
  });
}

const Map<String, String> predefinedAvatarNamePathMap = {
  'assets://cat': '/fs/private/common/avatar/cat.png',
  'assets://crab': '/fs/private/common/avatar/crab.png',
  'assets://deer': '/fs/private/common/avatar/deer.png',
  'assets://fox': '/fs/private/common/avatar/fox.png',
  'assets://koala': '/fs/private/common/avatar/koala.png',
  'assets://psyduck': '/fs/private/common/avatar/psyduck.png',
  'assets://starfish': '/fs/private/common/avatar/starfish.png',
};
