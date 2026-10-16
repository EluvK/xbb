import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart' show ColorTag;
import 'package:xbb/constant.dart';
import 'package:xbb/controller/clipboard_tray.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/utils/translation.dart';

/// 纯净的全局应用配置状态
class AppSettingsState {
  final ThemeMode themeMode;
  final FlexScheme scheme;
  final String languageCode; // 'system', 'zh', 'en'
  final Locale locale;
  final double fontScale;
  final ColorTag colorTag;
  final String syncStoreUrl;
  final List<String> syncStoreUrlHistory;
  final bool taskEnabled;
  final bool notesEnabled;
  final bool trackerEnabled;
  final bool checkinEnabled;
  final bool chatEnabled;
  final bool clipboardEnabled;
  final bool clipboardListeningEnabled;
  final int startupTabIndex;

  AppSettingsState({
    this.themeMode = ThemeMode.system,
    this.scheme = FlexScheme.blumineBlue,
    this.languageCode = 'zh',
    this.locale = const Locale('zh', 'CN'),
    this.fontScale = 1.0,
    this.colorTag = ColorTag.none,
    String? syncStoreUrl,
    List<String>? syncStoreUrlHistory,
    this.taskEnabled = true,
    this.notesEnabled = true,
    this.trackerEnabled = true,
    this.checkinEnabled = true,
    this.chatEnabled = true,
    this.clipboardEnabled = true,
    this.clipboardListeningEnabled = false,
    this.startupTabIndex = 0,
  })  : syncStoreUrl = syncStoreUrl ?? ApiClient.defaultDevServerUrl,
        syncStoreUrlHistory = syncStoreUrlHistory ?? [ApiClient.defaultDevServerUrl];

  AppSettingsState copyWith({
    ThemeMode? themeMode,
    FlexScheme? scheme,
    String? languageCode,
    Locale? locale,
    double? fontScale,
    ColorTag? colorTag,
    String? syncStoreUrl,
    List<String>? syncStoreUrlHistory,
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
      syncStoreUrl: syncStoreUrl ?? this.syncStoreUrl,
      syncStoreUrlHistory: syncStoreUrlHistory ?? this.syncStoreUrlHistory,
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

  AppSettingsNotifier(this.box) : super(AppSettingsState()) {
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

    final syncSetting = box.read<Map<String, dynamic>?>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY);
    String syncUrl = ApiClient.defaultDevServerUrl;
    List<String> urlHistory = [ApiClient.defaultDevServerUrl];
    if (syncSetting != null) {
      syncUrl = syncSetting['base_url'] as String? ?? ApiClient.defaultDevServerUrl;
      final rawHist = syncSetting['url_history'] as List<dynamic>?;
      if (rawHist != null && rawHist.isNotEmpty) {
        urlHistory = rawHist.map((e) => e.toString()).toList();
      }
    }

    state = state.copyWith(
      themeMode: mode,
      languageCode: langCode,
      locale: loc,
      fontScale: scale,
      colorTag: tag,
      syncStoreUrl: syncUrl,
      syncStoreUrlHistory: urlHistory,
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

  Future<void> updateSyncStoreUrl(String newUrl) async {
    final normalized = ApiClient.normalizeBaseUrl(newUrl);
    final history = List<String>.from(state.syncStoreUrlHistory);
    history.remove(normalized);
    history.insert(0, normalized);
    if (history.length > 10) history.removeLast();

    state = state.copyWith(
      syncStoreUrl: normalized,
      syncStoreUrlHistory: history,
    );

    final rawSetting = box.read<Map<String, dynamic>?>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY) ?? {};
    final updatedMap = Map<String, dynamic>.from(rawSetting)
      ..['base_url'] = normalized
      ..['url_history'] = history;
    await box.write(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY, updatedMap);

    ApiClient.instance.updateBaseUrl(normalized);
    SyncWorker.instance.updateDependencies(dio: ApiClient.instance.dio);
  }

  Future<void> resetDefaultSyncStoreUrl() async {
    final defaultUrl = ApiClient.defaultDevServerUrl;
    await updateSyncStoreUrl(defaultUrl);
  }

  Future<void> removeSyncStoreUrlHistory(String url) async {
    final history = List<String>.from(state.syncStoreUrlHistory)..remove(url);
    state = state.copyWith(syncStoreUrlHistory: history);

    final rawSetting = box.read<Map<String, dynamic>?>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY) ?? {};
    final updatedMap = Map<String, dynamic>.from(rawSetting)..['url_history'] = history;
    await box.write(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY, updatedMap);
  }

  void setStartupTabIndex(int index) {
    state = state.copyWith(startupTabIndex: index);
    final featureMap = Map<String, dynamic>.from(
      box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY) ?? {},
    );
    featureMap['home_startup_tab_index'] = index;
    box.write(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY, featureMap);
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

    final featureMap = Map<String, dynamic>.from(
      box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY) ?? {},
    );
    if (task != null) featureMap['enable_task'] = task;
    if (notes != null) featureMap['enable_notes'] = notes;
    if (tracker != null) featureMap['enable_tracker'] = tracker;
    if (checkin != null) featureMap['enable_checkin'] = checkin;
    if (chat != null) featureMap['enable_chat'] = chat;
    if (clipboard != null) featureMap['enable_clipboard_backup'] = clipboard;
    box.write(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY, featureMap);

    if (clipboard != null) {
      ClipboardTrayService.instance.setFeatureEnabled(clipboard);
    }
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettingsState>((ref) {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  return AppSettingsNotifier(box);
});
