import 'package:get/get.dart';
import 'package:ota_update/ota_update.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/utils/utils.dart';

checkUpdate({bool autoExecUpdate = false, bool forceCheck = false}) async {
  // delay a bit to avoid checking update too early before syncstore controller is ready
  await Future.delayed(const Duration(seconds: 3));
  final SettingController settingController = Get.find<SettingController>();
  final lastCheckUpdate = settingController.appLastCheckedUpdateTime;

  print('lastCheckUpdate: $lastCheckUpdate, forceCheck: $forceCheck');

  if (!forceCheck &&
      lastCheckUpdate != null &&
      DateTime.now().difference(lastCheckUpdate) < const Duration(minutes: 30)) {
    print('Checking too frequently, skipping.');
    return;
  }
  final SyncStoreControl syncStoreControl = Get.find<SyncStoreControl>();

  if (forceCheck || !settingController.appCanUpdate) {
    final version = await syncStoreControl.fetchVersionInfo('xbb');
    bool hasNewVersion = _shouldUpdate(version);

    settingController.updateAppSetting(canUpdate: hasNewVersion, lastCheckedUpdateTime: DateTime.now());

    if (hasNewVersion) {
      flushBar(FlushLevel.INFO, "有新版本啦！", "当前版本: $VERSION, 最新版本: $version");
    } else {
      print('No update needed.');
      return;
    }
  }

  if (!autoExecUpdate) {
    await Future.delayed(const Duration(seconds: 2));
    flushBar(FlushLevel.INFO, "记得更新新版本", "请前往设置页面更新");

    settingController.updateAppSetting(lastCheckedUpdateTime: DateTime.now());
    return;
  }

  if (GetPlatform.isWindows) {
    String url = "${settingController.syncStoreUrl}/fs/public/xbb/master/xbb_desktop_windows_setup.exe";
    openUrl(url);
  } else if (GetPlatform.isAndroid) {
    String url = "${settingController.syncStoreUrl}/fs/public/xbb/master/xbb.apk";
    _downloadApk(url);
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

void _downloadApk(String url) {
  final settingController = Get.find<SettingController>();
  try {
    OtaUpdate().execute(url, destinationFilename: "xbb.apk").listen((event) {
      print('event: $event');
      print('status: ${event.status}, value: ${event.value}');
      if (event.status == OtaStatus.DOWNLOADING) {
        settingController.downloadProgress.value = double.parse(event.value ?? '0') / 100;
      } else if (event.status == OtaStatus.DOWNLOAD_ERROR) {
        flushBar(FlushLevel.WARNING, 'Failed', event.value);
      } else if (event.status == OtaStatus.INSTALLING) {
        settingController.downloadProgress.value = 0.0;
        flushBar(FlushLevel.OK, 'Success', 'Download success');
      }
    });
  } catch (e) {
    print('Failed to make OTA update. Details: $e');
    flushBar(FlushLevel.WARNING, 'Failed', 'Failed to make OTA update $e');
  }
}
