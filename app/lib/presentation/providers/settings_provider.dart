import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart' show ColorTag;
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/core/core.dart';

/// 纯净的全局应用配置状态
class AppSettingsState {
  final ThemeMode themeMode;
  final FlexScheme scheme;
  final Locale locale;
  final double fontScale;
  final ColorTag colorTag;
  final bool taskEnabled;
  final bool notesEnabled;
  final bool trackerEnabled;
  final bool checkinEnabled;
  final bool chatEnabled;
  final bool clipboardEnabled;
  final int startupTabIndex;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.scheme = FlexScheme.blumineBlue,
    this.locale = const Locale('zh', 'CN'),
    this.fontScale = 1.0,
    this.colorTag = ColorTag.none,
    this.taskEnabled = true,
    this.notesEnabled = true,
    this.trackerEnabled = true,
    this.checkinEnabled = true,
    this.chatEnabled = true,
    this.clipboardEnabled = true,
    this.startupTabIndex = 0,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    FlexScheme? scheme,
    Locale? locale,
    double? fontScale,
    ColorTag? colorTag,
    bool? taskEnabled,
    bool? notesEnabled,
    bool? trackerEnabled,
    bool? checkinEnabled,
    bool? chatEnabled,
    bool? clipboardEnabled,
    int? startupTabIndex,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      scheme: scheme ?? this.scheme,
      locale: locale ?? this.locale,
      fontScale: fontScale ?? this.fontScale,
      colorTag: colorTag ?? this.colorTag,
      taskEnabled: taskEnabled ?? this.taskEnabled,
      notesEnabled: notesEnabled ?? this.notesEnabled,
      trackerEnabled: trackerEnabled ?? this.trackerEnabled,
      checkinEnabled: checkinEnabled ?? this.checkinEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      clipboardEnabled: clipboardEnabled ?? this.clipboardEnabled,
      startupTabIndex: startupTabIndex ?? this.startupTabIndex,
    );
  }
}

/// 全局应用配置 Notifier
class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final GetStorage box;

  AppSettingsNotifier(this.box) : super(const AppSettingsState()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final app = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_SETTINGS_KEY);
    final feature = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY);

    ThemeMode mode = ThemeMode.system;
    Locale loc = const Locale('zh', 'CN');
    double scale = 1.0;
    ColorTag tag = ColorTag.none;
    int tab = 0;

    if (app != null) {
      final parsed = AppSetting.fromJson(app);
      mode = parsed.themeMode is ThemeMode ? parsed.themeMode : ThemeMode.system;
      if (parsed.locale != null) {
        loc = parsed.locale as Locale;
      }
      scale = (parsed.fontScale as num?)?.toDouble() ?? 1.0;
      tag = parsed.colorTag is ColorTag ? parsed.colorTag : ColorTag.none;
    }

    bool task = true;
    bool notes = true;
    bool tracker = true;
    bool checkin = true;
    bool chat = true;
    bool clip = true;

    if (feature != null) {
      final f = AppFeaturesManagement.fromJson(feature);
      task = f.enableTask;
      notes = f.enableNotes;
      tracker = f.enableTracker;
      checkin = f.enableCheckin;
      chat = f.enableChat;
      clip = f.enableClipboardBackup;
      tab = f.homeStartupTabIndex;
    }

    state = state.copyWith(
      themeMode: mode,
      locale: loc,
      fontScale: scale,
      colorTag: tag,
      startupTabIndex: tab,
      taskEnabled: task,
      notesEnabled: notes,
      trackerEnabled: tracker,
      checkinEnabled: checkin,
      chatEnabled: chat,
      clipboardEnabled: clip,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLocale(Locale loc) {
    state = state.copyWith(locale: loc);
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
  }

  void setColorTag(ColorTag tag) {
    state = state.copyWith(colorTag: tag);
  }

  void toggleFeature({
    bool? task,
    bool? notes,
    bool? tracker,
    bool? checkin,
    bool? chat,
    bool? clipboard,
  }) {
    state = state.copyWith(
      taskEnabled: task,
      notesEnabled: notes,
      trackerEnabled: tracker,
      checkinEnabled: checkin,
      chatEnabled: chat,
      clipboardEnabled: clipboard,
    );
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  return AppSettingsNotifier(box);
});
