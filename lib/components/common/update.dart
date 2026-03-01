import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/utils.dart';

class UpdateDialog extends StatefulWidget {
  final String latestVersion;
  final String? releaseNotes;
  final bool hasNewVersion;
  final void Function(bool, bool) onUpdate;

  const UpdateDialog({
    super.key,
    required this.latestVersion,
    this.releaseNotes,
    required this.hasNewVersion,
    required this.onUpdate,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool throughProxy = true;

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    print('debug: hasNewVersion: ${widget.hasNewVersion}');
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue),
          Text('check_update'.tr),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前版本: $VERSION'),
            const SizedBox(height: 16),
            Text('最新版本: ${widget.latestVersion}'),
            const Text('更新内容:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (widget.releaseNotes != null)
              SimpleMarkdownRenderer(data: widget.releaseNotes!)
            else
              const Text('暂无更新内容详情'),
            const SizedBox(height: 16),
            Obx(() {
              if (settingController.downloadProgress.value > 0) {
                return Column(
                  children: [
                    LinearProgressIndicator(value: settingController.downloadProgress.value),
                    const SizedBox(height: 8),
                    Text(
                      '下载进度: ${(settingController.downloadProgress.value * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('以后再说')),
        TextButton(
          onPressed: () {
            setState(() {
              throughProxy = !throughProxy;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IgnorePointer(
                child: Checkbox(value: throughProxy, onChanged: (value) {}),
              ),
              Text('download_manually'.tr),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              onPressed: widget.hasNewVersion ? () => widget.onUpdate(false, throughProxy) : null,
              child: Text('do_update'.tr),
            ),
            ElevatedButton(
              onPressed: () => widget.onUpdate(true, throughProxy),
              child: Text('${'do_update'.tr} (nightly)'),
            ),
          ],
        ),
      ],
    );
  }
}

void showUpdateDialog({
  required String latestVersion,
  String? releaseNotes,
  bool hasNewVersion = false,
  required void Function(bool, bool) onUpdate,
}) {
  Get.dialog(
    UpdateDialog(
      latestVersion: latestVersion,
      releaseNotes: releaseNotes,
      hasNewVersion: hasNewVersion,
      onUpdate: onUpdate,
    ),
    barrierDismissible: false,
  );
}
