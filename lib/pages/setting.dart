import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('setting'.tr),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: _Settings(),
      ),
    );
  }
}

class _Settings extends StatefulWidget {
  const _Settings();

  @override
  State<_Settings> createState() => __SettingsState();
}

class __SettingsState extends State<_Settings> {
  final settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text('app_setting'.tr),
        child(themeModeButton()),
        child(languageButton()),
        child(fontScaleButton()),
        child(checkAppUpdateOption()),
        const Divider(),
        Text('sync_setting'.tr),
        child(checkSelfRepoSyncOption()),
        child(checkSubscribeRepoSyncOption()),
        const Divider(),
        child(forceCheckUpdateButton()),
      ],
    );
  }

  Widget child(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: child,
    );
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
      // showSelectedIcon: false,
      selected: {settingController.themeMode.value},
      onSelectionChanged: (Set<ThemeMode> newSelection) {
        settingController.setThemeMode(newSelection.first);
        setState(() {});
      },
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('theme_mode'.tr), btn],
    );
  }

  Widget languageButton() {
    var btn = DropdownButton<Locale>(
      value: settingController.locale.value,
      onChanged: (Locale? newValue) {
        settingController.setLocale(newValue!);
        setState(() {});
      },
      items: const [
        DropdownMenuItem(
          value: Locale('en'),
          child: Text('English'),
        ),
        DropdownMenuItem(
          value: Locale('zh'),
          child: Text('中文'),
        ),
      ],
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('language'.tr), btn],
    );
  }

  Widget fontScaleButton() {
    var btn = Slider(
      value: settingController.fontScale.value,
      onChanged: (double value) {
        settingController.setFontScale(value);
        setState(() {});
      },
      min: 0.75,
      max: 1.25,
      divisions: 10,
      label: settingController.fontScale.value.toStringAsFixed(1),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('font_scale'.tr), btn],
    );
  }

  Widget checkAppUpdateOption() {
    var btn = Switch(
      value: settingController.autoCheckAppUpdate.value,
      onChanged: (bool value) {
        settingController.setAutoCheckUpdate(value);
        setState(() {});
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('auto_check_app_update'.tr), btn],
    );
  }

  // sync_setting

  Widget checkSelfRepoSyncOption() {
    var btn = Switch(
      value: settingController.autoSyncSelfRepo.value,
      onChanged: (bool value) {
        settingController.setAutoSyncSelfRepo(value);
        setState(() {});
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('auto_sync_self_repo'.tr), btn],
    );
  }

  Widget checkSubscribeRepoSyncOption() {
    var btn = Switch(
      value: settingController.autoSyncSubscribeRepo.value,
      onChanged: (bool value) {
        settingController.setAutoSyncSubscribeRepo(value);
        setState(() {});
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text('auto_sync_subscribe_repo'.tr), btn],
    );
  }

  // info?
  Widget forceCheckUpdateButton() {
    var btn = ElevatedButton.icon(
      onPressed: () {
        settingController.checkIfUpdate(manually: true);
      },
      label: Text('check_app_update'.tr),
      icon: const Icon(Icons.update_rounded),
    );
    return Center(child: btn);
  }
}
