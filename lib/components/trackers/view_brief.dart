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
          debugOnlyWidget(
            IconButton(
              onPressed: () {
                final trackerController = Get.find<TrackerController>();
                trackerController.clearLocal();
              },
              icon: const Icon(Icons.warning_amber),
            ),
          ),
          const Expanded(child: _ViewTrackerBriefByCategory()),
        ],
      ),
    );
  }
}

class _ViewTrackerBriefByCategory extends StatefulWidget {
  const _ViewTrackerBriefByCategory();

  @override
  State<_ViewTrackerBriefByCategory> createState() => __ViewTrackerBriefByCategoryState();
}

class __ViewTrackerBriefByCategoryState extends State<_ViewTrackerBriefByCategory> {
  final TrackerController trackerController = Get.find<TrackerController>();
  static const predefinedType = ['event', 'milestone', 'anniversary'];
  @override
  Widget build(BuildContext context) {
    final List<TrackerDataItem> trackers = trackerController.getTrackerDetails(selector: (t) => t);
    final Map<String, int> categoryCount = {for (var type in predefinedType) type: 0};
    for (var tracker in trackers) {
      final type = tracker.body.type;
      if (predefinedType.contains(type)) {
        categoryCount[type] = (categoryCount[type] ?? 0) + 1;
      }
    }
    // todo make it pretty?
    return ListView(
      children: predefinedType
          .map((type) => ListTile(title: Text(type.tr), trailing: Text(categoryCount[type].toString())))
          .toList(),
    );
  }
}
