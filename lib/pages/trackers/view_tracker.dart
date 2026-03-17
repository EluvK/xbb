import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/components/trackers/tracker_card.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/time_picker.dart';
import 'package:xbb/utils/utils.dart';
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
  DateTime _recordTimestamp = DateTime.now().toUtc();
  bool _anniversaryPreview = false;
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
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          TextViewWidget(title: const _LocalTitle('Category', Icons.category, Colors.blue), value: t.category),
          TextViewWidget(
            title: const _LocalTitle('Description', Icons.description, Colors.orange),
            value: t.description,
          ),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          // "记一笔" button and in-page form
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _showAdd = !_showAdd;
                if (_showAdd) {
                  _recordTimestamp = DateTime.now().toUtc();
                  _anniversaryPreview = false;
                }
              });
            },
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
          const SizedBox(height: 6),
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
    final cfg = tracker.body.config;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cfg.map(
            event: (c) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TimePickerWidget(
                    label: '发生时间',
                    icon: Icons.schedule,
                    color: Colors.indigo,
                    pickerType: DateTimePickerType.datetime,
                    initialValue: _recordTimestamp.toLocal(),
                    onChange: (v) {
                      _recordTimestamp = v;
                    },
                  ),
                ],
              );
            },
            milestone: (c) {
              if (c.goalType == 'boolean') {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('当前版本暂不支持 milestone(boolean) 记录录入', style: Theme.of(context).textTheme.bodySmall),
                );
              }
              if (c.goalType == 'time') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('15 分钟'),
                          onPressed: () {
                            _valueController.text = '15';
                            setState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('30 分钟'),
                          onPressed: () {
                            setState(() {});
                            _valueController.text = '30';
                          },
                        ),
                        ActionChip(
                          label: const Text('60 分钟'),
                          onPressed: () {
                            _valueController.text = '60';
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextInputWidget(
                      title: const _LocalTitle('时长(分钟)', Icons.timer_outlined, Colors.purple),
                      initialValue: _valueController.text,
                      onFinished: (v) => _valueController.text = v,
                      inputType: const TextInputType.numberWithOptions(decimal: false),
                    ),
                  ],
                );
              }
              return TextInputWidget(
                title: const _LocalTitle('数值贡献', Icons.numbers, Colors.purple),
                initialValue: _valueController.text,
                onFinished: (v) => _valueController.text = v,
                inputType: const TextInputType.numberWithOptions(decimal: true),
              );
            },
            anniversary: (c) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TimePickerWidget(
                  label: '记录时间',
                  icon: Icons.schedule,
                  color: Colors.indigo,
                  pickerType: DateTimePickerType.datetime,
                  initialValue: _recordTimestamp.toLocal(),
                  onChange: (v) {
                    _recordTimestamp = v;
                  },
                ),
                const SizedBox(height: 6),
                UserDefinedInputWidget(
                  title: const _LocalTitle('纪念内容', Icons.edit, Colors.blue),
                  widget: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _anniversaryPreview = !_anniversaryPreview;
                      });
                    },
                    icon: Icon(_anniversaryPreview ? Icons.edit_note : Icons.preview_outlined, size: 16),
                    label: Text(_anniversaryPreview ? 'Write' : 'Preview'),
                  ),
                ),
                const SizedBox(height: 6),
                if (!_anniversaryPreview)
                  TextField(
                    controller: _contentController,
                    minLines: 4,
                    maxLines: 8,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: '支持 Markdown，记录当下发生了什么、你的感受或想法...',
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: _contentController.text.trim().isEmpty
                        ? Text('暂无内容可预览', style: Theme.of(context).textTheme.bodySmall)
                        : SimpleMarkdownRenderer(data: _contentController.text),
                  ),
              ],
            ),
          ),
          if (cfg is! AnniversaryTrackerConfig) ...[
            const SizedBox(height: 6),
            TextInputWidget(
              title: const _LocalTitle('备注', Icons.description, Colors.grey),
              initialValue: _contentController.text,
              onFinished: (v) => _contentController.text = v,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final now = DateTime.now().toUtc();
                  final cfg2 = tracker.body.config;
                  TrackerRecord rec;

                  if (cfg2 is AnniversaryTrackerConfig) {
                    final content = _contentController.text.trim();
                    if (content.isEmpty) {
                      Get.snackbar('输入错误', '纪念内容不能为空');
                      return;
                    }
                    rec = TrackerRecord.forAnniversary(
                      trackerId: tracker.id,
                      timestamp: _recordTimestamp,
                      content: content,
                    );
                  } else if (cfg2 is EventTrackerConfig) {
                    rec = TrackerRecord.forEvent(
                      trackerId: tracker.id,
                      timestamp: _recordTimestamp,
                      content: _contentController.text.trim(),
                    );
                  } else if (cfg2 is MilestoneTrackerConfig) {
                    if (cfg2.goalType == 'boolean') {
                      Get.snackbar('提示', '当前版本暂不支持该类型记录录入');
                      return;
                    } else if (cfg2.goalType == 'time') {
                      final input = _valueController.text.trim();
                      final minutes = int.tryParse(input);
                      if (minutes == null || minutes <= 0) {
                        Get.snackbar('输入错误', '时长必须是大于 0 的整数分钟');
                        return;
                      }
                      rec = TrackerRecord.forMilestoneTime(
                        trackerId: tracker.id,
                        timestamp: now,
                        minutes: minutes,
                        content: _contentController.text.trim(),
                      );
                    } else {
                      final input = _valueController.text.trim();
                      final parsed = double.tryParse(input);
                      if (parsed == null) {
                        Get.snackbar('输入错误', '请输入有效数值');
                        return;
                      }
                      rec = TrackerRecord.forMilestoneNumber(
                        trackerId: tracker.id,
                        timestamp: now,
                        number: input,
                        content: _contentController.text.trim(),
                      );
                    }
                  } else {
                    rec = TrackerRecord(trackerId: tracker.id, timestamp: now, content: _contentController.text.trim());
                  }

                  recordController.addData(rec);
                  setState(() {
                    _showAdd = false;
                    _recordTimestamp = DateTime.now().toUtc();
                    _anniversaryPreview = false;
                    _valueController.clear();
                    _contentController.clear();
                  });
                  trackerController.rebuildLocal();
                },
                child: const Text('Add'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _showAdd = false;
                    _recordTimestamp = DateTime.now().toUtc();
                    _anniversaryPreview = false;
                    _valueController.clear();
                    _contentController.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
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

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime dt) => '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}';

  String _formatTime(DateTime dt) => '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';

  @override
  Widget build(BuildContext context) {
    final List<TrackerRecord> sortedRecords = List.from(records)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: sortedRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (ctx, gi) {
        final record = sortedRecords[gi];
        final localTime = record.timestamp.toLocal();
        final dateLabel = _formatDate(localTime);
        final timeLabel = _formatTime(localTime);
        final relativeLabel = readableDateStr(localTime);
        final isFirst = gi == 0;
        final isLast = gi == sortedRecords.length - 1;
        return TimelineTile(
          alignment: TimelineAlign.start,
          lineXY: 0.08,
          isFirst: isFirst,
          isLast: isLast,
          beforeLineStyle: LineStyle(color: colorScheme.outlineVariant.withValues(alpha: 0.45), thickness: 2),
          afterLineStyle: LineStyle(color: colorScheme.outlineVariant.withValues(alpha: 0.45), thickness: 2),
          indicatorStyle: IndicatorStyle(
            width: 20,
            height: 20,
            color: Colors.transparent,
            indicator: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.12),
                border: Border.all(color: colorScheme.primary, width: 1.4),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          endChild: Padding(
            padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          relativeLabel,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  if (record.content != null && record.content!.isNotEmpty)
                    Text(record.content!, style: Theme.of(context).textTheme.bodyMedium),
                  if (record.value != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.tertiaryContainer.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.value!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
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
