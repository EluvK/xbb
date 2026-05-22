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
  static const String _trackerFilterKey = 'tracker-matrix';

  final TrackerController trackerController = Get.find<TrackerController>();
  final TrackerRecordController recordController = Get.find<TrackerRecordController>();
  final SettingController settingController = Get.find<SettingController>();

  late RxList<TrackerDataItem> _trackers;
  Worker? _settingWorker;

  @override
  void initState() {
    super.initState();
    _trackers = _registerTrackerSubscription();
    _settingWorker = ever(settingController.appSetting, (_) {
      if (!mounted) return;
      setState(() {
        _trackers = _registerTrackerSubscription();
      });
    });
  }

  RxList<TrackerDataItem> _registerTrackerSubscription() {
    trackerController.unregisterFilterSubscription(_trackerFilterKey);
    return trackerController.registerFilterSubscription(
      filterKey: _trackerFilterKey,
      filters: [ColorTagFilter.fromColorTag(settingController.colorTag)],
    );
  }

  @override
  void dispose() {
    _settingWorker?.dispose();
    trackerController.unregisterFilterSubscription(_trackerFilterKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Map<String, List<TrackerDataItem>> groupedTrackers = {};
      for (final t in _trackers) {
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
                            children: items
                                .map(
                                  (item) => _TrackerRecordCard(
                                    key: ValueKey('tracker-record-card-${item.id}'),
                                    item: item,
                                    cardWidth: cardWidth,
                                    recordController: recordController,
                                  ),
                                )
                                .toList(),
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

class _TrackerRecordCard extends StatefulWidget {
  const _TrackerRecordCard({super.key, required this.item, required this.cardWidth, required this.recordController});

  final TrackerDataItem item;
  final double cardWidth;
  final TrackerRecordController recordController;

  @override
  State<_TrackerRecordCard> createState() => _TrackerRecordCardState();
}

class _TrackerRecordCardState extends State<_TrackerRecordCard> {
  static const String _recordFilterPrefix = 'tracker-records-';

  late String _recordFilterKey;
  late RxList<TrackerRecordDataItem> _records;

  @override
  void initState() {
    super.initState();
    _recordFilterKey = '$_recordFilterPrefix${widget.item.id}';
    _records = widget.recordController.registerFilterSubscription(
      filterKey: _recordFilterKey,
      filters: [ParentIdFilter(widget.item.id)],
    );
  }

  @override
  void didUpdateWidget(covariant _TrackerRecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id == widget.item.id) return;

    widget.recordController.unregisterFilterSubscription(_recordFilterKey);
    _recordFilterKey = '$_recordFilterPrefix${widget.item.id}';
    _records = widget.recordController.registerFilterSubscription(
      filterKey: _recordFilterKey,
      filters: [ParentIdFilter(widget.item.id)],
    );
  }

  @override
  void dispose() {
    widget.recordController.unregisterFilterSubscription(_recordFilterKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.cardWidth,
      child: TrackerCard(item: widget.item, records: _records),
    );
  }
}
