import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart' show ColorTag, UserProfile;
import 'package:xbb/constant.dart';

bool initFirstTime() {
  var settingController = Get.find<SettingController>();
  if (settingController.userId.isNotEmpty && settingController.userName.isNotEmpty) {
    print('already done first init before');
    return false;
  }
  print('first init');
  return true;
}

class SettingController extends GetxController {
  final box = GetStorage(GET_STORAGE_FILE_KEY);

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

  // syncstore settings
  final syncStoreSetting = SyncStoreSetting.defaults().obs;
  String get syncStoreUrl => syncStoreSetting.value.url;
  bool get syncStoreHpkeEnabled => syncStoreSetting.value.hpkeEnabled;
  void updateSyncStoreSetting({String? baseUrl, bool? enableHpke}) {
    syncStoreSetting.update((setting) {
      setting?.update(baseUrl: baseUrl, enableHpke: enableHpke);
    });
    box.write(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY, syncStoreSetting.value.toJson());
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
  void updateAppFeaturesManagement({bool? enableNotes}) {
    appFeaturesManagement.update((feature) {
      feature?.update(enableNotes: enableNotes);
    });
    box.write(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY, appFeaturesManagement.value.toJson());
  }

  // user interface history cache
  final _userInterfaceHistoryCache = UserInterfaceHistoryCache.defaults().obs;
  String? get notesLastOpenedRepoId => _userInterfaceHistoryCache.value.notesLastOpenedRepoId;
  void updateUserInterfaceHistoryCache({String? notesLastOpenedRepoId}) {
    _userInterfaceHistoryCache.update((cache) {
      cache?.update(notesLastOpenedRepoId: notesLastOpenedRepoId);
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

  get url => baseUrl;
  get hpkeEnabled => enableHpke;

  SyncStoreSetting({required this.baseUrl, required this.enableHpke});

  factory SyncStoreSetting.defaults() {
    return SyncStoreSetting(baseUrl: 'http://127.0.0.1:10101/api', enableHpke: false);
  }

  Map<String, dynamic> toJson() {
    return {'base_url': baseUrl, 'enable_hpke': enableHpke};
  }

  factory SyncStoreSetting.fromJson(Map<String, dynamic> json) {
    return SyncStoreSetting(
      baseUrl: json['base_url'] ?? 'http://127.0.0.1:10101/api',
      enableHpke: json['enable_hpke'] ?? false,
    );
  }

  void update({String? baseUrl, bool? enableHpke}) {
    if (baseUrl != null) {
      this.baseUrl = baseUrl;
    }
    if (enableHpke != null) {
      this.enableHpke = enableHpke;
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

  get notesEnabled => enableNotes;
  AppFeaturesManagement({required this.enableNotes});
  factory AppFeaturesManagement.defaults() {
    return AppFeaturesManagement(enableNotes: true);
  }
  Map<String, dynamic> toJson() {
    return {'enable_notes': enableNotes};
  }

  factory AppFeaturesManagement.fromJson(Map<String, dynamic> json) {
    return AppFeaturesManagement(enableNotes: json['enable_notes'] ?? true);
  }
  void update({bool? enableNotes}) {
    if (enableNotes != null) {
      this.enableNotes = enableNotes;
    }
  }
}

class UserInterfaceHistoryCache {
  String? notesLastOpenedRepoId;
  UserInterfaceHistoryCache({this.notesLastOpenedRepoId});
  factory UserInterfaceHistoryCache.defaults() {
    return UserInterfaceHistoryCache(notesLastOpenedRepoId: null);
  }
  Map<String, dynamic> toJson() {
    return {'notes_last_opened_repo_id': notesLastOpenedRepoId};
  }

  factory UserInterfaceHistoryCache.fromJson(Map<String, dynamic> json) {
    return UserInterfaceHistoryCache(notesLastOpenedRepoId: json['notes_last_opened_repo_id']);
  }
  void update({String? notesLastOpenedRepoId}) {
    if (notesLastOpenedRepoId != null) {
      this.notesLastOpenedRepoId = notesLastOpenedRepoId;
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
