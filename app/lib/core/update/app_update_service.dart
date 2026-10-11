import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/utils/translation.dart';

/// 版本更新信息实体
class AppUpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String changelog;
  final String downloadUrl;

  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.changelog,
    required this.downloadUrl,
  });

  factory AppUpdateInfo.upToDate(String version) {
    return AppUpdateInfo(
      hasUpdate: false,
      currentVersion: version,
      latestVersion: version,
      changelog: '',
      downloadUrl: '',
    );
  }
}

/// 软件在线检测更新服务
class AppUpdateService {
  static const String currentVersion = '0.2.5+283';

  /// 版本对比算法：判断 latest 是否比 current 更高
  static bool isNewerVersion(String latest, String current) {
    String clean(String v) => v.trim().toLowerCase().replaceAll(RegExp(r'^v'), '');
    final l = clean(latest);
    final c = clean(current);
    if (l.isEmpty || c.isEmpty) return false;
    if (l == c) return false;

    final lParts = l.split('+');
    final cParts = c.split('+');

    final lSemver = lParts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cSemver = cParts[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (lSemver.length < 3) {
      lSemver.add(0);
    }
    while (cSemver.length < 3) {
      cSemver.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (lSemver[i] > cSemver[i]) return true;
      if (lSemver[i] < cSemver[i]) return false;
    }

    // 若 semver 相同，对比 build number
    if (lParts.length > 1 && cParts.length > 1) {
      final lBuild = int.tryParse(lParts[1]) ?? 0;
      final cBuild = int.tryParse(cParts[1]) ?? 0;
      return lBuild > cBuild;
    } else if (lParts.length > 1) {
      return true;
    }

    return false;
  }

  /// 请求远端静态文件并对比版本
  static Future<AppUpdateInfo> check({
    Dio? dio,
    String? baseUrl,
  }) async {
    final client = dio ?? ApiClient.instance.dio;
    final base = (baseUrl ?? ApiClient.instance.baseUrl).replaceAll(RegExp(r'/+$'), '');

    try {
      final versionRes = await client.get<String>(
        '$base/fs/public/xbb/version',
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      final latestVer = (versionRes.data ?? '').trim();
      if (latestVer.isEmpty) {
        return AppUpdateInfo.upToDate(currentVersion);
      }

      final hasUpdate = isNewerVersion(latestVer, currentVersion);
      String changelog = '';
      if (hasUpdate) {
        try {
          final changelogRes = await client.get<String>(
            '$base/fs/public/xbb/CHANGELOG',
            options: Options(
              responseType: ResponseType.plain,
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );
          changelog = (changelogRes.data ?? '').trim();
        } catch (_) {
          changelog = 'Latest update available.';
        }
      }

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestVer,
        changelog: changelog,
        downloadUrl: '$base/fs/public/xbb/download',
      );
    } catch (_) {
      return AppUpdateInfo.upToDate(currentVersion);
    }
  }

  /// 弹出更新弹窗
  static Future<void> showUpdateDialog(BuildContext context, AppUpdateInfo info) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update_alt_rounded, color: Colors.blue),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'update_dialog_title'.trParams({'version': info.latestVersion}),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ModernBadge(
                  label: 'current_version_label'.trParams({'version': info.currentVersion}),
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                ModernBadge(
                  label: 'latest_version_label'.trParams({'version': info.latestVersion}),
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (info.changelog.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    info.changelog,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('remind_later'.tr),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text('download_update_btn'.tr),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(info.downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// 全局更新状态
class AppUpdateState {
  final bool isChecking;
  final AppUpdateInfo? info;
  final DateTime? lastCheckedTime;

  const AppUpdateState({
    this.isChecking = false,
    this.info,
    this.lastCheckedTime,
  });

  AppUpdateState copyWith({
    bool? isChecking,
    AppUpdateInfo? info,
    DateTime? lastCheckedTime,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      info: info ?? this.info,
      lastCheckedTime: lastCheckedTime ?? this.lastCheckedTime,
    );
  }
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState());

  Future<AppUpdateInfo> checkUpdate({
    BuildContext? context,
    bool isManual = false,
  }) async {
    state = state.copyWith(isChecking: true);
    final info = await AppUpdateService.check();
    state = state.copyWith(
      isChecking: false,
      info: info,
      lastCheckedTime: DateTime.now(),
    );

    if (context != null && context.mounted) {
      if (info.hasUpdate) {
        AppUpdateService.showUpdateDialog(context, info);
      } else if (isManual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('already_latest_version'.tr)),
        );
      }
    }

    return info;
  }
}

final appUpdateProvider = StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
});
