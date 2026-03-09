import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/tracker/model.dart';

class ViewTracker extends StatelessWidget {
  const ViewTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed('/tracker/edit-tracker', arguments: [null]);
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: const TrackerMatrix(),
      ),
    );
  }
}

class TrackerMatrix extends StatefulWidget {
  const TrackerMatrix({super.key});

  @override
  State<TrackerMatrix> createState() => _TrackerMatrixState();
}

class _TrackerMatrixState extends State<TrackerMatrix> {
  final TrackerController trackerController = Get.find<TrackerController>();
  @override
  Widget build(BuildContext context) {
    final List<TrackerDataItem> trackers = trackerController.getTrackerDetails(selector: (t) => t);
    return ListView(
      children: trackers
          .map((tracker) => ListTile(title: Text(tracker.body.name), subtitle: Text('Type: ${tracker.body.type}')))
          .toList(),
    );
  }
}
