import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/trackers/tracker_card.dart';
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
  final TrackerRecordController recordController = Get.find<TrackerRecordController>();
  @override
  Widget build(BuildContext context) {
    // todo add more filter
    return Obx(() {
      RxList<TrackerDataItem> trackers = trackerController.registerFilterSubscription(
        filterKey: 'tracker-matrix',
        filters: [],
      );
      final Map<String, List<TrackerDataItem>> groupedTrackers = {};
      for (var t in trackers) {
        groupedTrackers.putIfAbsent(t.body.category, () => []).add(t);
      }
      // sort by category name
      final sortedKeys = groupedTrackers.keys.toList()..sort();
      final sortedGroupedTrackers = {for (var k in sortedKeys) k: groupedTrackers[k]!};
      return LayoutBuilder(
        builder: (context, constraints) {
          const double fixedHeight = 156.0;
          const double cardMaxWidth = 580.0;
          const double gridSpacing = 12.0;
          const double horizontalPadding = 24.0;

          int crossAxisCount = (constraints.maxWidth / (cardMaxWidth + gridSpacing)).floor();
          crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;

          double contentWidth = (crossAxisCount * cardMaxWidth) + ((crossAxisCount - 1) * gridSpacing);
          double sideMargin = 12.0;
          if (constraints.maxWidth > contentWidth + horizontalPadding) {
            sideMargin = (constraints.maxWidth - contentWidth) / 2;
          }

          final double availableWidth = constraints.maxWidth - (sideMargin * 2);
          final double itemWidth = (availableWidth - (crossAxisCount - 1) * gridSpacing) / crossAxisCount;
          final double dynamicAspectRatio = itemWidth / fixedHeight;

          return CustomScrollView(
            slivers: sortedGroupedTrackers.entries.map((entry) {
              final category = entry.key.isEmpty ? 'uncategorized'.tr : entry.key;
              final items = entry.value;

              return SliverMainAxisGroup(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin, vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        category,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: sideMargin),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: gridSpacing,
                        crossAxisSpacing: gridSpacing,
                        childAspectRatio: dynamicAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = items[index];
                        final records = Get.find<TrackerRecordController>().registerFilterSubscription(
                          filterKey: 'tracker-records-${item.id}',
                          filters: [ParentIdFilter(item.id)],
                        );
                        return TrackerCard(item: item, records: records);
                      }, childCount: items.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            }).toList(),
          );
        },
      );
    });
  }
}
