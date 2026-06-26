import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart' show ColorTag, UserProfile;
import 'package:xbb/constant.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/controller/utils.dart';
import 'package:xbb/utils/text_input.dart';

enum ChatLLMProvider { deepSeek }

bool initFirstTime() {
  var settingController = Get.find<SettingController>();
  if (settingController.userId.isNotEmpty && settingController.userName.isNotEmpty) {
    print('already done first init before');
    return false;
  }
  print('first init');
  return true;
}

// task: List<({double weight, Future<void> Function() action})> tasks,
Future<void> runSyncTaskWithStatus(List<dynamic> tasks, {double from = 0.0, double to = 100.0}) async {
  final normalizedTasks = tasks.map((t) {
    if (t is Future Function()) {
      return (weight: 1.0, action: t);
    } else if (t is ({double weight, Future Function() action})) {
      return t;
    }
    throw ArgumentError("任务格式不支持");
  }).toList();

  double totalWeight = normalizedTasks.fold(0, (sum, item) => sum + item.weight);
  double currentCompletedWeight = 0;
  print('total weight: $totalWeight');

  final settingController = Get.find<SettingController>();

  for (var task in normalizedTasks) {
    await task.action();
    currentCompletedWeight += task.weight;
    int progress = ((currentCompletedWeight / totalWeight) * (to - from) + from).toInt();
    settingController.updateUserInterfaceHistoryCache(notesSyncProgress: progress);
    print('当前同步进度: $progress%');
  }
  settingController.updateUserInterfaceHistoryCache(notesSyncProgress: to.toInt());
}

class AppHomeStartupTabIndex {
  static const int notes = 0;
  static const int tracker = 1;
  static const int task = 2;
  static const int clipboard = 3;
  static const int chat = 4;
  static const int checkin = 5;
  static const int settings = 6;
}

class SettingController extends GetxController {
  final box = GetStorage(GET_STORAGE_FILE_KEY);

  @override
  void onReady() {
    super.onReady();
    onLateInit();
  }

  onLateInit() async {
    // delay a bit to avoid checking update too early before syncstore controller is ready
    await Future.delayed(const Duration(seconds: 5));
    checkUpdate();
  }

  @override
  Future onInit() async {
    print('new setting controller onInit');

    // load app setting from storage
    Map<String, dynamic>? app = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_SETTINGS_KEY);
    if (app != null) {
      appSetting.value = AppSetting.fromJson(app);
    }
    // load app feature management from storage
    Map<String, dynamic>? feature = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY);
    if (feature != null) {
      appFeaturesManagement.value = AppFeaturesManagement.fromJson(feature);
    }
    // load user interface history cache from storage
    Map<String, dynamic>? uiCache = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INTERFACE_HISTORY_CACHE_KEY);
    if (uiCache != null) {
      _userInterfaceHistoryCache.value = UserInterfaceHistoryCache.fromJson(uiCache);
    }
    // load user info from storage
    Map<String, dynamic>? user = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INFO_KEY);
    if (user != null) {
      userInfo.value = UserInfo.fromJson(user);
    }
    // load quick login info from storage
    Map<String, dynamic>? quickLogin = box.read<Map<String, dynamic>?>(STORAGE_SETTING_QUICK_LOGIN_KEY);
    if (quickLogin != null) {
      quickLogins.value = QuickLoginInfo.fromJson(quickLogin);
    }
    // load syncstore setting from storage
    Map<String, dynamic>? syncstore = box.read<Map<String, dynamic>?>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY);
    if (syncstore != null) {
      syncStoreSetting.value = SyncStoreSetting.fromJson(syncstore);
    }
    // load chat llm setting from storage
    Map<String, dynamic>? chatLlm = box.read<Map<String, dynamic>?>(STORAGE_SETTING_CHAT_LLM_SETTINGS_KEY);
    if (chatLlm != null) {
      chatLLMSetting.value = ChatLLMSetting.fromJson(chatLlm);
    }
    super.onInit();

    _initialized = true;
  }

  bool _initialized = false;
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  // memory state
  final downloadProgress = 0.0.obs;
  final _isCheckingUpdate = false.obs;
  bool get isCheckingUpdate => _isCheckingUpdate.value;
  set isCheckingUpdate(bool value) => _isCheckingUpdate.value = value;

  // syncstore settings
  final syncStoreSetting = SyncStoreSetting.defaults().obs;
  String get syncStoreUrl => syncStoreSetting.value.url;
  bool get syncStoreHpkeEnabled => syncStoreSetting.value.hpkeEnabled;
  void updateSyncStoreSetting({String? baseUrl, bool? enableHpke, List<String>? urlHistory}) {
    syncStoreSetting.update((setting) {
      setting?.update(baseUrl: baseUrl, enableHpke: enableHpke, urlHistory: urlHistory);
    });
    box.write(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY, syncStoreSetting.value.toJson());
  }

  // chat llm settings
  final chatLLMSetting = ChatLLMSetting.defaults().obs;
  ChatLLMProvider get chatProvider => chatLLMSetting.value.provider;
  String get chatBaseUrl => chatLLMSetting.value.baseUrl;
  String get chatModel => chatLLMSetting.value.model;
  List<String> get chatModelCandidates => chatLLMSetting.value.modelCandidates;
  String? get chatApiKey => chatLLMSetting.value.apiKey;
  double get chatTemperature => chatLLMSetting.value.temperature;
  void updateChatLLMSetting({
    ChatLLMProvider? provider,
    String? baseUrl,
    String? model,
    List<String>? modelCandidates,
    String? apiKey,
    double? temperature,
  }) {
    chatLLMSetting.update((setting) {
      setting?.update(
        provider: provider,
        baseUrl: baseUrl,
        model: model,
        modelCandidates: modelCandidates,
        apiKey: apiKey,
        temperature: temperature,
      );
    });
    box.write(STORAGE_SETTING_CHAT_LLM_SETTINGS_KEY, chatLLMSetting.value.toJson());
  }

  // app settings
  final appSetting = AppSetting.defaults().obs;
  ThemeMode get themeMode => appSetting.value.themeMode;
  double get fontScale => appSetting.value.fontScale;
  Locale get locale => appSetting.value.locale;
  ColorTag get colorTag => appSetting.value.colorTag;
  bool get appCanUpdate => appSetting.value.canUpdate;
  DateTime? get appLastCheckedUpdateTime => appSetting.value.lastUpdateCheckTime;
  void updateAppSetting({
    ThemeMode? themeMode,
    double? fontScale,
    Locale? locale,
    ColorTag? colorTag,
    bool? canUpdate,
    DateTime? lastCheckedUpdateTime,
  }) {
    appSetting.update((setting) {
      setting?.update(
        themeMode: themeMode,
        fontScale: fontScale,
        locale: locale,
        colorTag: colorTag,
        canUpdate: canUpdate,
        lastCheckedUpdateTime: lastCheckedUpdateTime,
      );
    });
    box.write(STORAGE_SETTING_APP_SETTINGS_KEY, appSetting.value.toJson());
  }

  // app feature management
  final appFeaturesManagement = AppFeaturesManagement.defaults().obs;
  bool get notesEnabled => appFeaturesManagement.value.notesEnabled;
  bool get trackerEnabled => appFeaturesManagement.value.trackerEnabled;
  bool get taskEnabled => appFeaturesManagement.value.enableTask; // task is optional feature, default enabled
  bool get clipboardBackupEnabled => appFeaturesManagement.value.enableClipboardBackup;
  bool get clipboardListeningEnabled => appFeaturesManagement.value.enableClipboardListening;
  bool get chatEnabled => appFeaturesManagement.value.enableChat;
  bool get checkinEnabled => appFeaturesManagement.value.enableCheckin;
  int get homeStartupTabIndex => appFeaturesManagement.value.homeStartupTabIndex;
  void updateAppFeaturesManagement({
    bool? enableNotes,
    bool? enableTracker,
    bool? enableTask,
    bool? enableClipboardBackup,
    bool? enableClipboardListening,
    bool? enableChat,
    bool? enableCheckin,
    int? homeStartupTabIndex,
  }) {
    appFeaturesManagement.update((feature) {
      feature?.update(
        enableNotes: enableNotes,
        enableTracker: enableTracker,
        enableTask: enableTask,
        enableClipboardBackup: enableClipboardBackup,
        enableClipboardListening: enableClipboardListening,
        enableChat: enableChat,
        enableCheckin: enableCheckin,
        homeStartupTabIndex: homeStartupTabIndex,
      );
    });
    box.write(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY, appFeaturesManagement.value.toJson());
  }

  // user interface history cache
  final _userInterfaceHistoryCache = UserInterfaceHistoryCache.defaults().obs;
  String? get notesLastOpenedRepoId => _userInterfaceHistoryCache.value.notesLastOpenedRepoId;
  int get notesSyncProgress => _userInterfaceHistoryCache.value.notesSyncProgress;
  void updateUserInterfaceHistoryCache({String? notesLastOpenedRepoId, int? notesSyncProgress}) {
    _userInterfaceHistoryCache.update((cache) {
      cache?.update(notesLastOpenedRepoId: notesLastOpenedRepoId, notesSyncProgress: notesSyncProgress);
    });
    box.write(STORAGE_SETTING_USER_INTERFACE_HISTORY_CACHE_KEY, _userInterfaceHistoryCache.value.toJson());
  }

  // user info
  final userInfo = UserInfo.unknown().obs;
  String get userId => userInfo.value.id;
  String get userName => userInfo.value.name;
  String get userPassword => userInfo.value.password;
  void updateUserInfo({String? userId, String? userName, String? userPassword}) {
    userInfo.update((info) {
      info?.update(userId: userId, userName: userName, userPassword: userPassword);
    });
    box.write(STORAGE_SETTING_USER_INFO_KEY, userInfo.value.toJson());
    TaskWidgetBridge.scheduleRefresh();
  }

  // quick login info
  final quickLogins = QuickLoginInfo.defaults().obs;
  UserInfo? quickLoginUser(String userId) => quickLogins.value.quickLoginMap[userId];
  void updateQuickLoginInfo({String? userId, UserInfo? userInfo}) {
    quickLogins.update((ql) {
      ql?.update(userId: userId, userInfo: userInfo);
    });
    box.write(STORAGE_SETTING_QUICK_LOGIN_KEY, quickLogins.value.toJson());
  }

  // mainly for update user's name/avatar when user has already quick login info before
  void updateQuickLoginInfoIfExist(String userId, UserProfile profile) {
    final existing = quickLogins.value.quickLoginMap[userId];
    if (existing != null) {
      updateQuickLoginInfo(
        userId: userId,
        userInfo: UserInfo.fromProfile(profile, password: existing.password),
      );
    }
  }
}

class SyncStoreSetting {
  String baseUrl;
  bool enableHpke;
  List<String> urlHistory;

  get url => baseUrl;
  get hpkeEnabled => enableHpke;

  SyncStoreSetting({required this.baseUrl, required this.enableHpke, List<String>? urlHistory})
    : urlHistory = urlHistory ?? [];

  factory SyncStoreSetting.defaults() {
    return SyncStoreSetting(baseUrl: 'http://127.0.0.1:10101/api', enableHpke: false);
  }

  Map<String, dynamic> toJson() {
    return {'base_url': baseUrl, 'enable_hpke': enableHpke, 'url_history': urlHistory};
  }

  factory SyncStoreSetting.fromJson(Map<String, dynamic> json) {
    return SyncStoreSetting(
      baseUrl: json['base_url'] ?? 'http://127.0.0.1:10101/api',
      enableHpke: json['enable_hpke'] ?? false,
      urlHistory: ((json['url_history'] as List<dynamic>?) ?? []).cast<String>(),
    );
  }

  void update({String? baseUrl, bool? enableHpke, List<String>? urlHistory}) {
    if (baseUrl != null) {
      this.baseUrl = baseUrl;
    }
    if (enableHpke != null) {
      this.enableHpke = enableHpke;
    }
    if (urlHistory != null) {
      this.urlHistory = urlHistory;
    }
  }
}

class ChatLLMSetting {
  ChatLLMProvider provider;
  String baseUrl;
  String model;
  List<String> modelCandidates;
  String? apiKey;
  double temperature;

  ChatLLMSetting({
    required this.provider,
    required this.baseUrl,
    required this.model,
    required this.modelCandidates,
    required this.apiKey,
    required this.temperature,
  });

  factory ChatLLMSetting.defaults() {
    return ChatLLMSetting(
      provider: ChatLLMProvider.deepSeek,
      baseUrl: 'https://api.deepseek.com/v1',
      model: 'deepseek-chat',
      modelCandidates: const [],
      apiKey: null,
      temperature: 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'base_url': baseUrl,
      'model': model,
      'model_candidates': modelCandidates,
      'api_key': apiKey,
      'temperature': temperature,
    };
  }

  factory ChatLLMSetting.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider'] as String?;
    final parsedProvider = ChatLLMProvider.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => ChatLLMProvider.deepSeek,
    );
    return ChatLLMSetting(
      provider: parsedProvider,
      baseUrl: json['base_url'] ?? 'https://api.deepseek.com/v1',
      model: json['model'] ?? 'deepseek-chat',
      modelCandidates: ((json['model_candidates'] as List<dynamic>?) ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(),
      apiKey: json['api_key'] as String?,
      temperature: ((json['temperature'] as num?) ?? 1.0).toDouble(),
    );
  }

  void update({
    ChatLLMProvider? provider,
    String? baseUrl,
    String? model,
    List<String>? modelCandidates,
    String? apiKey,
    double? temperature,
  }) {
    if (provider != null) {
      this.provider = provider;
    }
    if (baseUrl != null) {
      this.baseUrl = baseUrl;
    }
    if (model != null) {
      this.model = model;
    }
    if (modelCandidates != null) {
      this.modelCandidates = modelCandidates;
    }
    if (apiKey != null) {
      this.apiKey = apiKey;
    }
    if (temperature != null) {
      this.temperature = temperature;
    }
  }
}

class AppSetting {
  ThemeMode _themeMode;
  double _fontScale;
  Locale _locale;
  ColorTag _colorTag = ColorTag.none;
  bool _canUpdate = false;
  DateTime? _lastCheckedUpdateTime;

  get themeMode => _themeMode;
  get fontScale => _fontScale;
  get locale => _locale;
  get colorTag => _colorTag;
  get canUpdate => _canUpdate;
  get lastUpdateCheckTime => _lastCheckedUpdateTime;

  AppSetting({
    required ThemeMode themeMode,
    required double fontScale,
    required Locale locale,
    required ColorTag colorTag,
    required bool canUpdate,
    required DateTime? lastCheckedUpdateTime,
  }) : _themeMode = themeMode,
       _fontScale = fontScale,
       _locale = locale,
       _colorTag = colorTag,
       _canUpdate = canUpdate,
       _lastCheckedUpdateTime = lastCheckedUpdateTime;

  factory AppSetting.defaults() {
    return AppSetting(
      themeMode: ThemeMode.system,
      fontScale: 1.0,
      locale: const Locale('en'),
      colorTag: ColorTag.none,
      canUpdate: false,
      lastCheckedUpdateTime: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': _themeMode.toString(),
      'font_scale': _fontScale,
      'locale': _locale.languageCode,
      'color_tag': _colorTag.toString(),
      'can_update': _canUpdate,
      'last_checked_update_time': _lastCheckedUpdateTime?.toIso8601String(),
    };
  }

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    ThemeMode themeMode;
    try {
      themeMode = ThemeMode.values.firstWhere((e) => e.toString() == json['theme_mode']);
    } catch (_) {
      themeMode = ThemeMode.system;
    }
    double fontScale = (json['font_scale'] as num).toDouble();
    Locale locale = Locale(json['locale'] ?? 'en');
    ColorTag colorTag = ColorTag.values.firstWhere(
      (e) => e.toString() == json['color_tag'],
      orElse: () => ColorTag.none,
    );
    bool canUpdate = json['can_update'] ?? false;
    DateTime? lastCheckedUpdateTime;
    if (json['last_checked_update_time'] != null) {
      lastCheckedUpdateTime = DateTime.tryParse(json['last_checked_update_time']);
    }
    return AppSetting(
      themeMode: themeMode,
      fontScale: fontScale,
      locale: locale,
      colorTag: colorTag,
      canUpdate: canUpdate,
      lastCheckedUpdateTime: lastCheckedUpdateTime,
    );
  }

  void update({
    ThemeMode? themeMode,
    double? fontScale,
    Locale? locale,
    ColorTag? colorTag,
    bool? canUpdate,
    DateTime? lastCheckedUpdateTime,
  }) {
    if (themeMode != null) {
      _themeMode = themeMode;
    }
    if (fontScale != null) {
      _fontScale = fontScale;
    }
    if (locale != null) {
      _locale = locale;
    }
    if (colorTag != null) {
      _colorTag = colorTag;
    }
    if (canUpdate != null) {
      _canUpdate = canUpdate;
    }
    if (lastCheckedUpdateTime != null) {
      _lastCheckedUpdateTime = lastCheckedUpdateTime;
    }
  }
}

class AppFeaturesManagement {
  bool enableNotes;
  bool enableTracker;
  bool enableTask;
  bool enableClipboardBackup;
  bool enableClipboardListening;
  bool enableChat;
  bool enableCheckin;
  int homeStartupTabIndex;

  get notesEnabled => enableNotes;
  get trackerEnabled => enableTracker;
  get taskEnabled => enableTask;
  get clipboardBackupEnabled => enableClipboardBackup;
  get clipboardListeningEnabled => enableClipboardListening;
  get chatEnabled => enableChat;
  get checkinEnabled => enableCheckin;
  AppFeaturesManagement({
    required this.enableNotes,
    required this.enableTracker,
    required this.enableTask,
    required this.enableClipboardBackup,
    required this.enableClipboardListening,
    required this.enableChat,
    required this.enableCheckin,
    required this.homeStartupTabIndex,
  });
  factory AppFeaturesManagement.defaults() {
    return AppFeaturesManagement(
      enableNotes: true,
      enableTracker: false,
      enableTask: true,
      enableClipboardBackup: false,
      enableClipboardListening: false,
      enableChat: false,
      enableCheckin: false,
      homeStartupTabIndex: AppHomeStartupTabIndex.notes,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'enable_notes': enableNotes,
      'enable_tracker': enableTracker,
      'enable_task': enableTask,
      'enable_clipboard_backup': enableClipboardBackup,
      'enable_clipboard_listening': enableClipboardListening,
      'enable_chat': enableChat,
      'enable_checkin': enableCheckin,
      'home_startup_tab_index': homeStartupTabIndex,
    };
  }

  factory AppFeaturesManagement.fromJson(Map<String, dynamic> json) {
    final rawStartupTabIndex = json['home_startup_tab_index'];
    final startupTabIndex = switch (rawStartupTabIndex) {
      int value => value,
      num value => value.toInt(),
      _ => AppHomeStartupTabIndex.notes,
    };
    return AppFeaturesManagement(
      enableNotes: json['enable_notes'] ?? true,
      enableTracker: json['enable_tracker'] ?? false,
      enableTask: json['enable_task'] ?? true,
      enableClipboardBackup: json['enable_clipboard_backup'] ?? false,
      enableClipboardListening: json['enable_clipboard_listening'] ?? false,
      enableChat: json['enable_chat'] ?? false,
      enableCheckin: json['enable_checkin'] ?? false,
      homeStartupTabIndex: startupTabIndex,
    );
  }
  void update({
    bool? enableNotes,
    bool? enableTracker,
    bool? enableTask,
    bool? enableClipboardBackup,
    bool? enableClipboardListening,
    bool? enableChat,
    bool? enableCheckin,
    int? homeStartupTabIndex,
  }) {
    if (enableNotes != null) {
      this.enableNotes = enableNotes;
    }
    if (enableTracker != null) {
      this.enableTracker = enableTracker;
    }
    if (enableTask != null) {
      this.enableTask = enableTask;
    }
    if (enableClipboardBackup != null) {
      this.enableClipboardBackup = enableClipboardBackup;
    }
    if (enableClipboardListening != null) {
      this.enableClipboardListening = enableClipboardListening;
    }
    if (enableChat != null) {
      this.enableChat = enableChat;
    }
    if (enableCheckin != null) {
      this.enableCheckin = enableCheckin;
    }
    if (homeStartupTabIndex != null) {
      this.homeStartupTabIndex = homeStartupTabIndex;
    }
  }
}

class UserInterfaceHistoryCache {
  String? notesLastOpenedRepoId;
  int notesSyncProgress;
  UserInterfaceHistoryCache({this.notesLastOpenedRepoId, required this.notesSyncProgress});
  factory UserInterfaceHistoryCache.defaults() {
    return UserInterfaceHistoryCache(notesLastOpenedRepoId: null, notesSyncProgress: 100);
  }
  Map<String, dynamic> toJson() {
    return {'notes_last_opened_repo_id': notesLastOpenedRepoId, 'notes_sync_progress': notesSyncProgress};
  }

  factory UserInterfaceHistoryCache.fromJson(Map<String, dynamic> json) {
    return UserInterfaceHistoryCache(
      notesLastOpenedRepoId: json['notes_last_opened_repo_id'],
      notesSyncProgress: json['notes_sync_progress'] ?? 100,
    );
  }
  void update({String? notesLastOpenedRepoId, int? notesSyncProgress}) {
    if (notesLastOpenedRepoId != null) {
      this.notesLastOpenedRepoId = notesLastOpenedRepoId;
    }
    if (notesSyncProgress != null) {
      this.notesSyncProgress = notesSyncProgress;
    }
  }
}

class UserInfo {
  String _userId;
  String _userName;
  String _userPassword;
  String? _userAvatarUrl;

  get id => _userId;
  get name => _userName;
  get password => _userPassword;
  get avatarUrl => _userAvatarUrl;

  UserInfo({required String userId, required String userName, required String userPassword, String? userAvatarUrl})
    : _userId = userId,
      _userName = userName,
      _userPassword = userPassword,
      _userAvatarUrl = userAvatarUrl;

  factory UserInfo.fromProfile(UserProfile profile, {required String password}) {
    return UserInfo(
      userId: profile.userId,
      userName: profile.name,
      userPassword: password,
      userAvatarUrl: profile.avatarUrl,
    );
  }

  factory UserInfo.unknown() {
    return UserInfo(userId: 'unknown', userName: '', userPassword: '', userAvatarUrl: null);
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': _userId,
      'user_name': _userName,
      'user_password': _userPassword,
      'user_avatar_url': _userAvatarUrl,
    };
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'],
      userName: json['user_name'],
      userPassword: json['user_password'],
      userAvatarUrl: json['user_avatar_url'],
    );
  }

  void update({String? userId, String? userName, String? userPassword, String? userAvatarUrl}) {
    if (userId != null) {
      _userId = userId;
    }
    if (userName != null) {
      _userName = userName;
    }
    if (userPassword != null) {
      _userPassword = userPassword;
    }
    if (userAvatarUrl != null) {
      _userAvatarUrl = userAvatarUrl;
    }
  }
}

class QuickLoginInfo {
  Map<String, UserInfo> quickLoginMap;
  QuickLoginInfo({required this.quickLoginMap});
  factory QuickLoginInfo.defaults() {
    return QuickLoginInfo(quickLoginMap: {});
  }
  Map<String, dynamic> toJson() {
    return {'quick_login_map': quickLoginMap.map((key, value) => MapEntry(key, value.toJson()))};
  }

  factory QuickLoginInfo.fromJson(Map<String, dynamic> json) {
    return QuickLoginInfo(
      quickLoginMap:
          (json['quick_login_map'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, UserInfo.fromJson(value)),
          ) ??
          {},
    );
  }
  void update({String? userId, UserInfo? userInfo}) {
    if (userId != null && userInfo != null) {
      quickLoginMap[userId] = userInfo;
    } else if (userId != null && userInfo == null) {
      quickLoginMap.remove(userId);
    }
  }
}

class SyncStoreUrlHistory implements TextInputHistory {
  final SettingController _controller;

  SyncStoreUrlHistory(this._controller);

  @override
  List<String> load() {
    return List.from(_controller.syncStoreSetting.value.urlHistory);
  }

  @override
  void save(String value) {
    final list = load();
    list.remove(value);
    list.insert(0, value);
    if (list.length > 10) list.removeLast();
    _controller.updateSyncStoreSetting(urlHistory: list);
  }

  @override
  void remove(String value) {
    final list = load();
    list.remove(value);
    _controller.updateSyncStoreSetting(urlHistory: list);
  }

  @override
  void clear() {
    _controller.updateSyncStoreSetting(urlHistory: []);
  }
}
