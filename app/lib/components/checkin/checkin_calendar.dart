import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  late PageController _pageController;

  String _formatDayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDaySelected(_selectedDay, _formatDayKey(_selectedDay));
    });
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    super.dispose();
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
    _focusedDay.value = day;
    final dayKey = _formatDayKey(day);
    widget.onDaySelected(day, dayKey);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<DateTime>(
          valueListenable: _focusedDay,
          builder: (context, value, _) {
            return _CheckinCalendarHeader(
              focusedDay: value,
              onTodayButtonTap: () => _selectDay(DateTime.now()),
              onLeftArrowTap: () {
                _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
              onRightArrowTap: () {
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
              onJumpToDate: (date) => _selectDay(date),
            );
          },
        ),
        TableCalendar(
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          startingDayOfWeek: StartingDayOfWeek.monday,
          focusedDay: _focusedDay.value,
          headerVisible: false,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) => setState(() => _calendarFormat = format),
          onDaySelected: (selectedDay, focusedDay) {
            _selectDay(selectedDay);
          },
          onPageChanged: (focusedDay) {
            _focusedDay.value = focusedDay;
            widget.onPageChanged?.call(focusedDay);
          },
          onCalendarCreated: (controller) => _pageController = controller,
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
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Color(e.body.colorValue)),
                  );
                }).toList(),
              );
            },
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
          ),
          locale: Get.locale?.languageCode ?? 'en',
        ),
      ],
    );
  }
}

class _CheckinCalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onTodayButtonTap;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final void Function(DateTime date) onJumpToDate;

  const _CheckinCalendarHeader({
    required this.focusedDay,
    required this.onTodayButtonTap,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onJumpToDate,
  });

  @override
  Widget build(BuildContext context) {
    final headerText = DateFormat.yMMM(Get.locale?.languageCode).format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 8.0),
          InkWell(
            onTap: () async {
              final result = await showBoardDateTimePicker(
                minimumDate: DateTime(2020),
                maximumDate: DateTime(2035),
                context: context,
                pickerType: DateTimePickerType.date,
                initialDate: focusedDay,
                options: BoardDateTimeOptions(
                  languages: BoardPickerLanguages(
                    today: '今天',
                    tomorrow: '明天',
                    yesterday: '昨天',
                    now: '现在',
                    locale: Get.locale?.languageCode ?? 'zh',
                  ),
                  startDayOfWeek: DateTime.monday,
                  pickerFormat: PickerFormat.ymd,
                  boardTitle: '跳转日期',
                  pickerSubTitles: const BoardDateTimeItemTitles(year: '年', month: '月', day: '日'),
                  withSecond: false,
                ),
              );
              if (result != null) {
                onJumpToDate(result);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(headerText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.today, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: onTodayButtonTap,
            tooltip: '今天',
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onLeftArrowTap),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onRightArrowTap),
        ],
      ),
    );
  }
}
