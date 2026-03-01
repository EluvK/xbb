import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ota_update/ota_update.dart';
import 'package:xbb/components/common/update.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/utils/utils.dart';

checkUpdate({bool forceCheck = false}) async {
  final SettingController settingController = Get.find<SettingController>();
  final lastCheckUpdate = settingController.appLastCheckedUpdateTime;

  print('lastCheckUpdate: $lastCheckUpdate, forceCheck: $forceCheck');

  if (!forceCheck &&
      lastCheckUpdate != null &&
      DateTime.now().difference(lastCheckUpdate) < const Duration(minutes: 30)) {
    print('Checking too frequently, skipping.');
    return;
  }

  final bool shouldFetchVersion = forceCheck || !settingController.appCanUpdate;
  if (!shouldFetchVersion) {
    print('Already aware of latest version, skipping fetch.');
    return;
  }

  if (settingController.isCheckingUpdate) {
    print('Update check already running, cancelling duplicate request.');
    return;
  }

  settingController.isCheckingUpdate = true;
  try {
    final SyncStoreControl syncStoreControl = Get.find<SyncStoreControl>();

    String version;
    String? releaseNotes;
    try {
      version = await syncStoreControl.fetchVersionInfo('xbb');
      try {
        releaseNotes = await syncStoreControl.fetchReleaseNotes('xbb');
      } catch (e) {
        print('Failed to fetch release notes: $e');
      }
    } catch (e) {
      print('Failed to fetch version info: $e');
      flushBar(FlushLevel.WARNING, 'Failed', '无法获取版本信息 $e');
      return;
    }
    final bool hasNewVersion = _shouldUpdate(version);

    settingController.updateAppSetting(canUpdate: hasNewVersion, lastCheckedUpdateTime: DateTime.now());

    showUpdateDialog(
      latestVersion: version,
      releaseNotes: releaseNotes,
      hasNewVersion: hasNewVersion,
      onUpdate: (bool nightly, bool throughProxy) =>
          _executeAppUpdate(settingController, version, nightly: nightly, throughProxy: throughProxy),
    );
  } finally {
    settingController.isCheckingUpdate = false;
  }
}

void _executeAppUpdate(
  SettingController settingController,
  String version, {
  bool nightly = false,
  bool throughProxy = false,
}) {
  // execute update
  final urlVersion = nightly ? 'master' : version;
  if (!throughProxy) {
    if (GetPlatform.isWindows) {
      String url = "${settingController.syncStoreUrl}/fs/public/xbb/$urlVersion/xbb_desktop_windows_setup.exe";
      openUrl(url);
    } else if (GetPlatform.isAndroid) {
      String url = "${settingController.syncStoreUrl}/fs/public/xbb/$urlVersion/xbb.apk";
      _downloadApk(url);
    }
  } else {
    if (GetPlatform.isWindows) {
      String url = "https://pub-35fb8e0d745944819b75af2768f58058.r2.dev/release/$urlVersion/xbb_desktop_windows_setup.exe";
      openUrl(url);
    } else if (GetPlatform.isAndroid) {
      String url = "https://pub-35fb8e0d745944819b75af2768f58058.r2.dev/release/$urlVersion/xbb.apk";
      Clipboard.setData(ClipboardData(text: url));
      flushBar(FlushLevel.OK, 'URL Copied', '下载链接已复制到剪贴板，请在浏览器中打开下载:\n$url');
    }
  }
}

bool _shouldUpdate(String latestVersion) {
  if (VERSION == 'DEBUG') {
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
