import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/checkin/checkin_calendar.dart';
import 'package:xbb/components/checkin/day_event_list.dart';
import 'package:xbb/components/checkin/event_list_bar.dart';
import 'package:xbb/controller/checkin_widget.dart';
import 'package:xbb/models/checkin/model.dart';

class CheckinCalendarPage extends StatefulWidget {
  const CheckinCalendarPage({super.key});

  @override
  State<CheckinCalendarPage> createState() => _CheckinCalendarPageState();
}

class _CheckinCalendarPageState extends State<CheckinCalendarPage> {
  final CheckinEventController eventController = Get.find<CheckinEventController>();
  final CheckinRecordController recordController = Get.find<CheckinRecordController>();
  final Set<String> _filteredEventIds = {};
  bool _filterEverPopulated = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late String _selectedDayKey;

  late final RxList<CheckinEventDataItem> _events;
  late final RxList<CheckinRecordDataItem> _records;

  String _formatDayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _selectedDayKey = _formatDayKey(_selectedDay);
    _events = eventController.registerFilterSubscription(filterKey: 'checkin-calendar-all');
    _records = recordController.registerFilterSubscription(filterKey: 'checkin-calendar-all');
  }

  @override
  void dispose() {
    eventController.unregisterFilterSubscription('checkin-calendar-all');
    recordController.unregisterFilterSubscription('checkin-calendar-all');
    super.dispose();
  }

  Set<String> get _filteredIds => _filteredEventIds;

  Map<String, List<CheckinRecordDataItem>> _recordsByDayKey() {
    final activeIds = _filteredIds;
    final map = <String, List<CheckinRecordDataItem>>{};
    for (final r in _records) {
      if (activeIds.contains(r.body.eventId)) {
        map.putIfAbsent(r.body.localDayKey, () => []).add(r);
      }
    }
    return map;
  }

  void _onDaySelected(DateTime day, String dayKey) {
    setState(() {
      _selectedDay = day;
      _selectedDayKey = dayKey;
    });
  }

  void _onDataChanged() {
    CheckinWidgetBridge.scheduleRefresh();
    setState(() {});
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/checkin/edit-event', arguments: [null]),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (!_filterEverPopulated && _events.isNotEmpty) {
          _filterEverPopulated = true;
          _filteredEventIds.addAll(_events.map((e) => e.id));
        }
        final recordsByDay = _recordsByDayKey();
        return SingleChildScrollView(
          child: Column(
            children: [
              EventListBar(
                events: _events,
                records: _records,
                filteredEventIds: _filteredEventIds,
                focusedDay: _focusedDay,
                onFilterChanged: (ids) => setState(() {
                  _filteredEventIds.clear();
                  _filteredEventIds.addAll(ids);
                  _focusedDay = DateTime.now();
                }),
              ),
              CheckinCalendar(
                events: _events,
                recordsByDay: recordsByDay,
                onDaySelected: _onDaySelected,
                onPageChanged: _onPageChanged,
              ),
              if (_events.isNotEmpty)
                DayEventList(
                  day: _selectedDay,
                  dayKey: _selectedDayKey,
                  events: _events,
                  records: _records,
                  recordController: recordController,
                  eventController: eventController,
                  onChanged: _onDataChanged,
                ),
            ],
          ),
        );
      }),
    );
  }
}
