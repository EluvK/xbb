import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ignore: constant_identifier_names
const String VERSION =
    String.fromEnvironment('APP_VERSION', defaultValue: 'debug');

// ignore: constant_identifier_names
const String APP_BUILD_NUMBER =
    String.fromEnvironment('APP_BUILD_NUMBER', defaultValue: '0');

// ignore: constant_identifier_names
const String REPO_URL = 'https://github.com/eluvk/xbb/releases';
Future<void> openUrl(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    throw Exception('Could not launch $url');
  }
}

bool isMobile() {
  return GetPlatform.isMobile || Get.width < 600;
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

void flushBar(FlushLevel level, String? title, String? message,
    {bool upperPosition = false}) {
  Color? color;
  IconData? icon;
  switch (level) {
    case FlushLevel.OK:
      color = Colors.green.shade300;
      icon = Icons.check_box_sharp;
      break;
    case FlushLevel.INFO:
      color = Colors.blue.shade300;
      icon = Icons.info_outline;
      break;
    case FlushLevel.WARNING:
      color = Colors.orange.shade300;
      icon = Icons.error_outline;
      break;
  }
  Flushbar(
    title: title,
    message: message,
    duration: const Duration(seconds: 2),
    icon: Icon(icon, size: 28, color: color),
    margin: const EdgeInsets.all(12.0),
    borderRadius: BorderRadius.circular(8.0),
    leftBarIndicatorColor: color,
    flushbarPosition:
        upperPosition ? FlushbarPosition.TOP : FlushbarPosition.BOTTOM,
  ).show(Get.context!);
}

Future<bool?> showBackCheckDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('back_check_title'.tr),
        content: Text(
          'back_check_content'.tr,
        ),
        actions: <Widget>[
          TextButton(
            child: Text('back_check_cancel'.tr),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            // style: TextButton.styleFrom(
            //   textStyle: Theme.of(context).textTheme.labelLarge,
            // ),
            child: Text(
              'back_check_confirm'.tr,
              style: TextStyle(color: Colors.red[400]),
            ),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      );
    },
  );
}
