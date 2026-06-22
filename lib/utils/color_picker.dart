import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';

class ColorPickerWidget extends StatefulWidget {
  const ColorPickerWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.initialValue,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color? initialValue;
  final void Function(Color) onChanged;

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late final ValueNotifier<Color> _color;

  @override
  void initState() {
    super.initState();
    _color = ValueNotifier(
      widget.initialValue ?? RandomColor.getColorObject(Options(luminosity: Luminosity.light)),
    );
  }

  @override
  void didUpdateWidget(covariant ColorPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != null && oldWidget.initialValue != widget.initialValue) {
      _color.value = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _color.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final newColor = await showColorPickerDialog(
            context,
            _color.value,
            title: Text(widget.label, style: Theme.of(context).textTheme.titleLarge),
            subheading: const Text('调整深浅'),
            width: 40,
            height: 40,
            showColorCode: true,
            showColorName: true,
            pickersEnabled: const {
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: false,
              ColorPickerType.bw: false,
              ColorPickerType.custom: false,
              ColorPickerType.wheel: true,
            },
            pickerTypeLabels: const {
              ColorPickerType.primary: '常规',
              ColorPickerType.wheel: '轮盘',
            },
            actionButtons: const ColorPickerActionButtons(
              okButton: true,
              closeButton: true,
              dialogActionButtons: false,
            ),
            transitionBuilder: (context, a1, a2, widget) {
              final curvedValue = Curves.easeInOutBack.transform(a1.value) - 1.0;
              return Transform(
                transform: Matrix4.translationValues(0.0, curvedValue * 100, 0.0),
                child: Opacity(opacity: a1.value, child: widget),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          );
          _color.value = newColor;
          widget.onChanged(newColor);
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
              ValueListenableBuilder<Color>(
                valueListenable: _color,
                builder: (context, color, _) {
                  return ColorIndicator(
                    width: 32,
                    height: 32,
                    borderRadius: 8,
                    color: color,
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
