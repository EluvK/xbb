import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/trackers/tracker_editor.dart';
import 'package:xbb/models/tracker/model.dart';

class EditTrackerPage extends StatelessWidget {
  const EditTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final TrackerDataItem? tracker = args?[0];
    if (tracker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Tracker')),
        body: const TrackerEditor(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Tracker')),
      body: TrackerEditor(trackerItem: tracker),
    );
  }
}
