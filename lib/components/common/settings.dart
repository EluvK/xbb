import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/common/ping_latency_inline.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/controller/task_widget.dart';
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
  bool _isPinging = false;
  int? _pingLatencyMs;
  bool _isPinningWidget = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultSyncStoreUrl = SyncStoreSetting.defaults().baseUrl;
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
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('syncstore_setting'.tr),
                  PingLatencyInline(
                    isLoading: _isPinging,
                    latencyMs: _pingLatencyMs,
                    onRefresh: _isPinging ? null : testPingLatency,
                  ),
                ],
              ),
              child(
                TextInputWidget(
                  title: SyncStoreInputMetaEnum.address,
                  initialValue: settingController.syncStoreUrl,
                  tailButton: OutlinedButton.icon(
                    onPressed: settingController.syncStoreUrl == defaultSyncStoreUrl
                        ? null
                        : () async {
                            settingController.updateSyncStoreSetting(baseUrl: defaultSyncStoreUrl);
                            await reInitSyncStoreController();
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _pingLatencyMs = null;
                            });
                          },
                    icon: Tooltip(message: 'reset_default'.tr, child: const Icon(Icons.restore)),
                    label: const SizedBox.shrink(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(40, 36),
                    ),
                  ),
                  onFinished: (value) async {
                    settingController.updateSyncStoreSetting(baseUrl: value);
                    await reInitSyncStoreController();
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _pingLatencyMs = null;
                    });
                  },
                ),
              ),
              child(
                BoolSelectorInputWidget(
                  title: SyncStoreInputMetaEnum.enableTunnel,
                  initialValue: settingController.syncStoreHpkeEnabled,
                  onChanged: (value) async {
                    print('value: $value');
                    settingController.updateSyncStoreSetting(enableHpke: value);
                    await reInitSyncStoreController();
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _pingLatencyMs = null;
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
              child(
                BoolSelectorInputWidget(
                  title: AppFeatureMetaEnum.enableTracker,
                  initialValue: settingController.trackerEnabled,
                  onChanged: (value) {
                    settingController.updateAppFeaturesManagement(enableTracker: value);
                    setState(() {});
                  },
                ),
              ),
              child(
                BoolSelectorInputWidget(
                  title: AppFeatureMetaEnum.enableTask,
                  initialValue: settingController.taskEnabled,
                  onChanged: (value) {
                    settingController.updateAppFeaturesManagement(enableTask: value);
                    setState(() {});
                  },
                ),
              ),
              if (!kIsWeb && Platform.isAndroid)
                child(
                  UserDefinedInputWidget(
                    title: AppFeatureMetaEnum.taskWidget,
                    widget: ElevatedButton.icon(
                      onPressed: _isPinningWidget ? null : _onAddTaskWidget,
                      icon: _isPinningWidget
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_to_home_screen_rounded),
                      label: Text('add_task_widget_to_home'.tr),
                    ),
                  ),
                ),
              const Divider(),
              Text('app_version'.trParams({'version': DISPLAY_VERSION})),
              child(versionInfo(context)),
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

  Future<void> _onAddTaskWidget() async {
    setState(() => _isPinningWidget = true);
    try {
      await TaskWidgetBridge.requestPinWidget();
    } catch (_) {
      // best-effort: ignore errors from the system API
    } finally {
      if (mounted) setState(() => _isPinningWidget = false);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('add_task_widget_title'.tr),
        content: Text('add_task_widget_guide_message'.tr),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('confirm'.tr))],
      ),
    );
  }

  Future<void> testPingLatency() async {
    if (_isPinging) {
      return;
    }
    setState(() {
      _isPinging = true;
    });
    final latency = await Get.find<SyncStoreControl>().pingLatencyMs();
    if (!mounted) {
      return;
    }
    setState(() {
      _pingLatencyMs = latency >= 0 ? latency : null;
      _isPinging = false;
    });
  }

  // ---

  Widget versionInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Obx(() {
        final bool isChecking = settingController.isCheckingUpdate;
        final bool hasUpdate = settingController.appCanUpdate;
        final Widget icon = isChecking
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(colorScheme.onPrimary),
                ),
              )
            : const Icon(Icons.update);
        final Widget label = isChecking
            ? Text('check_update'.tr)
            : (hasUpdate ? Text('do_update'.tr) : Text('check_update'.tr));
        return ElevatedButton.icon(
          onPressed: isChecking ? null : () => checkUpdate(forceCheck: true),
          icon: icon,
          label: label,
        );
      }),
    );
  }
}
