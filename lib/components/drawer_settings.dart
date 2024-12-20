import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/utils.dart';

class DrawerSettingArea extends StatefulWidget {
  const DrawerSettingArea({super.key});

  @override
  State<DrawerSettingArea> createState() => _DrawerSettingAreaState();
}

class _DrawerSettingAreaState extends State<DrawerSettingArea> {
  final settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var downloadProgress = settingController.downloadProgress.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: settingButton(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: versionWithUpdate(),
              ),
            ],
          ),
          Visibility(
            visible: downloadProgress > 0,
            child: LinearPercentIndicator(
              percent: downloadProgress,
              backgroundColor: Colors.grey.shade300,
              progressColor: Colors.blue,
            ),
          ),
        ],
      );
    });
  }

  Widget settingButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Get.toNamed('/setting');
      },
      label: Text('setting'.tr),
      icon: const Icon(Icons.settings_rounded),
    );
  }

  Widget versionWithUpdate() {
    bool canUpdate = settingController.canUpdate.value;
    return ElevatedButton.icon(
      onPressed: canUpdate
          ? () async {
              checkUpdate();
            }
          : null,
      label: const Text(VERSION),
      icon: Icon(canUpdate ? Icons.update_rounded : Icons.info_rounded),
    );
  }

  checkUpdate() {
    getLatestVersion().then((value) {
      value.fold((version) {
        if (!shouldUpdate(version)) {
          flushBar(FlushLevel.INFO, "已经是最新版本啦", "当前版本: $VERSION");
          return;
        }
        if (GetPlatform.isWindows) {
          String url =
              "https://pub-35fb8e0d745944819b75af2768f58058.r2.dev/release/$version/xbb_desktop_windows_setup.exe";
          print(url);
          openUrl(url);
        } else if (GetPlatform.isAndroid) {
          String url =
              "https://pub-35fb8e0d745944819b75af2768f58058.r2.dev/release/$version/xbb.apk";
          print(url);
          settingController.downloadApk(url);
        }
      }, (error) {
        print('error: $error');
      });
    });
  }
}
