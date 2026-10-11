class Avatar {
  final String name;
  final String url;

  const Avatar({required this.name, required this.url});

  factory Avatar.defaultAvatar() {
    return const Avatar(name: 'default', url: '');
  }
}

const String assetsPrefix = 'assets://';
const String ASSETS_PREFIX = assetsPrefix;

Iterable<Avatar> predefinedAvatarList() {
  return const [Avatar(name: 'default', url: '')];
}
