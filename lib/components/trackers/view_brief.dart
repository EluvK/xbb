import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/utils.dart';
import 'package:xbb/models/tracker/model.dart';

class ViewTrackerBrief extends StatelessWidget {
  const ViewTrackerBrief({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () async {
                  await onReadySyncTracker();
                },
                icon: const Icon(Icons.refresh),
              ),
              debugOnlyWidget(
                IconButton(
                  onPressed: () {
                    final trackerController = Get.find<TrackerController>();
                    trackerController.clearLocal();
                  },
                  icon: const Icon(Icons.warning_amber),
                ),
              ),
            ],
          ),
          const Expanded(child: _ViewTrackerBriefByCategory()),
        ],
      ),
    );
  }
}

class _ViewTrackerBriefByCategory extends StatelessWidget {
  const _ViewTrackerBriefByCategory();

  static const predefinedType = ['event', 'milestone', 'anniversary'];

  @override
  Widget build(BuildContext context) {
    final trackerController = Get.find<TrackerController>();
    return Obx(() {
      final trackers = trackerController.getTrackerDetails(selector: (t) => t);
      final categoryCount = {for (final type in predefinedType) type: 0};
      for (final tracker in trackers) {
        final type = tracker.body.type;
        if (predefinedType.contains(type)) {
          categoryCount[type] = (categoryCount[type] ?? 0) + 1;
        }
      }

      return ListView.builder(
        itemCount: predefinedType.length,
        itemBuilder: (context, index) {
          final type = predefinedType[index];
          return ListTile(title: Text(type.tr), trailing: Text((categoryCount[type] ?? 0).toString()));
        },
      );
    });
  }
}
