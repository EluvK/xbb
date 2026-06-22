import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:get/get.dart';

class CheckinCalendar extends StatefulWidget {
  const CheckinCalendar({
    super.key,
    required this.events,
    required this.recordsByDay,
    required this.onDaySelected,
    this.onPageChanged,
  });

  final RxList<CheckinEventDataItem> events;
  final Map<String, List<CheckinRecordDataItem>> recordsByDay;
  final void Function(DateTime day, String dayKey) onDaySelected;
  final void Function(DateTime focusedDay)? onPageChanged;

  @override
  State<CheckinCalendar> createState() => _CheckinCalendarState();
}

class _CheckinCalendarState extends State<CheckinCalendar> {
  DateTime _focusedDay = DateTime.now();
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  String _formatDayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDaySelected(_selectedDay, _formatDayKey(_selectedDay));
    });
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2035),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      calendarFormat: _calendarFormat,
      onFormatChanged: (format) => setState(() => _calendarFormat = format),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        final dayKey = _formatDayKey(selectedDay);
        widget.onDaySelected(selectedDay, dayKey);
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
        widget.onPageChanged?.call(focusedDay);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final dayKey = _formatDayKey(date);
          final dayRecords = widget.recordsByDay[dayKey];
          if (dayRecords == null || dayRecords.isEmpty) return null;
          final eventIds = dayRecords.map((r) => r.body.eventId).toSet();
          final filtered = widget.events.where((e) => eventIds.contains(e.id)).toList();
          if (filtered.isEmpty) return null;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: filtered.map((e) {
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(e.body.colorValue),
                ),
              );
            }).toList(),
          );
        },
      ),
      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
      locale: Get.locale?.languageCode ?? 'en',
    );
  }
}
