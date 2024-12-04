import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/utils.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var downloadProgress = settingController.downloadProgress.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: themeModeButton(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: version(),
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

  Widget themeModeButton() {
    return SegmentedButton(
      segments: [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          tooltip: 'mode_light'.tr,
          icon: const Icon(Icons.light_mode_sharp),
        ),
        ButtonSegment<ThemeMode>(
          tooltip: 'mode_system'.tr,
          value: ThemeMode.system,
          icon: const Icon(Icons.settings_applications_sharp),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          tooltip: 'mode_dark'.tr,
          icon: const Icon(Icons.dark_mode_sharp),
        ),
      ],
      showSelectedIcon: false,
      selected: {settingController.themeMode.value},
      onSelectionChanged: (Set<ThemeMode> newSelection) {
        settingController.setThemeMode(newSelection.first);
        setState(() {});
      },
    );
  }

  Widget version() {
    return Transform.scale(
      scale: 0.9,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: null,
            label: const Text('XBB $VERSION'),
            icon: const Icon(Icons.info_rounded),
          ),
          ElevatedButton.icon(
            label: Text('check_update'.tr),
            onPressed: () async {
              checkUpdate();
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
    );
  }

  checkUpdate() {
    getLastestVersion().then((value) {
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

  bool shouldUpdate(String latestVersion) {
    if (VERSION == 'debug') {
      return true;
    }
    for (int i = 0; i < latestVersion.split('.').length; i++) {
      if (int.parse(latestVersion.split('.')[i]) >
          int.parse(VERSION.split('.')[i])) {
        return true;
      }
    }
    return false;
  }
}
