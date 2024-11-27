import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      ],
    );
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
              launchRepo();
            },
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
    );
  }
}
