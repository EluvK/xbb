import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/checkin/model.dart';

class EventListBar extends StatelessWidget {
  const EventListBar({
    super.key,
    required this.events,
    required this.records,
    required this.filteredEventIds,
    required this.focusedDay,
    required this.onFilterChanged,
  });

  final RxList<CheckinEventDataItem> events;
  final RxList<CheckinRecordDataItem> records;
  final Set<String> filteredEventIds;
  final DateTime focusedDay;
  final void Function(Set<String> eventIds) onFilterChanged;

  String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  int _monthlyCount(CheckinEventDataItem event) {
    final monthPrefix = _dayKey(focusedDay).substring(0, 7);
    return records.where((r) => r.body.eventId == event.id && r.body.localDayKey.startsWith(monthPrefix)).length;
  }

  bool get _showingAll => filteredEventIds.length == events.length;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (events.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text('checkin_no_events'.tr)),
        );
      }
      return SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text('checkin_filter_all'.tr),
                selected: _showingAll,
                onSelected: (selected) {
                  if (selected) {
                    onFilterChanged(events.map((e) => e.id).toSet());
                  } else {
                    onFilterChanged({});
                  }
                },
              ),
            ),
            ...events.map((event) {
              final selected = filteredEventIds.contains(event.id);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onLongPress: () => Get.toNamed('/checkin/edit-event', arguments: [event]),
                  child: FilterChip(
                    avatar: Icon(Icons.circle, size: 10, color: Color(event.body.colorValue)),
                    label: Text('${event.body.name} ${_monthlyCount(event)}'),
                    selected: selected || _showingAll,
                    onSelected: (isSelected) {
                      final newSet = Set<String>.from(filteredEventIds);
                      if (isSelected) {
                        newSet.add(event.id);
                      } else {
                        newSet.remove(event.id);
                      }
                      onFilterChanged(newSet);
                    },
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
