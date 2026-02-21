import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/controller/utils.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/utils.dart';

class CommonSettings extends StatefulWidget {
  const CommonSettings({super.key});

  @override
  State<CommonSettings> createState() => _CommonSettingsState();
}

class _CommonSettingsState extends State<CommonSettings> {
  final settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surface,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(color: colorScheme.surface),
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: ListView(
            children: [
              Text('app_setting'.tr),
              child(themeModeButton()),
              child(languageButton()),
              child(fontScaleButton()),
              const Divider(),
              Text('syncstore_setting'.tr),
              child(
                TextInputWidget(
                  title: SyncStoreInputMetaEnum.address,
                  initialValue: settingController.syncStoreUrl,
                  onChanged: (value) {
                    settingController.updateSyncStoreSetting(baseUrl: value);
                    setState(() {
                      reInitSyncStoreController();
                    });
                  },
                ),
              ),
              child(
                BoolSelectorInputWidget(
                  title: SyncStoreInputMetaEnum.enableTunnel,
                  initialValue: settingController.syncStoreHpkeEnabled,
                  onChanged: (value) {
                    print('value: $value');
                    settingController.updateSyncStoreSetting(enableHpke: value);
                    setState(() {
                      reInitSyncStoreController();
                    });
                  },
                ),
              ),
              const Divider(),
              Text('app_feature_management'.tr),
              child(
                BoolSelectorInputWidget(
                  title: AppFeatureMetaEnum.enableNotes,
                  initialValue: settingController.notesEnabled,
                  onChanged: (value) {
                    settingController.updateAppFeaturesManagement(enableNotes: value);
                    setState(() {});
                  },
                ),
              ),
              const Divider(),
              Text('app_version'.tr),
              child(versionInfo()),
            ],
          ),
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
    return UserDefinedInputWidget(title: AppSettingMetaEnum.themeMode, widget: btn);
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
    return UserDefinedInputWidget(title: AppSettingMetaEnum.language, widget: btn);
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
    return UserDefinedInputWidget(title: AppSettingMetaEnum.fontScale, widget: btn);
  }

  // ---

  Widget versionInfo() {
    final SettingController settingController = Get.find<SettingController>();
    return Center(
      child: ElevatedButton.icon(
        onPressed: settingController.appCanUpdate
            ? () {
                checkUpdate(true);
              }
            : null,
        icon: const Icon(Icons.update),
        label: const Text(VERSION),
      ),
    );
  }
}
