import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/common/permission.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/components/trackers/tracker_card.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/time_picker.dart';
import 'package:xbb/utils/utils.dart';
import 'package:xbb/utils/view_widget.dart';

TrackerRecord? _buildTrackerRecordFromInput({
  required TrackerConfig config,
  required String trackerId,
  required DateTime timestamp,
  required String rawValue,
  required String rawContent,
  required bool milestoneBooleanValue,
  required bool allowMilestoneBoolean,
}) {
  final content = rawContent.trim();
  final value = rawValue.trim();

  if (config is AnniversaryTrackerConfig) {
    if (content.isEmpty) {
      Get.snackbar('tracker_input_error_title'.tr, 'tracker_anniversary_content_required'.tr);
      return null;
    }
    return TrackerRecord.forAnniversary(trackerId: trackerId, timestamp: timestamp, content: content);
  }

  if (config is EventTrackerConfig) {
    return TrackerRecord.forEvent(
      trackerId: trackerId,
      timestamp: timestamp,
      content: content.isEmpty ? null : content,
    );
  }

  if (config is MilestoneTrackerConfig) {
    if (config.goalType == 'boolean') {
      if (!allowMilestoneBoolean) {
        Get.snackbar('tracker_tip_title'.tr, 'tracker_milestone_boolean_disabled'.tr);
        return null;
      }
      return TrackerRecord.forMilestoneBoolean(
        trackerId: trackerId,
        timestamp: timestamp,
        done: milestoneBooleanValue,
        content: content.isEmpty ? null : content,
      );
    }
    if (config.goalType == 'time') {
      final minutes = int.tryParse(value);
      if (minutes == null || minutes <= 0) {
        Get.snackbar('tracker_input_error_title'.tr, 'tracker_duration_minutes_error'.tr);
        return null;
      }
      return TrackerRecord.forMilestoneTime(
        trackerId: trackerId,
        timestamp: timestamp,
        minutes: minutes,
        content: content.isEmpty ? null : content,
      );
    }
    if (double.tryParse(value) == null) {
      Get.snackbar('tracker_input_error_title'.tr, 'tracker_numeric_error'.tr);
      return null;
    }
    return TrackerRecord.forMilestoneNumber(
      trackerId: trackerId,
      timestamp: timestamp,
      number: value,
      content: content.isEmpty ? null : content,
    );
  }

  return TrackerRecord(
    trackerId: trackerId,
    timestamp: timestamp,
    value: value.isEmpty ? null : value,
    content: content.isEmpty ? null : content,
  );
}

class ViewTrackerDetailPage extends StatelessWidget {
  const ViewTrackerDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final TrackerDataItem? tracker = args?[0];
    if (tracker == null) {
      return Scaffold(
        appBar: AppBar(title: Text('tracker_panic'.tr)),
        body: Text('tracker_no_selection'.tr),
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
  bool _milestoneBooleanValue = false;
  bool _showAdd = false;
  TrackerRecordDataItem? _editingRecord;

  bool get _isEditingRecord => _editingRecord != null;

  void _resetRecordInputState() {
    _showAdd = false;
    _editingRecord = null;
    _recordTimestamp = DateTime.now().toUtc();
    _anniversaryPreview = false;
    _milestoneBooleanValue = false;
    _valueController.clear();
    _contentController.clear();
  }

  void _startInlineEditRecord(TrackerRecordDataItem item) {
    setState(() {
      _showAdd = true;
      _editingRecord = item;
      _recordTimestamp = item.body.timestamp.toUtc();
      _anniversaryPreview = false;
      _valueController.text = item.body.value ?? '';
      _contentController.text = item.body.content ?? '';
      _milestoneBooleanValue = (item.body.value ?? '').toLowerCase() == 'true';
    });
  }

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
    final cachedAcl = trackerController.getAclCached(widget.trackerItem.id);
    final bool canEdit = oncePermissionCheck(
      TrackerFeatureRequires.update,
      widget.trackerItem.owner,
      cachedAcl,
      widget.trackerItem.owner,
    );
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrackerCard(item: widget.trackerItem, records: recordsRx),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          TextViewWidget(title: _LocalTitle('tracker_category'.tr, Icons.category, Colors.blue), value: t.category),
          TextViewWidget(
            title: _LocalTitle('tracker_description'.tr, Icons.description, Colors.orange),
            value: t.description,
          ),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          // "记一笔" button and in-page form
          if (canEdit)
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showAdd = !_showAdd;
                  if (_showAdd) {
                    _editingRecord = null;
                    _recordTimestamp = DateTime.now().toUtc();
                    _anniversaryPreview = false;
                    _milestoneBooleanValue = false;
                    _valueController.clear();
                    _contentController.clear();
                  }
                });
              },
              label: Text(_showAdd ? 'cancel'.tr : (_isEditingRecord ? 'tracker_edit_record'.tr : 'tracker_add_record'.tr)),
              icon: const Icon(Icons.draw_rounded),
            ),
          if (_showAdd && _isEditingRecord)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'tracker_edit_record'.tr,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
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
              if (list.isEmpty) return Center(child: Text('tracker_no_records'.tr));
              // render timeline grouped by date
              final items = list.map((e) => e).toList();
              return _RecordsTimeline(records: items, canEdit: canEdit, onEditRecord: _startInlineEditRecord);
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
                    label: 'tracker_record_time'.tr,
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
              final timePicker = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TimePickerWidget(
                    label: 'tracker_record_time'.tr,
                    icon: Icons.schedule,
                    color: Colors.indigo,
                    pickerType: DateTimePickerType.datetime,
                    initialValue: _recordTimestamp.toLocal(),
                    onChange: (v) {
                      _recordTimestamp = v;
                    },
                  ),
                  const SizedBox(height: 6),
                ],
              );

              if (c.goalType == 'boolean') {
                if (!_isEditingRecord) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      timePicker,
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'tracker_milestone_boolean_disabled'.tr,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timePicker,
                    Row(
                      children: [
                        Expanded(child: Text('tracker_target_value'.trParams({'value': c.targetValue}))),
                        Switch(
                          value: _milestoneBooleanValue,
                          onChanged: (v) {
                            setState(() {
                              _milestoneBooleanValue = v;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }
              if (c.goalType == 'time') {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timePicker,
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: Text('tracker_minutes_quick'.trParams({'minutes': '15'})),
                          onPressed: () {
                            _valueController.text = '15';
                            setState(() {});
                          },
                        ),
                        ActionChip(
                          label: Text('tracker_minutes_quick'.trParams({'minutes': '30'})),
                          onPressed: () {
                            setState(() {});
                            _valueController.text = '30';
                          },
                        ),
                        ActionChip(
                          label: Text('tracker_minutes_quick'.trParams({'minutes': '60'})),
                          onPressed: () {
                            _valueController.text = '60';
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextInputWidget(
                      title: _LocalTitle('tracker_duration_minutes'.tr, Icons.timer_outlined, Colors.purple),
                      initialValue: _valueController.text,
                      onFinished: (v) => _valueController.text = v,
                      inputType: const TextInputType.numberWithOptions(decimal: false),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  timePicker,
                  TextInputWidget(
                    title: _LocalTitle('tracker_numeric_contribution'.tr, Icons.numbers, Colors.purple),
                    initialValue: _valueController.text,
                    onFinished: (v) => _valueController.text = v,
                    inputType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              );
            },
            anniversary: (c) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TimePickerWidget(
                  label: 'tracker_record_time'.tr,
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
                  title: _LocalTitle('tracker_anniversary_content'.tr, Icons.edit, Colors.blue),
                  widget: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _anniversaryPreview = !_anniversaryPreview;
                      });
                    },
                    icon: Icon(_anniversaryPreview ? Icons.edit_note : Icons.preview_outlined, size: 16),
                    label: Text(_anniversaryPreview ? 'tracker_write'.tr : 'tracker_preview'.tr),
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
                      hintText: 'tracker_anniversary_markdown_hint'.tr,
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
                        ? Text('tracker_no_preview_content'.tr, style: Theme.of(context).textTheme.bodySmall)
                        : SimpleMarkdownRenderer(data: _contentController.text),
                  ),
              ],
            ),
          ),
          if (cfg is! AnniversaryTrackerConfig) ...[
            const SizedBox(height: 6),
            TextInputWidget(
              title: _LocalTitle('tracker_note'.tr, Icons.description, Colors.grey),
              initialValue: _contentController.text,
              onFinished: (v) => _contentController.text = v,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  final cfg2 = tracker.body.config;
                  final effectiveTimestamp = _recordTimestamp;
                  final rec = _buildTrackerRecordFromInput(
                    config: cfg2,
                    trackerId: tracker.id,
                    timestamp: effectiveTimestamp,
                    rawValue: _valueController.text,
                    rawContent: _contentController.text,
                    milestoneBooleanValue: _milestoneBooleanValue,
                    allowMilestoneBoolean: _isEditingRecord,
                  );
                  if (rec == null) return;

                  if (_isEditingRecord) {
                    recordController.updateData(_editingRecord!.id, rec);
                  } else {
                    recordController.addData(rec);
                  }
                  setState(() {
                    _resetRecordInputState();
                  });
                  trackerController.rebuildLocal();
                },
                child: Text(_isEditingRecord ? 'tracker_edit_record'.tr : 'tracker_add_record'.tr),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _resetRecordInputState();
                  });
                },
                child: Text('cancel'.tr),
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
  const _RecordsTimeline({required this.records, required this.canEdit, required this.onEditRecord});
  final List<TrackerRecordDataItem> records;
  final bool canEdit;
  final void Function(TrackerRecordDataItem item) onEditRecord;

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime dt) => '${dt.year}-${_twoDigits(dt.month)}-${_twoDigits(dt.day)}';

  String _formatTime(DateTime dt) => '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}';

  @override
  Widget build(BuildContext context) {
    final List<TrackerRecordDataItem> sortedRecords = List.from(records)
      ..sort((a, b) => b.body.timestamp.compareTo(a.body.timestamp));
    final colorScheme = Theme.of(context).colorScheme;
    final UserManagerController userManager = Get.find<UserManagerController>();
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: sortedRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (ctx, gi) {
        final recordItem = sortedRecords[gi];
        final record = recordItem.body;
        final localTime = record.timestamp.toLocal();
        final dateLabel = _formatDate(localTime);
        final timeLabel = _formatTime(localTime);
        final relativeLabel = readableDateStr(localTime);
        final isFirst = gi == 0;
        final isLast = gi == sortedRecords.length - 1;
        final userProfile = userManager.selfProfile.value?.userId == recordItem.owner
            ? userManager.selfProfile.value
            : userManager.getUserProfile(recordItem.owner);
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
                      buildUserAvatar(context, userProfile?.avatarUrl, size: 16, selected: false),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (canEdit)
                        IconButton(
                          tooltip: 'edit'.tr,
                          onPressed: () => onEditRecord(recordItem),
                          icon: const Icon(Icons.edit),
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
