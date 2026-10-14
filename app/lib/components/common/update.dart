import 'package:flutter/material.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';

class UpdateSheet extends StatelessWidget {
  final String latestVersion;
  final String? releaseNotes;
  final bool hasNewVersion;
  final void Function(bool, bool) onUpdate;

  const UpdateSheet({
    super.key,
    required this.latestVersion,
    this.releaseNotes,
    required this.hasNewVersion,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveModalContainer(
      title: '版本检查',
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('好的'),
        ),
      ],
      child: Text(hasNewVersion ? '发现新版本: $latestVersion' : '当前已是最新版本'),
    );
  }
}

void showUpdateDialog({
  required String latestVersion,
  String? releaseNotes,
  required bool hasNewVersion,
  required void Function(bool, bool) onUpdate,
}) {}
