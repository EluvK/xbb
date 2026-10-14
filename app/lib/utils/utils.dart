import 'package:flutter/material.dart';
import 'package:xbb/core/core.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

const String debugVersionLiteral = 'DEBUG';

// ignore: constant_identifier_names
const String VERSION = String.fromEnvironment('APP_VERSION', defaultValue: debugVersionLiteral);

// ignore: constant_identifier_names
const String APP_BUILD_NUMBER = String.fromEnvironment('APP_BUILD_NUMBER', defaultValue: '0');

// ignore: constant_identifier_names
const String APP_CHANNEL = String.fromEnvironment('APP_CHANNEL', defaultValue: 'debug');

// ignore: constant_identifier_names
const String APP_BUILD_DATE = String.fromEnvironment('APP_BUILD_DATE', defaultValue: '');

/// Full display version: `0.2.2` for stable, `0.2.2-nightly-20250428` for nightly, `DEBUG` in debug.
// ignore: non_constant_identifier_names
final String DISPLAY_VERSION = () {
  if (VERSION == debugVersionLiteral) return VERSION;
  if (APP_CHANNEL == 'nightly' && APP_BUILD_DATE.isNotEmpty) {
    return '$VERSION-nightly-$APP_BUILD_DATE';
  }
  return VERSION;
}();

// ignore: constant_identifier_names
const String REPO_URL = 'https://github.com/eluvk/xbb/releases';
Future<void> openUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}

bool isMobile() {
  return AppPlatform.isMobile;
}

String sharedLink(String owner, String id) {
  return "xbb-share://$owner/$id";
}

String readableDateStr(DateTime dt) {
  return GetTimeAgo.parse(dt.toLocal());
}

String detailedDateStr(DateTime dt) {
  return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt.toLocal());
}

// void flushDiff(String title, List<int> diff) {
//   String diffStr = "";
//   if (diff[0] > 0) {
//     diffStr = '$diffStr${'update_result_new_posts_cnt'.trParams({
//           'count': diff[0].toString()
//         })}\n';
//   }
//   if (diff[1] > 0) {
//     diffStr = "$diffStr${'update_result_update_posts_cnt'.trParams({
//           'count': diff[1].toString()
//         })}\n";
//   }
//   if (diff[2] > 0) {
//     diffStr = "$diffStr${'update_result_delete_posts_cnt'.trParams({
//           'count': diff[2].toString()
//         })}\n";
//   }
//   if (diff[3] > 0) {
//     diffStr = "$diffStr${'update_result_update_comments_cnt'.trParams({
//           'count': diff[3].toString()
//         })}\n";
//   }
//   if (diffStr == "") {
//     diffStr = "update_result_nothing".tr;
//   }

//   if (diff[0] < 0) {
//     flushBar(FlushLevel.WARNING, "update_failed".tr, "somethings went wrongs");
//   } else {
//     flushBar(FlushLevel.OK, title, diffStr);
//   }
// }

// ignore: constant_identifier_names
enum FlushLevel { OK, INFO, WARNING }

void successSimpleFlushBar(String message) {
  flushBar(FlushLevel.OK, null, message, upperPosition: true, duration: const Duration(seconds: 1));
}

void flushBar(
  FlushLevel level,
  String? title,
  String? message, {
  bool upperPosition = false,
  Duration duration = const Duration(seconds: 2),
}) {
  print('[$level] $title: $message');
}

Future<bool?> showBackCheckDialog(BuildContext context) {
  return showAdaptiveConfirmDialog(
    context,
    title: 'back_check_title'.tr,
    message: 'back_check_content'.tr,
    cancelText: 'back_check_cancel'.tr,
    confirmText: 'back_check_confirm'.tr,
    isDanger: true,
  );
}
