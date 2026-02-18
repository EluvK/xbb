import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/common/avatar.dart';
import 'package:xbb/controller/syncstore.dart';

Widget buildUserAvatar(BuildContext context, String? avatarUrl, {double size = 30.0, selected = true}) {
  // final colorScheme = Theme.of(context).colorScheme;
  String url = avatarUrl ?? Avatar.defaultAvatar().url;
  final border = selected
      ? Border.all(width: 3.0, color: Colors.lightGreen.shade700)
      : Border.all(width: 3.0, color: Colors.transparent);
  if (url.startsWith(ASSETS_PREFIX)) {
    url = predefinedAvatarList().firstWhere((avatar) => avatar.name == url, orElse: () => Avatar.defaultAvatar()).url;
  }
  SyncStoreControl ssClient = Get.find<SyncStoreControl>();
  return Container(
    decoration: BoxDecoration(shape: BoxShape.circle, border: border),
    child: CachedNetworkImage(
      imageUrl: url,
      cacheManager: AppCacheManager.instance(ssClient.syncStoreClient),
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      fit: BoxFit.cover,
      width: size * 2,
      height: size * 2,
    ),
  );
}
