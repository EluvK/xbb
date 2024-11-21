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
Future<void> launchRepo() async {
  if (!await launchUrl(Uri.parse(REPO_URL))) {
    throw Exception('Could not launch $REPO_URL');
  }
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

void flushDiff(List<int> diff) {
  String diffStr = "add ${diff[0]}, update ${diff[1]}, delete ${diff[2]}";
  if (diff[0] < 0) {
    flushBar(FlushLevel.WARNING, "failed", "somethings went wrongs");
  } else {
    flushBar(FlushLevel.OK, "success", diffStr);
  }
}

// ignore: constant_identifier_names
enum FlushLevel { OK, INFO, WARNING }

void flushBar(
  FlushLevel level,
  String? title,
  String? message,
) {
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
  ).show(Get.context!);
}
