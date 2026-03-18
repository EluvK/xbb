import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/trackers/tracker_card.dart';
import 'package:xbb/controller/setting.dart';
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
  final SettingController settingController = Get.find<SettingController>();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      List<DataItemFilter> filters = [ColorTagFilter.fromColorTag(settingController.colorTag)];
      RxList<TrackerDataItem> trackers = trackerController.registerFilterSubscription(
        filterKey: 'tracker-matrix',
        filters: filters,
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
          const double cardMaxWidth = 640.0;
          const double cardMinWidth = 340.0;
          const double cardSpacing = 12.0;
          const double pagePadding = 12.0;

          final double contentMaxWidth = (constraints.maxWidth - pagePadding * 2).clamp(0.0, double.infinity);
          int columns = ((contentMaxWidth + cardSpacing) / (cardMinWidth + cardSpacing)).floor();
          if (columns < 1) columns = 1;

          final double widthByColumns = (contentMaxWidth - (columns - 1) * cardSpacing) / columns;
          final double cardWidth = widthByColumns.clamp(0.0, cardMaxWidth);
          final double usedContentWidth = (cardWidth * columns) + ((columns - 1) * cardSpacing);

          return CustomScrollView(
            slivers: sortedGroupedTrackers.entries.map((entry) {
              final category = entry.key.isEmpty ? 'uncategorized'.tr : entry.key;
              final items = entry.value;

              return SliverMainAxisGroup(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: pagePadding, vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: usedContentWidth,
                          child: Text(
                            category,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: pagePadding),
                    sliver: SliverToBoxAdapter(
                      child: Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: usedContentWidth,
                          child: Wrap(
                            spacing: cardSpacing,
                            runSpacing: cardSpacing,
                            children: items.map((item) {
                              final records = recordController.registerFilterSubscription(
                                filterKey: 'tracker-records-${item.id}',
                                filters: [ParentIdFilter(item.id)],
                              );
                              return SizedBox(
                                width: cardWidth,
                                child: TrackerCard(item: item, records: records),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
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
