import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ota_update/ota_update.dart';
import 'package:syncstore_client/syncstore_client.dart' show ColorTag;
import 'package:xbb/constant.dart';
import 'package:xbb/utils/predefined.dart';
import 'package:xbb/utils/utils.dart';

bool initFirstTime() {
  var settingController = Get.find<NewSettingController>();
  if (settingController.userId.isNotEmpty && settingController.userName.isNotEmpty) {
    print('already done first init before');
    return false;
  }
  print('first init');
  return true;
}

Future<void> initCacheSetting() async {}

class SettingController extends GetxController {
  final box = GetStorage(GET_STORAGE_FILE_KEY);

  // app settings
  final themeMode = ThemeMode.system.obs;
  final fontScale = 1.0.obs;
  final locale = const Locale('en').obs;
  final autoCheckAppUpdate = true.obs;

  // sync settings
  final autoSyncSelfRepo = false.obs;
  final autoSyncSubscribeRepo = true.obs;

  // cache information
  final serverAddress = "".obs;
  final currentRepoId = "".obs;
  final currentUserName = "".obs;
  final currentUserPasswd = "".obs;
  final currentUserId = "".obs;
  final currentUserAvatarUrl = "".obs;

  // local state
  final canUpdate = false.obs;
  final quickReloadMode = false.obs;

  // memory state
  final downloadProgress = 0.0.obs;
  final lastAutoLoadTimestamp = DateTime.fromMillisecondsSinceEpoch(0).obs;

  @override
  Future onInit() async {
    print('setting controller onInit');
    getAppSetting();
    getSyncSetting();
    getCacheSetting();
    getLocalState();
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

  getAppSetting() {
    String themeText = box.read('theme') ?? 'system';
    print('read theme from box $themeText');
    try {
      themeMode.value = ThemeMode.values.firstWhere((e) => e.toString() == themeText);
    } catch (_) {
      print('theme not found, setting to system');
      themeMode.value = ThemeMode.system;
    }
    fontScale.value = box.read('font_scale') ?? 1.0;
    locale.value = Locale(box.read('locale') ?? 'zh');
    autoCheckAppUpdate.value = box.read('auto_check_app_update') ?? true;
  }

  setFontScale(double scale) {
    setQuickReloadMode(true);
    fontScale.value = scale;
    Get.forceAppUpdate().then((value) {
      setQuickReloadMode(false);
    });
    box.write('font_scale', scale);
  }

  setLocale(Locale locale) {
    setQuickReloadMode(true);
    this.locale.value = locale;
    Get.updateLocale(locale).then((value) {
      setQuickReloadMode(false);
    });
    box.write('locale', locale.languageCode);
  }

  setThemeMode(ThemeMode theme) {
    print('setting theme: $theme');
    themeMode.value = theme;
    Get.changeThemeMode(themeMode.value);
    box.write('theme', themeMode.value.toString());
  }

  setAutoCheckUpdate(bool value) {
    autoCheckAppUpdate.value = value;
    box.write('auto_check_app_update', value);
  }

  getSyncSetting() {
    autoSyncSelfRepo.value = box.read('auto_sync_self_repo') ?? false;
    autoSyncSubscribeRepo.value = box.read('auto_sync_subscribe_repo') ?? true;
  }

  setAutoSyncSelfRepo(bool value) {
    autoSyncSelfRepo.value = value;
    box.write('auto_sync_self_repo', value);
  }

  setAutoSyncSubscribeRepo(bool value) {
    autoSyncSubscribeRepo.value = value;
    box.write('auto_sync_subscribe_repo', value);
  }

  getCacheSetting() {
    serverAddress.value = box.read('server_address') ?? 'https://';
    currentRepoId.value = box.read('current_repo_id') ?? '0';
    currentUserName.value = box.read('current_user_name') ?? '';
    currentUserPasswd.value = box.read('current_user_passwd') ?? '';
    currentUserId.value = box.read('current_user_id') ?? '';
    // currentUserAvatarUrl.value = box.read('current_user_avatar_url') ?? defaultAvatarLink;
  }

  getCurrentBaseAuth() {
    return 'Basic ${base64Encode(utf8.encode('$currentUserId/$currentUserName:$currentUserPasswd'))}';
  }

  setServerAddress(String address) {
    serverAddress.value = address;
    box.write('server_address', address);
  }

  getServerAddress() {
    return serverAddress.value;
  }

  setUser(String id, {String? name, String? password, String? avatarUrl}) {
    currentUserId.value = id;
    box.write('current_user_id', currentUserId.value);
    if (name != null) {
      currentUserName.value = name;
      box.write('current_user_name', currentUserName.value);
    }
    if (password != null) {
      currentUserPasswd.value = password;
      box.write('current_user_passwd', currentUserPasswd.value);
    }
    if (avatarUrl != null) {
      currentUserAvatarUrl.value = avatarUrl;
      box.write('current_user_avatar_url', currentUserAvatarUrl.value);
    }
  }

  setCurrentRepo(String repo) {
    currentRepoId.value = repo;
    box.write('current_repo_id', repo);
  }

  downloadApk(String url) {
    try {
      OtaUpdate().execute(url, destinationFilename: "xbb.apk").listen((event) {
        print('event: $event');
        print('status: ${event.status}, value: ${event.value}');
        if (event.status == OtaStatus.DOWNLOADING) {
          downloadProgress.value = double.parse(event.value ?? '0') / 100;
        } else if (event.status == OtaStatus.DOWNLOAD_ERROR) {
          flushBar(FlushLevel.WARNING, 'Failed', event.value);
        } else if (event.status == OtaStatus.INSTALLING) {
          downloadProgress.value = 0.0;
          flushBar(FlushLevel.OK, 'Success', 'Download success');
        }
      });
    } catch (e) {
      print('Failed to make OTA update. Details: $e');
      flushBar(FlushLevel.WARNING, 'Failed', 'Failed to make OTA update $e');
    }
  }

  getLocalState() {
    canUpdate.value = box.read('can_update') ?? false;
    quickReloadMode.value = box.read('quick_reload_mode') ?? false;
  }

  setCanUpdate(bool value) {
    canUpdate.value = value;
    box.write('can_update', value);
  }

  setQuickReloadMode(bool value) {
    // print('setUpdateAppMode,$value');
    quickReloadMode.value = value;
    box.write('quick_reload_mode', value);
  }

  checkIfUpdate({bool manually = false, bool doUpdateIfCan = false}) {
    if (!manually && !autoCheckAppUpdate.value) {
      return;
    }
    _getLatestVersionThen((version) {
      if (_shouldUpdate(version)) {
        if (!manually || !doUpdateIfCan) {
          flushBar(FlushLevel.INFO, "有新版本啦", "最新版本: $version", upperPosition: true);
          setCanUpdate(true);
          return;
        }
        // do update:
        if (GetPlatform.isWindows) {
          String url =
              "https://pub-35fb8e0d745944819b75af2768f58058.r2.dev/release/$version/xbb_desktop_windows_setup.exe";
          print(url);
          openUrl(url);
        } else if (GetPlatform.isAndroid) {
          String url = "https://pub-35fb8e0d745944819b75af2768f58058.r2.dev/release/$version/xbb.apk";
          print(url);
          downloadApk(url);
        }
      } else {
        setCanUpdate(false);
        if (manually) {
          flushBar(FlushLevel.INFO, "已经是最新版本啦", "当前版本: $VERSION");
        }
        return;
      }
    });
  }
}

bool _shouldUpdate(String latestVersion) {
  if (VERSION == 'debug') {
    return true;
  }
  for (int i = 0; i < latestVersion.split('.').length; i++) {
    if (int.parse(latestVersion.split('.')[i]) > int.parse(VERSION.split('.')[i])) {
      return true;
    }
  }
  return false;
}

_getLatestVersionThen(void Function(String) onValue) {
  // getLatestVersion().then((value) {
  //   value.fold((version) {
  //     onValue(version);
  //   }, (error) {
  //     print('error: $error');
  //   });
  // });
}

class NewSettingController extends GetxController {
  final box = GetStorage(GET_STORAGE_FILE_KEY);

  @override
  Future onInit() async {
    print('new setting controller onInit');

    // load app setting from storage
    Map<String, dynamic>? app = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_SETTINGS_KEY);
    if (app != null) {
      appSetting.value = AppSetting.fromJson(app);
    }
    // load user info from storage
    Map<String, dynamic>? user = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INFO_KEY);
    if (user != null) {
      userInfo.value = UserInfo.fromJson(user);
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
  void updateAppSetting({ThemeMode? themeMode, double? fontScale, Locale? locale, ColorTag? colorTag}) {
    appSetting.update((setting) {
      setting?.update(themeMode: themeMode, fontScale: fontScale, locale: locale, colorTag: colorTag);
    });
    box.write(STORAGE_SETTING_APP_SETTINGS_KEY, appSetting.value.toJson());
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
}

// ignore: constant_identifier_names
const String APP_API_URI = 'http://127.0.0.1:1011/api';

class SyncStoreSetting {
  String baseUrl;
  bool enableHpke;

  get url => baseUrl;
  get hpkeEnabled => enableHpke;

  SyncStoreSetting({required this.baseUrl, required this.enableHpke});

  factory SyncStoreSetting.defaults() {
    return SyncStoreSetting(baseUrl: APP_API_URI, enableHpke: false);
  }

  Map<String, dynamic> toJson() {
    return {'base_url': baseUrl, 'enable_hpke': enableHpke};
  }

  factory SyncStoreSetting.fromJson(Map<String, dynamic> json) {
    return SyncStoreSetting(baseUrl: json['base_url'] ?? APP_API_URI, enableHpke: json['enable_hpke'] ?? false);
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

  get themeMode => _themeMode;
  get fontScale => _fontScale;
  get locale => _locale;
  get colorTag => _colorTag;

  AppSetting({
    required ThemeMode themeMode,
    required double fontScale,
    required Locale locale,
    required ColorTag colorTag,
  }) : _themeMode = themeMode,
       _fontScale = fontScale,
       _locale = locale,
       _colorTag = colorTag;

  factory AppSetting.defaults() {
    return AppSetting(themeMode: ThemeMode.system, fontScale: 1.0, locale: const Locale('en'), colorTag: ColorTag.none);
  }

  Map<String, dynamic> toJson() {
    return {
      'theme_mode': _themeMode.toString(),
      'font_scale': _fontScale,
      'locale': _locale.languageCode,
      'color_tag': _colorTag.toString(),
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
    return AppSetting(themeMode: themeMode, fontScale: fontScale, locale: locale, colorTag: colorTag);
  }

  void update({ThemeMode? themeMode, double? fontScale, Locale? locale, ColorTag? colorTag}) {
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
  }
}

class UserInfo {
  String _userId;
  String _userName;
  String _userPassword;

  get id => _userId;
  get name => _userName;
  get password => _userPassword;

  UserInfo({required String userId, required String userName, required String userPassword})
    : _userId = userId,
      _userName = userName,
      _userPassword = userPassword;

  factory UserInfo.unknown() {
    return UserInfo(userId: '', userName: '', userPassword: '');
  }

  Map<String, dynamic> toJson() {
    return {'user_id': _userId, 'user_name': _userName, 'user_password': _userPassword};
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(userId: json['user_id'], userName: json['user_name'], userPassword: json['user_password']);
  }

  void update({String? userId, String? userName, String? userPassword}) {
    if (userId != null) {
      _userId = userId;
    }
    if (userName != null) {
      _userName = userName;
    }
    if (userPassword != null) {
      _userPassword = userPassword;
    }
  }
}
