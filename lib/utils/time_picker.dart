import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';

/// A generic time/date picker row suitable for xbb.
/// Use simple parameters (label/icon/color/pickerType) instead of project-specific enums.
class TimePickerWidget extends StatefulWidget {
  const TimePickerWidget({
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

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late final ValueNotifier<DateTime> _date;

  @override
  void initState() {
    super.initState();
    _date = ValueNotifier(widget.initialValue?.toLocal() ?? DateTime.now());
  }

  @override
  void didUpdateWidget(covariant TimePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null && oldWidget.initialValue != widget.initialValue) {
      _date.value = widget.initialValue!.toLocal();
    }
  }

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = BoardDateTimeController();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final result = await showBoardDateTimePicker(
            context: context,
            pickerType: widget.pickerType,
            initialDate: _date.value,
            options: const BoardDateTimeOptions(
              // todo i18n
              languages: BoardPickerLanguages(today: '今天', tomorrow: '明天', yesterday: '昨天', now: '现在', locale: 'zh'),
              startDayOfWeek: DateTime.monday,
              pickerFormat: PickerFormat.ymd,
              withSecond: false,
            ),
            valueNotifier: _date,
            controller: controller,
            onChanged: (value) {
              _date.value = value;
              if (widget.onChange != null) widget.onChange!(value.toUtc());
            },
          );
          if (result != null) {
            _date.value = result;
            if (widget.onChange != null) widget.onChange!(result.toUtc());
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: widget.color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(widget.icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.label, style: Theme.of(context).textTheme.bodyMedium)),
              ValueListenableBuilder<DateTime>(
                valueListenable: _date,
                builder: (context, data, _) {
                  return Text(
                    BoardDateFormat(_formatter(widget.pickerType)).format(data),
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
class DurationPickerWidget extends StatefulWidget {
  const DurationPickerWidget({
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

  @override
  State<DurationPickerWidget> createState() => _DurationPickerWidgetState();
}

class _DurationPickerWidgetState extends State<DurationPickerWidget> {
  late final ValueNotifier<Duration> _duration;

  @override
  void initState() {
    super.initState();
    _duration = ValueNotifier(widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant DurationPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _duration.value = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

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
              hour: _duration.value.inHours,
              minute: _duration.value.inMinutes.remainder(60),
            ),
            onResult: (BoardTimeResult result) {
              _duration.value = Duration(hours: result.hour, minutes: result.minute);
              widget.onChange(_duration.value);
            },
            options: BoardDateTimeOptions(
              // todo i18n
              pickerSubTitles: const BoardDateTimeItemTitles(hour: '小时', minute: '分钟'),
              customOptions: BoardPickerCustomOptions(minutes: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]),
            ),
          );
          if (resultDateTime != null) {
            _duration.value = Duration(hours: resultDateTime.hour, minutes: resultDateTime.minute);
            widget.onChange(_duration.value);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: widget.color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(widget.icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(widget.label, style: Theme.of(context).textTheme.bodyMedium)),
              ValueListenableBuilder<Duration>(
                valueListenable: _duration,
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
