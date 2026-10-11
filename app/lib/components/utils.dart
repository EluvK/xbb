import 'package:flutter/material.dart';
import 'package:xbb/components/common/avatar.dart';

Widget buildUserAvatar(BuildContext context, String? avatarUrl, {double size = 30.0, bool selected = true}) {
  return Container(
    width: size * 2,
    height: size * 2,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Theme.of(context).colorScheme.primaryContainer,
    ),
    child: Icon(Icons.person, size: size, color: Theme.of(context).colorScheme.primary),
  );
}
