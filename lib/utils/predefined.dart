class Avatar {
  final String name;
  final String url;

  Avatar({required this.name, required this.url});
}

const String defaultAvatarLink = '$R2LINK/avatar/psyduck.png';

// ignore: constant_identifier_names
const String R2LINK = 'https://pub-35fb8e0d745944819b75af2768f58058.r2.dev';

final List<Avatar> predefinedAvatar = [
  Avatar(name: 'cat', url: '$R2LINK/avatar/cat.png'),
  Avatar(name: 'crab', url: '$R2LINK/avatar/crab.png'),
  Avatar(name: 'deer', url: '$R2LINK/avatar/deer.png'),
  Avatar(name: 'fox', url: '$R2LINK/avatar/fox.png'),
  Avatar(name: 'koala', url: '$R2LINK/avatar/koala.png'),
  Avatar(name: 'psyduck', url: '$R2LINK/avatar/psyduck.png'),
  Avatar(name: 'starfish', url: '$R2LINK/avatar/starfish.png'),
];
