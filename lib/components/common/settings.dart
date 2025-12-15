import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/utils.dart';

class CommonSettings extends StatefulWidget {
  const CommonSettings({super.key});

  @override
  State<CommonSettings> createState() => _CommonSettingsState();
}

class _CommonSettingsState extends State<CommonSettings> {
  final settingController = Get.find<NewSettingController>();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        child: ListView(
          children: [
            Text('app_setting'.tr),
            child(themeModeButton()),
            child(languageButton()),
            child(fontScaleButton()),
            const Divider(),
            child(versionInfo()),
          ],
        ),
      ),
    );
  }

  Widget child(Widget child) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), child: child);
  }

  Widget themeModeButton() {
    var btn = SegmentedButton(
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
      selected: <ThemeMode>{settingController.themeMode},
      onSelectionChanged: (Set<ThemeMode> newSelection) {
        settingController.updateAppSetting(themeMode: newSelection.first);
        setState(() {
          Get.changeThemeMode(newSelection.first);
        });
      },
    );
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('theme_mode'.tr), btn]);
  }

  Widget languageButton() {
    var btn = DropdownButton<Locale>(
      value: settingController.locale,
      onChanged: (Locale? newValue) {
        settingController.updateAppSetting(locale: newValue!);
        setState(() {
          Get.updateLocale(newValue);
        });
      },
      items: const [
        DropdownMenuItem(value: Locale('en'), child: Text('English')),
        DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
      ],
    );
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('language'.tr), btn]);
  }

  Widget fontScaleButton() {
    var btn = Slider(
      value: settingController.fontScale,
      onChanged: (double value) {
        settingController.updateAppSetting(fontScale: value);
        setState(() {
          Get.forceAppUpdate();
        });
      },
      min: 0.75,
      max: 1.25,
      divisions: 10,
      label: "${((settingController.fontScale - 1) * 100).toStringAsFixed(0)}%",
    );
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('font_scale'.tr), btn]);
  }

  // ---

  Widget versionInfo() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Text('version'.tr),
        Text(VERSION),
      ],
    );
  }
}
