import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';

/// A generic time/date picker row suitable for xbb.
/// Use simple parameters (label/icon/color/pickerType) instead of project-specific enums.
class TimePickerWidget extends StatelessWidget {
  TimePickerWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.pickerType,
    this.initialValue,
    this.onChange,
  });

  final String label;
  final IconData icon;
  final Color color;
  final DateTimePickerType pickerType;
  final DateTime? initialValue;
  final void Function(DateTime)? onChange;

  late final ValueNotifier<DateTime> date = ValueNotifier(initialValue?.toLocal() ?? DateTime.now());

  @override
  Widget build(BuildContext context) {
    final controller = BoardDateTimeController();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await showBoardDateTimePicker(
            context: context,
            pickerType: pickerType,
            initialDate: date.value,
            options: const BoardDateTimeOptions(
              // todo i18n
              languages: BoardPickerLanguages(today: '今天', tomorrow: '明天', yesterday: '昨天', now: '现在', locale: 'zh'),
              startDayOfWeek: DateTime.monday,
              pickerFormat: PickerFormat.ymd,
              withSecond: false,
            ),
            valueNotifier: date,
            controller: controller,
            onChanged: (value) {
              date.value = value;
              if (onChange != null) onChange!(value.toUtc());
            },
          );
          if (result != null) {
            date.value = result;
            if (onChange != null) onChange!(result.toUtc());
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
              ValueListenableBuilder<DateTime>(
                valueListenable: date,
                builder: (context, data, _) {
                  return Text(
                    BoardDateFormat(_formatter(pickerType)).format(data),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatter(DateTimePickerType type, {bool withSecond = false}) {
  switch (type) {
    case DateTimePickerType.date:
      return 'yyyy/MM/dd';
    case DateTimePickerType.datetime:
      return 'yyyy/MM/dd HH:mm';
    case DateTimePickerType.time:
      return withSecond ? 'HH:mm:ss' : 'HH:mm';
  }
}

// A simple duration picker that uses the platform time picker to pick hours/minutes.
class DurationPickerWidget extends StatelessWidget {
  DurationPickerWidget({
    super.key,
    required this.initialValue,
    required this.onChange,
    this.label = 'Duration',
    this.icon = Icons.schedule_rounded,
    this.color = Colors.pink,
  });

  final Duration initialValue;
  final void Function(Duration) onChange;
  final String label;
  final IconData icon;
  final Color color;

  late final ValueNotifier<Duration> duration = ValueNotifier(initialValue);

  String _format(Duration d) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final resultDateTime = await showBoardDateTimePickerForTime(
            context: context,
            initialDate: DateTime.now().copyWith(
              hour: initialValue.inHours,
              minute: initialValue.inMinutes.remainder(60),
            ),
            onResult: (BoardTimeResult result) {
              duration.value = Duration(hours: result.hour, minutes: result.minute);
              onChange(duration.value);
            },
            options: BoardDateTimeOptions(
              // todo i18n
              pickerSubTitles: const BoardDateTimeItemTitles(hour: '小时', minute: '分钟'),
              customOptions: BoardPickerCustomOptions(minutes: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]),
            ),
          );
          if (resultDateTime != null) {
            duration.value = Duration(hours: resultDateTime.hour, minutes: resultDateTime.minute);
            onChange(duration.value);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
              ValueListenableBuilder<Duration>(
                valueListenable: duration,
                builder: (context, data, _) {
                  return Text(
                    _format(data),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
