import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
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
    if (canUpdate) {
      return ElevatedButton.icon(
        onPressed: () async {
          settingController.checkIfUpdate(
            manually: true,
            doUpdateIfCan: true,
          );
        },
        label: Text("do_app_update".tr),
        icon: const Icon(Icons.update_rounded),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: null,
        label: const Text(VERSION),
        icon: const Icon(Icons.info_rounded),
      );
    }
  }
}
