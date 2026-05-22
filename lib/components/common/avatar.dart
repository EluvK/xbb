import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

class Avatar {
  final String name;
  final String url;

  const Avatar({required this.name, required this.url});

  factory Avatar.defaultAvatar() {
    final baseUrl = _syncStoreBaseUrl();
    return Avatar(name: '${assetsPrefix}psyduck', url: '$baseUrl/fs/private/common/avatar/psyduck.png');
  }
}

const String assetsPrefix = 'assets://';
// Backward-compatible alias for existing imports/usages.
const String ASSETS_PREFIX = assetsPrefix;

Iterable<Avatar> predefinedAvatarList() {
  final baseUrl = _syncStoreBaseUrl();
  return predefinedAvatarNamePathMap.entries.map((entry) {
    return Avatar(name: entry.key, url: '$baseUrl${entry.value}');
  });
}

String _syncStoreBaseUrl() => Get.find<SettingController>().syncStoreUrl;

const Map<String, String> predefinedAvatarNamePathMap = {
  'assets://cat': '/fs/private/common/avatar/cat.png',
  'assets://crab': '/fs/private/common/avatar/crab.png',
  'assets://deer': '/fs/private/common/avatar/deer.png',
  'assets://fox': '/fs/private/common/avatar/fox.png',
  'assets://koala': '/fs/private/common/avatar/koala.png',
  'assets://psyduck': '/fs/private/common/avatar/psyduck.png',
  'assets://starfish': '/fs/private/common/avatar/starfish.png',
};
