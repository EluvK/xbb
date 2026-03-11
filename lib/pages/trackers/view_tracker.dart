import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/trackers/tracker_card.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/view_widget.dart';

class ViewTrackerDetailPage extends StatelessWidget {
  const ViewTrackerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final TrackerDataItem? tracker = args?[0];
    if (tracker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('panic')),
        body: const Text("No tracker selected, should pass tracker here."),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tracker.body.name)),
      body: ViewTrackerDetail(trackerItem: tracker),
    );
  }
}

class ViewTrackerDetail extends StatefulWidget {
  const ViewTrackerDetail({super.key, required this.trackerItem});
  final TrackerDataItem trackerItem;

  @override
  State<ViewTrackerDetail> createState() => _ViewTrackerDetailState();
}

class _ViewTrackerDetailState extends State<ViewTrackerDetail> {
  late final TrackerController trackerController;
  late final TrackerRecordController recordController;
  late final RxList<TrackerRecordDataItem> recordsRx;

  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _showAdd = false;

  @override
  void initState() {
    super.initState();
    trackerController = Get.find<TrackerController>();
    recordController = Get.find<TrackerRecordController>();
    recordsRx = recordController.registerFilterSubscription(
      filterKey: 'tracker-records-for-view${widget.trackerItem.id}',
      filters: [ParentIdFilter(widget.trackerItem.id)],
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _contentController.dispose();
    recordController.unregisterFilterSubscription('tracker-records-for-view${widget.trackerItem.id}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trackerItem.body;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrackerCard(item: widget.trackerItem, records: recordsRx),
          TextViewWidget(title: const _LocalTitle('Category', Icons.category, Colors.blue), value: t.category),
          TextViewWidget(
            title: const _LocalTitle('Description', Icons.description, Colors.orange),
            value: t.description,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          // "记一笔" button and in-page form
          ElevatedButton.icon(
            onPressed: () => setState(() => _showAdd = !_showAdd),
            label: Text(_showAdd ? '取消' : '记一笔'),
            icon: const Icon(Icons.draw_rounded),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _newRecordInputWidget(),
            crossFadeState: _showAdd ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              final list = recordsRx;
              if (list.isEmpty) return const Center(child: Text('No records yet'));
              // render timeline grouped by date
              final items = list.map((e) => e.body).toList();
              return _RecordsTimeline(records: items);
            }),
          ),
        ],
      ),
    );
  }

  Widget _newRecordInputWidget() {
    final tracker = widget.trackerItem;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          // value input depends on config
          tracker.body.config.map(
            event: (c) {
              return TextInputWidget(
                title: const _LocalTitle('Value', Icons.numbers, Colors.purple),
                initialValue: _valueController.text,
                onFinished: (v) => _valueController.text = v,
                inputType: const TextInputType.numberWithOptions(decimal: true),
              );
            },
            milestone: (c) => TextInputWidget(
              title: const _LocalTitle('Value', Icons.numbers, Colors.purple),
              initialValue: _valueController.text,
              onFinished: (v) => _valueController.text = v,
              inputType: const TextInputType.numberWithOptions(decimal: true),
            ),
            anniversary: (c) => TextInputWidget(
              title: const _LocalTitle('Note', Icons.note, Colors.blueGrey),
              initialValue: _valueController.text,
              onFinished: (v) => _valueController.text = v,
            ),
          ),
          const SizedBox(height: 6),
          TextInputWidget(
            title: const _LocalTitle('Note', Icons.description, Colors.grey),
            initialValue: _contentController.text,
            onFinished: (v) => _contentController.text = v,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final now = DateTime.now().toUtc();
                  String? val = _valueController.text.trim();
                  final cfg2 = tracker.body.config;
                  if (cfg2 is AnniversaryTrackerConfig) val = null;
                  final rec = TrackerRecord(
                    trackerId: tracker.id,
                    timestamp: now,
                    value: val,
                    content: _contentController.text.trim(),
                  );
                  recordController.addData(rec);
                  setState(() {
                    _showAdd = false;
                    _valueController.clear();
                    _contentController.clear();
                  });
                  trackerController.rebuildLocal();
                },
                child: const Text('Add'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(onPressed: () => setState(() => _showAdd = false), child: const Text('Cancel')),
            ],
          ),
        ],
      ),
    );
  }
}

// simple local title for input widgets
class _LocalTitle implements TitleInterface {
  const _LocalTitle(this._title, this._icon, this._color);
  final String _title;
  final IconData _icon;
  final Color _color;

  @override
  Color get gColor => _color;

  @override
  IconData get gIcon => _icon;

  @override
  String get gTitle => _title;
}

class _RecordsTimeline extends StatelessWidget {
  const _RecordsTimeline({required this.records});
  final List<TrackerRecord> records;
  @override
  Widget build(BuildContext context) {
    final List<TrackerRecord> sortedRecords = List.from(records)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    print("[Timeline] Sorted ${sortedRecords.length} records for display");
    return ListView.builder(
      itemCount: sortedRecords.length,
      itemBuilder: (ctx, gi) {
        final record = sortedRecords[gi];
        final dateLabel =
            '${record.timestamp.year}-${record.timestamp.month.toString().padLeft(2, '0')}-${record.timestamp.day.toString().padLeft(2, '0')}';
        final isFirst = gi == 0;
        final isLast = gi == sortedRecords.length - 1;
        return TimelineTile(
          alignment: TimelineAlign.start,
          isFirst: isFirst,
          isLast: isLast,
          indicatorStyle: IndicatorStyle(
            width: 12,
            height: 12,
            color: Theme.of(context).colorScheme.primary,
            indicator: Container(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            ),
          ),
          endChild: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateLabel, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  if (record.content != null && record.content!.isNotEmpty)
                    Text(record.content!, style: Theme.of(context).textTheme.bodyMedium),
                  if (record.value != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      record.value!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
