import 'package:flutter/material.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/permission.dart' show FeaturePermission;

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
    return child;
  }
}

bool oncePermissionCheck(
  FeaturePermission feature,
  String ownerId,
  List<Permission> acls,
  String? resourceRootOwnerId,
) {
  return true;
}
