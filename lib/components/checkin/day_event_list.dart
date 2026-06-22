import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/utils/time_picker.dart';
import 'package:board_datetime_picker/board_datetime_picker.dart';

class DayEventList extends StatelessWidget {
  const DayEventList({
    super.key,
    required this.day,
    required this.dayKey,
    required this.events,
    required this.records,
    required this.recordController,
    required this.eventController,
    required this.onChanged,
  });

  final DateTime day;
  final String dayKey;
  final RxList<CheckinEventDataItem> events;
  final RxList<CheckinRecordDataItem> records;
  final CheckinRecordController recordController;
  final CheckinEventController eventController;
  final VoidCallback onChanged;

  bool _todayOrPast() {
    final now = DateTime.now();
    return day.year < now.year ||
        (day.year == now.year && day.month < now.month) ||
        (day.year == now.year && day.month == now.month && day.day <= now.day);
  }

  String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  void _toggleCheckin(BuildContext context, CheckinEventDataItem event) {
    final existing = records.firstWhereOrNull(
      (r) => r.body.eventId == event.id && r.body.localDayKey == dayKey,
    );
    if (existing != null) {
      Get.defaultDialog(
        title: 'checkin_undo_title'.tr,
        middleText: 'checkin_undo_confirm'.trParams({'name': event.body.name}),
        textCancel: 'cancel'.tr,
        textConfirm: 'checkin_undo'.tr,
        confirmTextColor: Colors.white,
        onConfirm: () {
          recordController.deleteData(existing.id);
          onChanged();
          Navigator.pop(context);
        },
      );
    } else {
      final now = DateTime.now().toUtc();
      final local = now.toLocal();
      final offset = local.timeZoneOffset.inMinutes;
      final record = CheckinRecord(
        eventId: event.id,
        createdAtUtc: now,
        localDayKey: dayKey,
        timezoneOffsetMinutes: offset,
        note: null,
      );
      recordController.addData(record);
      onChanged();
    }
  }

  void _editRecord(BuildContext context, CheckinRecordDataItem record) {
    DateTime currentTime = record.body.createdAtUtc.toLocal();
    TextEditingController noteController = TextEditingController(text: record.body.note ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('checkin_edit_record'.tr, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TimePickerWidget(
                label: 'checkin_record_time'.tr,
                icon: Icons.schedule,
                color: Colors.indigo,
                pickerType: DateTimePickerType.time,
                initialValue: currentTime,
                onChange: (v) => currentTime = v.toLocal(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(labelText: 'checkin_note'.tr),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('cancel'.tr),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final updated = CheckinRecord(
                        eventId: record.body.eventId,
                        createdAtUtc: currentTime.toUtc(),
                        localDayKey: record.body.localDayKey,
                        timezoneOffsetMinutes: currentTime.timeZoneOffset.inMinutes,
                        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                      );
                      recordController.updateData(record.id, updated);
                      onChanged();
                      Navigator.pop(ctx);
                    },
                    child: Text('checkin_save'.tr),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAllowed = _todayOrPast();
    if (events.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          Text(
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ...events.map((event) {
            final record = records.firstWhereOrNull(
              (r) => r.body.eventId == event.id && r.body.localDayKey == dayKey,
            );
            final done = record != null;
            final color = Color(event.body.colorValue);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.circle, color: color, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(event.body.name, style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  if (done) ...[
                    Text(
                      '${_fmtTime(record.body.createdAtUtc)}${record.body.note != null ? ' · ${record.body.note}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editRecord(context, record),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(Icons.undo, size: 18, color: Colors.red.shade300),
                      onPressed: isAllowed ? () => _toggleCheckin(context, event) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ] else
                    ElevatedButton(
                      onPressed: isAllowed ? () => _toggleCheckin(context, event) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('checkin_checkin'.tr, style: const TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
