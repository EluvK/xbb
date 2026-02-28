import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/user.dart';

/// Noted: this wrapper should not be used for too many tree/list items.
/// In that case, consider using `oncePermissionCheck` for a one-time check instead of wrapping each item.
class PermissionBox extends StatelessWidget {
  final FeaturePermission feature;
  final String ownerId;
  final String? rootOwnerId;
  final List<Permission> acls;
  final Widget child;

  const PermissionBox({
    super.key,
    required this.feature,
    required this.ownerId,
    this.rootOwnerId,
    required this.acls,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final userCtrl = Get.find<UserManagerController>();
    return Obx(() {
      final canShow = userCtrl.checkPermission(feature, ownerId, acls, resourceRootOwnerId: rootOwnerId);
      return canShow ? child : const SizedBox.shrink();
    });
  }
}

bool oncePermissionCheck(
  FeaturePermission feature,
  String ownerId,
  List<Permission> acls,
  String? resourceRootOwnerId,
) {
  final userCtrl = Get.find<UserManagerController>();
  return userCtrl.checkPermission(feature, ownerId, acls, resourceRootOwnerId: resourceRootOwnerId);
}
