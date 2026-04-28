import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/utils.dart';

class UpdateSheet extends StatefulWidget {
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
  State<UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<UpdateSheet> {
  bool throughProxy = true;

  @override
  Widget build(BuildContext context) {
    final SettingController settingController = Get.find<SettingController>();
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.system_update, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('check_update'.tr, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          '当前版本: $DISPLAY_VERSION · 最新: ${widget.latestVersion}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close), tooltip: '关闭'),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.releaseNotes != null)
                        SimpleMarkdownRenderer(data: widget.releaseNotes!)
                      else
                        const Text('暂无更新内容详情'),
                      const SizedBox(height: 12),
                      Obx(() {
                        if (settingController.downloadProgress.value > 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
              ),

              const Divider(height: 16),

              SwitchListTile(
                value: throughProxy,
                title: Text('download_manually'.tr),
                subtitle: Text(
                  throughProxy ? '开启：将复制下载链接，可在浏览器中粘贴下载' : '关闭：将在应用内通过服务器自动下载安装',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onChanged: (v) => setState(() => throughProxy = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.hasNewVersion
                      ? () {
                          widget.onUpdate(false, throughProxy);
                          Get.back();
                        }
                      : null,
                  child: Text('do_update'.tr),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onUpdate(true, throughProxy);
                    Get.back();
                  },
                  child: Text('${'do_update'.tr} (nightly)'),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(onPressed: () => Get.back(), child: const Text('以后再说')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Show update as a bottom sheet (replaces the old wrapper)
void showUpdateDialog({
  required String latestVersion,
  String? releaseNotes,
  bool hasNewVersion = false,
  required void Function(bool, bool) onUpdate,
}) {
  Get.bottomSheet(
    UpdateSheet(
      latestVersion: latestVersion,
      releaseNotes: releaseNotes,
      hasNewVersion: hasNewVersion,
      onUpdate: onUpdate,
    ),
    isScrollControlled: true,
    backgroundColor: Get.theme.dialogBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
  );
}
