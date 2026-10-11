import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart' show ColorTag;
import 'package:xbb/constant.dart';
import 'package:xbb/controller/clipboard_tray.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/translation.dart';

/// 纯净的全局应用配置状态
class AppSettingsState {
  final ThemeMode themeMode;
  final FlexScheme scheme;
  final String languageCode; // 'system', 'zh', 'en'
  final Locale locale;
  final double fontScale;
  final ColorTag colorTag;
  final bool taskEnabled;
  final bool notesEnabled;
  final bool trackerEnabled;
  final bool checkinEnabled;
  final bool chatEnabled;
  final bool clipboardEnabled;
  final bool clipboardListeningEnabled;
  final int startupTabIndex;

  const AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.scheme = FlexScheme.blumineBlue,
    this.languageCode = 'zh',
    this.locale = const Locale('zh', 'CN'),
    this.fontScale = 1.0,
    this.colorTag = ColorTag.none,
    this.taskEnabled = true,
    this.notesEnabled = true,
    this.trackerEnabled = true,
    this.checkinEnabled = true,
    this.chatEnabled = true,
    this.clipboardEnabled = true,
    this.clipboardListeningEnabled = false,
    this.startupTabIndex = 0,
  });

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    FlexScheme? scheme,
    String? languageCode,
    Locale? locale,
    double? fontScale,
    ColorTag? colorTag,
    bool? taskEnabled,
    bool? notesEnabled,
    bool? trackerEnabled,
    bool? checkinEnabled,
    bool? chatEnabled,
    bool? clipboardEnabled,
    bool? clipboardListeningEnabled,
    int? startupTabIndex,
  }) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      scheme: scheme ?? this.scheme,
      languageCode: languageCode ?? this.languageCode,
      locale: locale ?? this.locale,
      fontScale: fontScale ?? this.fontScale,
      colorTag: colorTag ?? this.colorTag,
      taskEnabled: taskEnabled ?? this.taskEnabled,
      notesEnabled: notesEnabled ?? this.notesEnabled,
      trackerEnabled: trackerEnabled ?? this.trackerEnabled,
      checkinEnabled: checkinEnabled ?? this.checkinEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      clipboardEnabled: clipboardEnabled ?? this.clipboardEnabled,
      clipboardListeningEnabled: clipboardListeningEnabled ?? this.clipboardListeningEnabled,
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
    String langCode = 'zh';
    Locale loc = const Locale('zh', 'CN');
    double scale = 1.0;
    ColorTag tag = ColorTag.none;
    int tab = 0;

    if (app != null) {
      final parsed = AppSetting.fromJson(app);
      mode = parsed.themeMode is ThemeMode ? parsed.themeMode : ThemeMode.system;
      final rawLocale = app['locale'] as String?;
      if (rawLocale != null && rawLocale.isNotEmpty) {
        if (rawLocale == 'system' || rawLocale == 'zh' || rawLocale == 'en') {
          langCode = rawLocale;
        } else if (rawLocale.startsWith('zh')) {
          langCode = 'zh';
        } else if (rawLocale.startsWith('en')) {
          langCode = 'en';
        }
      }
      scale = (parsed.fontScale as num?)?.toDouble() ?? 1.0;
      tag = parsed.colorTag is ColorTag ? parsed.colorTag : ColorTag.none;
    }

    String translationLocale = 'zh_CN';
    if (langCode == 'en') {
      loc = const Locale('en', 'US');
      translationLocale = 'en_US';
    } else if (langCode == 'system') {
      final sys = WidgetsBinding.instance.platformDispatcher.locale;
      if (sys.languageCode == 'en') {
        loc = const Locale('en', 'US');
        translationLocale = 'en_US';
      } else {
        loc = const Locale('zh', 'CN');
        translationLocale = 'zh_CN';
      }
    } else {
      langCode = 'zh';
      loc = const Locale('zh', 'CN');
      translationLocale = 'zh_CN';
    }
    Translation.setLocale(translationLocale);

    bool task = true;
    bool notes = true;
    bool tracker = true;
    bool checkin = true;
    bool chat = true;
    bool clip = true;
    bool clipListen = false;

    if (feature != null) {
      final f = AppFeaturesManagement.fromJson(feature);
      task = f.enableTask;
      notes = f.enableNotes;
      tracker = f.enableTracker;
      checkin = f.enableCheckin;
      chat = f.enableChat;
      clip = f.enableClipboardBackup;
      clipListen = f.enableClipboardListening;
      tab = f.homeStartupTabIndex;
    }

    state = state.copyWith(
      themeMode: mode,
      languageCode: langCode,
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
      clipboardListeningEnabled: clipListen,
    );

    // 同步初始化托盘与后台监听服务
    ClipboardTrayService.instance.init(
      featureEnabled: clip,
      listeningEnabled: clipListen,
    );
  }

  void _persistAppSetting() {
    final appMap = Map<String, dynamic>.from(
      box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_SETTINGS_KEY) ?? {},
    );
    appMap['theme_mode'] = state.themeMode.toString();
    appMap['font_scale'] = state.fontScale;
    appMap['locale'] = state.languageCode;
    appMap['color_tag'] = state.colorTag.toString();
    box.write(STORAGE_SETTING_APP_SETTINGS_KEY, appMap);
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persistAppSetting();
  }

  void setLanguageCode(String code) {
    Locale effectiveLocale;
    String translationLocale;
    if (code == 'zh') {
      effectiveLocale = const Locale('zh', 'CN');
      translationLocale = 'zh_CN';
    } else if (code == 'en') {
      effectiveLocale = const Locale('en', 'US');
      translationLocale = 'en_US';
    } else {
      code = 'system';
      final sys = WidgetsBinding.instance.platformDispatcher.locale;
      if (sys.languageCode == 'en') {
        effectiveLocale = const Locale('en', 'US');
        translationLocale = 'en_US';
      } else {
        effectiveLocale = const Locale('zh', 'CN');
        translationLocale = 'zh_CN';
      }
    }
    Translation.setLocale(translationLocale);
    state = state.copyWith(languageCode: code, locale: effectiveLocale);
    _persistAppSetting();
  }

  void setLocale(Locale loc) {
    setLanguageCode(loc.languageCode);
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
    _persistAppSetting();
  }

  void setColorTag(ColorTag tag) {
    state = state.copyWith(colorTag: tag);
    _persistAppSetting();
  }

  void setClipboardListeningEnabled(bool enabled) {
    state = state.copyWith(clipboardListeningEnabled: enabled);
    final featureMap = Map<String, dynamic>.from(
      box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY) ?? {},
    );
    featureMap['enable_clipboard_listening'] = enabled;
    box.write(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY, featureMap);

    ClipboardTrayService.instance.setListeningEnabled(enabled);
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

    if (clipboard != null) {
      ClipboardTrayService.instance.setFeatureEnabled(clipboard);
    }
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  return AppSettingsNotifier(box);
});
