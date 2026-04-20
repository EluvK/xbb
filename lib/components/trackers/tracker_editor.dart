import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/acl_editor.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/time_picker.dart';
import 'package:xbb/utils/utils.dart';
import 'package:xbb/utils/view_widget.dart';

class TrackerEditor extends StatefulWidget {
  const TrackerEditor({super.key, this.trackerItem});
  final TrackerDataItem? trackerItem;

  @override
  State<TrackerEditor> createState() => _TrackerEditorState();
}

class _TrackerEditorState extends State<TrackerEditor> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  TrackerDataItem? _editingItem;
  late final bool creatingNewTracker;
  late final bool isSelfTracker;
  Future<List<Permission>>? _initialPermissionsFuture;
  String _type = 'event';

  // event
  final TextEditingController _periodDaysController = TextEditingController();

  // milestone
  String _milestoneGoalType = 'time';
  String _milestoneProgressMode = 'accumulate';
  final TextEditingController _milestoneTargetController = TextEditingController();
  Duration _milestoneTargetDuration = const Duration(hours: 1);

  // anniversary
  DateTime? _baseDate;
  bool _isLunar = false;
  String _remindType = 'per_year';

  TrackerController get _trackerController => Get.find<TrackerController>();
  final UserManagerController userManagerController = Get.find<UserManagerController>();

  String _formatHoursFromMinutes(int minutes) {
    final hours = minutes / 60;
    if (hours == hours.roundToDouble()) {
      return hours.toStringAsFixed(0);
    }
    return hours.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  int? _parseHoursToMinutes(String input) {
    final hours = double.tryParse(input.trim());
    if (hours == null || hours < 0) return null;
    return (hours * 60).round();
  }

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
          _milestoneProgressMode = c.progressMode;
          if (_milestoneGoalType == 'time') {
            final minutes = int.tryParse(c.targetValue);
            if (minutes != null) {
              _milestoneTargetDuration = Duration(minutes: minutes);
              _milestoneTargetController.text = _formatHoursFromMinutes(minutes);
            }
          } else {
            _milestoneTargetController.text = c.targetValue;
          }
        },
        anniversary: (c) {
          _baseDate = c.baseDate.toLocal();
          _isLunar = c.isLunar;
          _remindType = c.remindType;
        },
      );
      creatingNewTracker = false;
      isSelfTracker = userManagerController.selfProfile.value?.userId == _editingItem!.owner;
      _initialPermissionsFuture = _trackerController.getAclRefresh(_editingItem!.id);
    } else {
      creatingNewTracker = true;
      isSelfTracker = true;
      _initialPermissionsFuture = Future.value([]);
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<Permission>>(
          future: _initialPermissionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('tracker_error_with_message'.trParams({'error': snapshot.error.toString()}));
            } else {
              final initialPermissions = snapshot.data as List<Permission>;
              final canEdit =
                  isSelfTracker ||
                  initialPermissions.any(
                    (perm) =>
                        perm.accessLevel == AccessLevel.write ||
                        perm.accessLevel == AccessLevel.update ||
                        perm.accessLevel == AccessLevel.fullAccess,
                  );
              return ListView(
                children: [
                  _editTracker(canEdit),
                  const Divider(),
                  if (creatingNewTracker)
                    Center(child: Text('tracker_acl_after_creation'.tr, style: Theme.of(context).textTheme.bodyMedium))
                  else
                    _editAcl(initialPermissions),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    TrackerConfig config;
    if (_type == 'event') {
      config = TrackerConfig.event(periodDays: int.tryParse(_periodDaysController.text) ?? 0);
    } else if (_type == 'milestone') {
      final String targetValue;
      if (_milestoneGoalType == 'time') {
        final minutes = _parseHoursToMinutes(_milestoneTargetController.text);
        targetValue = (minutes ?? _milestoneTargetDuration.inMinutes).toString();
      } else {
        targetValue = _milestoneTargetController.text;
      }
      config = TrackerConfig.milestone(
        goalType: _milestoneGoalType,
        targetValue: targetValue,
        progressMode: _milestoneProgressMode,
      );
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
      flushBar(FlushLevel.WARNING, 'tracker_validation_error'.tr, 'tracker_name_required'.tr);
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
    Navigator.pop(context);
  }

  Widget _buildConfigSection() {
    if (_type == 'event') {
      return Column(
        children: [
          TextInputWidget(
            title: _LocalTitle('tracker_period_days_title'.tr, Icons.repeat, Colors.blueGrey),
            initialValue: _periodDaysController.text,
            onFinished: (v) => _periodDaysController.text = v,
            optional: false,
            helperText: 'tracker_period_days_helper'.tr,
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
            title: _LocalTitle('tracker_goal_type'.tr, Icons.flag, Colors.purple),
            widget: DropdownButton<String>(
              value: _milestoneGoalType,
              items: [
                DropdownMenuItem(value: 'time', child: Text('tracker_goal_time'.tr)),
                DropdownMenuItem(value: 'number', child: Text('tracker_goal_number'.tr)),
                // TODO: Temporarily hide boolean milestone creation until product semantics are finalized.
                // DropdownMenuItem(value: 'boolean', child: Text('Boolean')),
              ],
              onChanged: (v) => setState(() => _milestoneGoalType = v ?? 'time'),
            ),
          ),
          const SizedBox(height: 8),
          UserDefinedInputWidget(
            title: _LocalTitle('tracker_progress_mode'.tr, Icons.refresh, Colors.deepPurple),
            widget: DropdownButton<String>(
              value: _milestoneProgressMode,
              items: [
                DropdownMenuItem(value: 'accumulate', child: Text('tracker_progress_mode_accumulate'.tr)),
                DropdownMenuItem(value: 'latest', child: Text('tracker_progress_mode_latest'.tr)),
              ],
              onChanged: (v) => setState(() => _milestoneProgressMode = v ?? 'accumulate'),
            ),
          ),
          const SizedBox(height: 8),
          if (_milestoneGoalType == 'time')
            TextInputWidget(
              title: _LocalTitle('tracker_duration_hours'.tr, Icons.timer, Colors.purple),
              initialValue: _milestoneTargetController.text.isNotEmpty
                  ? _milestoneTargetController.text
                  : _formatHoursFromMinutes(_milestoneTargetDuration.inMinutes),
              onFinished: (v) {
                final minutes = _parseHoursToMinutes(v);
                if (minutes != null) {
                  _milestoneTargetDuration = Duration(minutes: minutes);
                  _milestoneTargetController.text = v.trim();
                }
              },
              inputType: const TextInputType.numberWithOptions(decimal: true),
            )
          else if (_milestoneGoalType == 'number')
            TextInputWidget(
              title: _LocalTitle('tracker_target_value_title'.tr, Icons.numbers, Colors.purple),
              initialValue: _milestoneTargetController.text,
              onFinished: (v) => _milestoneTargetController.text = v,
              inputType: const TextInputType.numberWithOptions(decimal: true),
            )
          else
            // BoolSelectorInputWidget(
            //     title: const _LocalTitle('Target', Icons.check_box, Colors.green),
            //     initialValue: _milestoneTargetController.text == 'true',
            //     onChanged: (v) => setState(() => _milestoneTargetController.text = v.toString()),
            //   ),
            UserDefinedInputWidget(
              title: _LocalTitle('tracker_target'.tr, Icons.check_box, Colors.green),
              // TODO: Re-enable boolean milestone editor once the recording semantics are finalized.
              widget: Text('tracker_boolean_target_hidden'.tr, style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TimePickerWidget(
            label: 'tracker_base_date'.tr,
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
            title: _LocalTitle('tracker_remind_type'.tr, Icons.alarm, Colors.blue),
            widget: DropdownButton<String>(
              value: _remindType,
              items: [
                DropdownMenuItem(value: 'per_year', child: Text('tracker_remind_per_year'.tr)),
                DropdownMenuItem(value: 'per_100_days', child: Text('tracker_remind_per_100_days'.tr)),
                DropdownMenuItem(value: 't_minus', child: Text('tracker_remind_t_minus'.tr)),
              ],
              onChanged: (v) => setState(() => _remindType = v ?? 'per_year'),
            ),
          ),
        ],
      );
    }
  }

  Widget _editTracker(bool canEdit) {
    if (!canEdit) {
      final item = _editingItem!;
      return Column(
        children: [
          TextViewWidget(title: InputTitleEnum.title, value: item.body.name),
          TextViewWidget(title: InputTitleEnum.description, value: item.body.description),
          TextViewWidget(
            title: _LocalTitle('tracker_category'.tr, Icons.label, Colors.teal),
            value: item.body.category,
          ),
          TextViewWidget(title: _LocalTitle('tracker_type'.tr, Icons.category, Colors.orange), value: item.body.type),
        ],
      );
    }
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
                    title: _LocalTitle('tracker_category'.tr, Icons.label, Colors.teal),
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
                title: _LocalTitle('tracker_type'.tr, Icons.category, Colors.orange),
                widget: DropdownButton<String>(
                  value: _type,
                  items: [
                    DropdownMenuItem(value: 'event', child: Text('tracker_type_event'.tr)),
                    DropdownMenuItem(value: 'milestone', child: Text('tracker_type_milestone'.tr)),
                    DropdownMenuItem(value: 'anniversary', child: Text('tracker_type_anniversary'.tr)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'event'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(child: _buildConfigSection()),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: Text('save'.tr)),
          ],
        ),
      ),
    );
  }

  Widget _editAcl(List<Permission> initialPermissions) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isSelfTracker
            ? Text('tracker_access_control'.tr, style: Theme.of(context).textTheme.titleMedium)
            : Text('tracker_your_permissions'.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        isSelfTracker
            ? AclEditor(
                schema: TrackerPermissionSchema(),
                initialPermissions: initialPermissions,
                onSavePermissions: (newPermissions) async {
                  await _trackerController.setAcls(widget.trackerItem!.id, newPermissions);
                  setState(() {
                    _initialPermissionsFuture = Future.value(newPermissions);
                  });
                },
              )
            : AclViewer(schema: TrackerPermissionSchema(), permissions: initialPermissions),
      ],
    );
  }
}

class TrackerPermissionSchema implements PermissionSchema {
  @override
  List<(String, String)> get labels => [
    ('tracker_perm_view'.tr, 'view'),
    ('tracker_perm_edit'.tr, 'edit'),
    ('tracker_perm_full_access'.tr, 'full_access'),
  ];

  @override
  List<bool> decode(AccessLevel accessLevel) {
    switch (accessLevel) {
      case AccessLevel.none:
        return [false, false, false];
      case AccessLevel.read:
        return [true, false, false];
      case AccessLevel.write:
        return [true, true, false];
      case AccessLevel.fullAccess:
        return [true, true, true];
      // unimplemented;
      case AccessLevel.read_append1:
      case AccessLevel.read_append2:
      case AccessLevel.read_append3:
      case AccessLevel.update:
        return [false, false, false];
    }
  }

  @override
  AccessLevel encode(List<bool> accessList) {
    if (accessList[2]) {
      return AccessLevel.fullAccess;
    } else if (accessList[1]) {
      return AccessLevel.write;
    } else if (accessList[0]) {
      return AccessLevel.read;
    } else {
      return AccessLevel.none;
    }
  }

  @override
  List<int> disableOverlappingSelections(AccessLevel accessLevel) {
    switch (accessLevel) {
      case AccessLevel.write:
        return [0];
      case AccessLevel.fullAccess:
        return [0, 1];
      case AccessLevel.none:
      case AccessLevel.read_append1:
      case AccessLevel.read_append2:
      case AccessLevel.read_append3:
      case AccessLevel.update:
      case AccessLevel.read:
        return [];
    }
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
