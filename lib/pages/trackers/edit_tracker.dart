import 'package:board_datetime_picker/board_datetime_picker.dart' show DateTimePickerType;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/tracker/model.dart';
// import 'package:xbb/utils/utils.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/time_picker.dart';
import 'package:xbb/utils/utils.dart';

class EditTrackerPage extends StatelessWidget {
  const EditTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final TrackerDataItem? tracker = args?[0];
    if (tracker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Tracker')),
        body: const EditTracker(),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Tracker')),
      body: EditTracker(trackerItem: tracker),
    );
  }
}

class EditTracker extends StatefulWidget {
  const EditTracker({super.key, this.trackerItem});
  final TrackerDataItem? trackerItem;

  @override
  State<EditTracker> createState() => _EditTrackerState();
}

class _EditTrackerState extends State<EditTracker> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  TrackerDataItem? _editingItem;
  String _type = 'event';

  // event
  final TextEditingController _periodDaysController = TextEditingController();

  // milestone
  String _milestoneGoalType = 'time';
  final TextEditingController _milestoneTargetController = TextEditingController();
  Duration _milestoneTargetDuration = const Duration(hours: 1);

  // anniversary
  DateTime? _baseDate;
  bool _isLunar = false;
  String _remindType = 'per_year';

  TrackerController get _trackerController => Get.find<TrackerController>();

  @override
  void initState() {
    super.initState();
    _editingItem = widget.trackerItem;
    if (_editingItem != null) {
      final Tracker t = _editingItem!.body;
      _nameController.text = t.name;
      _descriptionController.text = t.description;
      _categoryController.text = t.category;
      _type = t.type;
      t.config.map(
        event: (c) {
          _periodDaysController.text = c.periodDays.toString();
        },
        milestone: (c) {
          _milestoneGoalType = c.goalType;
          _milestoneTargetController.text = c.targetValue;
          if (_milestoneGoalType == 'time') {
            final secs = int.tryParse(c.targetValue);
            if (secs != null) _milestoneTargetDuration = Duration(seconds: secs);
          }
        },
        anniversary: (c) {
          _baseDate = c.baseDate.toLocal();
          _isLunar = c.isLunar;
          _remindType = c.remindType;
        },
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _periodDaysController.dispose();
    _milestoneTargetController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    TrackerConfig config;
    if (_type == 'event') {
      config = TrackerConfig.event(periodDays: int.tryParse(_periodDaysController.text) ?? 0);
    } else if (_type == 'milestone') {
      final String targetValue;
      if (_milestoneGoalType == 'time') {
        targetValue = _milestoneTargetController.text.isNotEmpty
            ? _milestoneTargetController.text
            : _milestoneTargetDuration.inSeconds.toString();
      } else {
        targetValue = _milestoneTargetController.text;
      }
      config = TrackerConfig.milestone(goalType: _milestoneGoalType, targetValue: targetValue);
    } else {
      config = TrackerConfig.anniversary(
        baseDate: (_baseDate ?? DateTime.now()).toUtc(),
        isLunar: _isLunar,
        remindType: _remindType,
      );
    }
    print('Saving tracker with config: $config');
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      flushBar(FlushLevel.WARNING, 'Validation Error', 'Name cannot be empty');
      return;
    }
    final tracker = Tracker(
      name: name,
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      type: _type,
      config: config,
    );

    if (_editingItem != null) {
      _trackerController.updateData(_editingItem!.id, tracker);
    } else {
      _trackerController.addData(tracker);
    }
    Get.offNamed('/');
  }

  Widget _buildConfigSection() {
    if (_type == 'event') {
      return Column(
        children: [
          TextInputWidget(
            title: const _LocalTitle('Period Days', Icons.repeat, Colors.blueGrey),
            initialValue: _periodDaysController.text,
            onFinished: (v) => _periodDaysController.text = v,
            optional: false,
            helperText: '0 for no cycle',
            inputType: const TextInputType.numberWithOptions(decimal: true),
          ),
          // const SizedBox(height: 12),
          // const Divider(),
          // deleted.
          // Text('record detail setting', style: Theme.of(context).textTheme.titleSmall),
          // UserDefinedInputWidget(
          //   title: const _LocalTitle('Detail Unit', Icons.straighten, Colors.blueGrey),
          //   widget: DropdownButton<String>(
          //     value: _eventDetailUnit,
          //     items: const [
          //       DropdownMenuItem(value: 'duration', child: Text('Duration')),
          //       DropdownMenuItem(value: 'number', child: Text('Number')),
          //       DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
          //     ],
          //     onChanged: (v) => setState(() => _eventDetailUnit = v ?? 'duration'),
          //   ),
          // ),
          // const SizedBox(height: 8),
          // if (_eventDetailUnit == 'duration')
          //   DurationPickerWidget(
          //     initialValue: _eventDefaultDuration,
          //     onChange: (d) => setState(() => _eventDefaultDuration = d),
          //     label: 'Default Duration',
          //     icon: Icons.schedule_rounded,
          //     color: Colors.pink,
          //   )
          // else if (_eventDetailUnit == 'number')
          //   TextInputWidget(
          //     title: const _LocalTitle('Default Value', Icons.numbers, Colors.pink),
          //     initialValue: _eventNumberController.text,
          //     onFinished: (v) => _eventNumberController.text = v,
          //     inputType: const TextInputType.numberWithOptions(decimal: true),
          //   ),
        ],
      );
    } else if (_type == 'milestone') {
      return Column(
        children: [
          UserDefinedInputWidget(
            title: const _LocalTitle('Goal Type', Icons.flag, Colors.purple),
            widget: DropdownButton<String>(
              value: _milestoneGoalType,
              items: const [
                DropdownMenuItem(value: 'time', child: Text('Time')),
                DropdownMenuItem(value: 'number', child: Text('Number')),
                DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
              ],
              onChanged: (v) => setState(() => _milestoneGoalType = v ?? 'time'),
            ),
          ),
          const SizedBox(height: 8),
          if (_milestoneGoalType == 'time')
            TextInputWidget(
              title: const _LocalTitle('Duration (hours)', Icons.timer, Colors.purple),
              initialValue: (_milestoneTargetDuration.inMinutes / 60).toString(),
              onFinished: (v) {
                final hours = double.tryParse(v);
                if (hours != null) {
                  _milestoneTargetDuration = Duration(minutes: (hours * 60).toInt());
                  _milestoneTargetController.text = v;
                }
              },
              inputType: const TextInputType.numberWithOptions(decimal: true),
            )
          else if (_milestoneGoalType == 'number')
            TextInputWidget(
              title: const _LocalTitle('Target Value', Icons.numbers, Colors.purple),
              initialValue: _milestoneTargetController.text,
              onFinished: (v) => _milestoneTargetController.text = v,
              inputType: const TextInputType.numberWithOptions(decimal: true),
            )
          else
            BoolSelectorInputWidget(
              title: const _LocalTitle('Target', Icons.check_box, Colors.green),
              initialValue: _milestoneTargetController.text == 'true',
              onChanged: (v) => setState(() => _milestoneTargetController.text = v.toString()),
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimePickerWidget(
            label: 'Base Date',
            icon: Icons.calendar_today,
            color: Colors.blue,
            pickerType: DateTimePickerType.date,
            initialValue: _baseDate,
            onChange: (dt) => setState(() => _baseDate = dt.toLocal()),
          ),
          // todo add lunar calendar support
          // Padding(
          //   padding: const EdgeInsets.only(left: 8.0),
          //   child: BoolSelectorInputWidget(
          //     title: const _LocalTitle('Is Lunar', Icons.calendar_view_month, Colors.blue),
          //     initialValue: _isLunar,
          //     onChanged: (v) => setState(() => _isLunar = v),
          //   ),
          // ),
          UserDefinedInputWidget(
            title: const _LocalTitle('Remind Type', Icons.alarm, Colors.blue),
            widget: DropdownButton<String>(
              value: _remindType,
              items: const [
                DropdownMenuItem(value: 'per_year', child: Text('per_year')),
                DropdownMenuItem(value: 'per_100_days', child: Text('per_100_days')),
                DropdownMenuItem(value: 't_minus', child: Text('t_minus')),
              ],
              onChanged: (v) => setState(() => _remindType = v ?? 'per_year'),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(16.0),
        child: _body(),
      ),
    );
  }

  Widget _body() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              child: Column(
                children: [
                  TextInputWidget(
                    title: InputTitleEnum.title,
                    initialValue: _nameController.text,
                    autoFocus: true,
                    onFinished: (v) => _nameController.text = v,
                  ),
                  const Divider(),
                  TextInputWidget(
                    title: InputTitleEnum.description,
                    initialValue: _descriptionController.text,
                    onFinished: (v) => _descriptionController.text = v,
                    optional: true,
                  ),
                  const Divider(),
                  TextInputWidget(
                    title: const _LocalTitle('Category', Icons.label, Colors.teal),
                    initialValue: _categoryController.text,
                    onFinished: (v) => _categoryController.text = v,
                    optional: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              child: UserDefinedInputWidget(
                title: const _LocalTitle('Type', Icons.category, Colors.orange),
                widget: DropdownButton<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'event', child: Text('Event')),
                    DropdownMenuItem(value: 'milestone', child: Text('Milestone')),
                    DropdownMenuItem(value: 'anniversary', child: Text('Anniversary')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'event'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(child: _buildConfigSection()),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.7), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0), child: child),
    );
  }
}
