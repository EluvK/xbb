import 'package:xbb/constant.dart' show APP_API_URI;

class Avatar {
  final String name;
  final String url;

  const Avatar({required this.name, required this.url});
}

// const String R2LINK = 'https://pub-35fb8e0d745944819b75af2768f58058.r2.dev';

// ignore: constant_identifier_names
const String ASSETS_PREFIX = 'assets://';

const Avatar defaultAvatar = Avatar(
  name: '${ASSETS_PREFIX}psyduck',
  url: '$APP_API_URI/fs/private/common/avatar/psyduck.png',
);

const List<Avatar> predefinedAvatar = [
  Avatar(name: '${ASSETS_PREFIX}cat', url: '$APP_API_URI/fs/private/common/avatar/cat.png'),
  Avatar(name: '${ASSETS_PREFIX}crab', url: '$APP_API_URI/fs/private/common/avatar/crab.png'),
  Avatar(name: '${ASSETS_PREFIX}deer', url: '$APP_API_URI/fs/private/common/avatar/deer.png'),
  Avatar(name: '${ASSETS_PREFIX}fox', url: '$APP_API_URI/fs/private/common/avatar/fox.png'),
  Avatar(name: '${ASSETS_PREFIX}koala', url: '$APP_API_URI/fs/private/common/avatar/koala.png'),
  Avatar(name: '${ASSETS_PREFIX}psyduck', url: '$APP_API_URI/fs/private/common/avatar/psyduck.png'),
  Avatar(name: '${ASSETS_PREFIX}starfish', url: '$APP_API_URI/fs/private/common/avatar/starfish.png'),
];
