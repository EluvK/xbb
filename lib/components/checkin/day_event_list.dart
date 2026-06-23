import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
            DateFormat.MMMd(Get.locale?.languageCode).format(day),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...events.map((event) {
            final record = records.firstWhereOrNull(
              (r) => r.body.eventId == event.id && r.body.localDayKey == dayKey,
            );
            final done = record != null;
            final color = Color(event.body.colorValue);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          done ? Icons.check_circle : Icons.circle,
                          color: color,
                          size: done ? 14 : 10,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            event.body.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (done)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _fmtTime(record.body.createdAtUtc),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 2),
                              _ActionButton(
                                icon: Icons.edit_outlined,
                                color: Colors.grey,
                                onPressed: () => _editRecord(context, record),
                              ),
                              _ActionButton(
                                icon: Icons.undo,
                                color: Colors.red.shade300,
                                onPressed: isAllowed ? () => _toggleCheckin(context, event) : null,
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: isAllowed ? () => _toggleCheckin(context, event) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text('checkin_checkin'.tr, style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                    if (done && record.body.note != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, top: 4),
                        child: Text(
                          record.body.note!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        splashRadius: 16,
      ),
    );
  }
}
