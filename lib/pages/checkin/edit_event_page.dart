import 'package:flutter/material.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';
import 'package:get/get.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/utils/color_picker.dart';
import 'package:xbb/utils/text_input.dart';

class _FieldTitle implements TitleInterface {
  const _FieldTitle(this.gTitle, this.gIcon, this.gColor);

  @override
  final String gTitle;
  @override
  final IconData gIcon;
  @override
  final Color gColor;
}

class EditCheckinEventPage extends StatefulWidget {
  const EditCheckinEventPage({super.key});

  @override
  State<EditCheckinEventPage> createState() => _EditCheckinEventPageState();
}

class _EditCheckinEventPageState extends State<EditCheckinEventPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late Color _selectedColor;
  CheckinEventDataItem? _editingItem;
  late final bool _creatingNew;

  CheckinEventController get _controller => Get.find<CheckinEventController>();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final CheckinEventDataItem? existing = args?[0];
    if (existing != null) {
      _editingItem = existing;
      _creatingNew = false;
      _nameController.text = existing.body.name;
      _descriptionController.text = existing.body.description;
      _selectedColor = Color(existing.body.colorValue);
    } else {
      _creatingNew = true;
      _selectedColor = RandomColor.getColorObject(Options(luminosity: Luminosity.light));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('checkin_name_required'.tr, '');
      return;
    }
    final event = CheckinEvent(
      name: name,
      description: _descriptionController.text.trim(),
      colorValue: _selectedColor.toARGB32(),
    );
    if (_editingItem != null) {
      _controller.updateData(_editingItem!.id, event);
    } else {
      _controller.addData(event);
    }
    Navigator.pop(context);
  }

  void _delete() {
    if (_editingItem == null) return;
    Get.defaultDialog(
      title: 'checkin_delete_event'.tr,
      middleText: 'checkin_delete_confirm'.tr,
      textCancel: 'cancel'.tr,
      textConfirm: 'delete'.tr,
      confirmTextColor: Colors.white,
      onConfirm: () {
        _controller.deleteData(_editingItem!.id);
        Navigator.pop(context);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_creatingNew ? 'checkin_create_event'.tr : 'checkin_edit_event'.tr),
        actions: [
          TextButton(onPressed: _save, child: Text('checkin_save'.tr)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            UserDefinedInputWidget(
              title: _FieldTitle('checkin_event_name'.tr, Icons.title, Colors.blue),
              widget: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                autofocus: true,
              ),
            ),
            const SizedBox(height: 8),
            UserDefinedInputWidget(
              title: _FieldTitle('checkin_event_description'.tr, Icons.description, Colors.green),
              widget: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ColorPickerWidget(
              label: 'checkin_event_color'.tr,
              icon: Icons.color_lens,
              color: Colors.pink,
              initialValue: _selectedColor,
              onChanged: (color) => _selectedColor = color,
            ),
            const SizedBox(height: 32),
            if (!_creatingNew)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text('checkin_delete_event'.tr),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
