import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/common/ping_latency_inline.dart';
import 'package:xbb/controller/clipboard_tray.dart';
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
  final clipboardTrayController = Get.find<ClipboardTrayController>();
  bool _isPinging = false;
  int? _pingLatencyMs;
  bool _isPinningWidget = false;

  List<int> _startupTabCandidates() {
    final candidates = <int>[];
    if (settingController.taskEnabled) candidates.add(AppHomeStartupTabIndex.task);
    if (settingController.clipboardBackupEnabled) candidates.add(AppHomeStartupTabIndex.clipboard);
    if (settingController.notesEnabled) candidates.add(AppHomeStartupTabIndex.notes);
    if (settingController.trackerEnabled) candidates.add(AppHomeStartupTabIndex.tracker);
    if (settingController.chatEnabled) candidates.add(AppHomeStartupTabIndex.chat);
    candidates.add(AppHomeStartupTabIndex.settings);
    return candidates;
  }

  int _effectiveStartupTabIndex() {
    final candidates = _startupTabCandidates();
    final selected = settingController.homeStartupTabIndex;
    if (candidates.contains(selected)) {
      return selected;
    }
    return candidates.first;
  }

  void _ensureStartupTabIndexValid() {
    final effective = _effectiveStartupTabIndex();
    if (effective == settingController.homeStartupTabIndex) {
      return;
    }
    settingController.updateAppFeaturesManagement(homeStartupTabIndex: effective);
  }

  String _startupTabTitle(int tabIndex) {
    switch (tabIndex) {
      case AppHomeStartupTabIndex.notes:
        return 'home_bar_title_note'.tr;
      case AppHomeStartupTabIndex.tracker:
        return 'home_bar_title_tracker'.tr;
      case AppHomeStartupTabIndex.task:
        return 'home_bar_title_task'.tr;
      case AppHomeStartupTabIndex.clipboard:
        return 'home_bar_title_clipboard'.tr;
      case AppHomeStartupTabIndex.chat:
        return 'home_bar_title_chat'.tr;
      case AppHomeStartupTabIndex.settings:
      default:
        return 'home_bar_title_setting'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final defaultSyncStoreUrl = SyncStoreSetting.defaults().baseUrl;
    final showClipboardTraySettings = !kIsWeb && Platform.isWindows;
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
              _withPadding(themeModeButton()),
              _withPadding(languageButton()),
              _withPadding(fontScaleButton()),
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
              _withPadding(
                TextInputWidget(
                  title: SyncStoreInputMetaEnum.address,
                  initialValue: settingController.syncStoreUrl,
                  tailButton: debugOnlyWidget(
                    OutlinedButton.icon(
                      onPressed: settingController.syncStoreUrl == defaultSyncStoreUrl
                          ? null
                          : () async {
                              settingController.updateSyncStoreSetting(baseUrl: defaultSyncStoreUrl);
                              await reInitSyncStoreController();
                              _resetPingLatency();
                            },
                      icon: Tooltip(message: 'reset_default'.tr, child: const Icon(Icons.restore)),
                      label: const SizedBox.shrink(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(40, 36),
                      ),
                    ),
                  ),
                  onFinished: (value) async {
                    settingController.updateSyncStoreSetting(baseUrl: value);
                    await reInitSyncStoreController();
                    _resetPingLatency();
                  },
                ),
              ),
              _withPadding(
                BoolSelectorInputWidget(
                  title: SyncStoreInputMetaEnum.enableTunnel,
                  initialValue: settingController.syncStoreHpkeEnabled,
                  onChanged: (value) async {
                    settingController.updateSyncStoreSetting(enableHpke: value);
                    await reInitSyncStoreController();
                    _resetPingLatency();
                  },
                ),
              ),
              const Divider(),
              Text('app_feature_management'.tr),
              _withPadding(
                BoolSelectorInputWidget(
                  title: AppFeatureMetaEnum.enableTask,
                  initialValue: settingController.taskEnabled,
                  onChanged: (value) {
                    settingController.updateAppFeaturesManagement(enableTask: value);
                    _ensureStartupTabIndexValid();
                    setState(() {});
                  },
                ),
              ),
              if (showClipboardTraySettings)
                _withPadding(
                  BoolSelectorInputWidget(
                    title: AppFeatureMetaEnum.enableClipboardBackup,
                    initialValue: clipboardTrayController.featureEnabled.value,
                    onChanged: (value) async {
                      await clipboardTrayController.setFeatureEnabled(value);
                      setState(() {});
                    },
                  ),
                ),
              if (showClipboardTraySettings && clipboardTrayController.featureEnabled.value)
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 4, 8, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppFeatureMetaEnum.enableClipboardListening.gColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          AppFeatureMetaEnum.enableClipboardListening.gIcon,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppFeatureMetaEnum.enableClipboardListening.gTitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Switch(
                          value: clipboardTrayController.listeningEnabled.value,
                          onChanged: (value) async {
                            await clipboardTrayController.setListeningEnabled(value);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              _withPadding(
                BoolSelectorInputWidget(
                  title: AppFeatureMetaEnum.enableChat,
                  initialValue: settingController.chatEnabled,
                  onChanged: (value) {
                    settingController.updateAppFeaturesManagement(enableChat: value);
                    _ensureStartupTabIndexValid();
                    setState(() {});
                  },
                ),
              ),
              _withPadding(
                BoolSelectorInputWidget(
                  title: AppFeatureMetaEnum.enableNotes,
                  initialValue: settingController.notesEnabled,
                  onChanged: (value) {
                    settingController.updateAppFeaturesManagement(enableNotes: value);
                    _ensureStartupTabIndexValid();
                    setState(() {});
                  },
                ),
              ),
              _withPadding(
                BoolSelectorInputWidget(
                  title: AppFeatureMetaEnum.enableTracker,
                  initialValue: settingController.trackerEnabled,
                  onChanged: (value) {
                    settingController.updateAppFeaturesManagement(enableTracker: value);
                    _ensureStartupTabIndexValid();
                    setState(() {});
                  },
                ),
              ),
              _withPadding(
                UserDefinedInputWidget(
                  title: AppFeatureMetaEnum.startupTab,
                  widget: DropdownButton<int>(
                    value: _effectiveStartupTabIndex(),
                    onChanged: (newValue) {
                      if (newValue == null) return;
                      settingController.updateAppFeaturesManagement(homeStartupTabIndex: newValue);
                      setState(() {});
                    },
                    items: _startupTabCandidates()
                        .map(
                          (tabIndex) => DropdownMenuItem<int>(value: tabIndex, child: Text(_startupTabTitle(tabIndex))),
                        )
                        .toList(),
                  ),
                ),
              ),
              if (!kIsWeb && Platform.isAndroid)
                _withPadding(
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
              _withPadding(versionInfo(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withPadding(Widget child) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0), child: child);
  }

  void _resetPingLatency() {
    if (!mounted) return;
    setState(() {
      _pingLatencyMs = null;
    });
  }

  Widget themeModeButton() {
    final btn = SegmentedButton<ThemeMode>(
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
    final btn = DropdownButton<Locale>(
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
    final btn = Slider(
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
