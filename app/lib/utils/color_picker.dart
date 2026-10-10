import 'dart:async';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_randomcolor/flutter_randomcolor.dart';
import 'package:xbb/core/core.dart';
import 'package:syncstore_client/syncstore_client.dart' show ColorTag;

export 'package:syncstore_client/syncstore_client.dart' show ColorTag;

extension ColorTagExtension on ColorTag {
  Color? toColor() {
    switch (this) {
      case ColorTag.red:
        return Colors.red[400];
      case ColorTag.green:
        return Colors.lightGreen[400];
      case ColorTag.blue:
        return Colors.blue[400];
      case ColorTag.yellow:
        return Colors.yellow[400];
      case ColorTag.orange:
        return Colors.orange[400];
      case ColorTag.gray:
        return Colors.grey[400];
      case ColorTag.none:
        return Colors.transparent;
    }
  }
}

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

class InlineColorPickerButton extends StatefulWidget {
  final ColorTag value;
  final ValueChanged<ColorTag> onSelected;

  const InlineColorPickerButton({super.key, required this.value, required this.onSelected});

  @override
  State<InlineColorPickerButton> createState() => _InlineColorPickerButtonState();
}

class _InlineColorPickerButtonState extends State<InlineColorPickerButton> {
  bool expanded = false;
  Timer? _autoCollapseTimer;

  void _cancelAutoCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = null;
  }

  void _startAutoCollapseTimer() {
    _cancelAutoCollapseTimer();
    _autoCollapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && expanded) {
        setState(() => expanded = false);
      }
    });
  }

  @override
  void dispose() {
    _cancelAutoCollapseTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.centerLeft,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SizeTransition(sizeFactor: curved, axis: Axis.horizontal, axisAlignment: -1.0, child: child),
          );
        },
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: [...previousChildren, if (currentChild != null) currentChild],
          );
        },
        child: expanded
            ? ColorPickerButtons(
                key: const ValueKey('picker-expanded'),
                selectedTag: widget.value,
                onSelected: (tag) {
                  _cancelAutoCollapseTimer();
                  widget.onSelected(tag);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) {
                      setState(() => expanded = false);
                    }
                  });
                },
              )
            : IconButton(
                key: const ValueKey('picker-collapsed'),
                icon: Icon(
                  Icons.color_lens_rounded,
                  color: widget.value.toColor() == Colors.transparent ? null : widget.value.toColor(),
                ),
                onPressed: () => setState(() {
                  expanded = !expanded;
                  if (expanded) {
                    _startAutoCollapseTimer();
                  } else {
                    _cancelAutoCollapseTimer();
                  }
                }),
              ),
      ),
    );
  }
}

class ColorPickerButtons extends StatelessWidget {
  final double iconSize;
  final double spacing;
  final ColorTag selectedTag;
  final ValueChanged<ColorTag> onSelected;

  const ColorPickerButtons({
    super.key,
    this.iconSize = 16.0,
    this.spacing = 2.0,
    required this.selectedTag,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      children: ColorTag.values.where((tag) => tag != ColorTag.none).map((tag) {
        final selected = selectedTag == tag;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => {selected ? onSelected(ColorTag.none) : onSelected(tag)},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 2.0),
            child: AnimatedScale(
              scale: selected ? 1.3 : 0.9,
              duration: const Duration(milliseconds: 150),
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tag.toColor()?.withAlpha(selected ? 255 : 198),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: selected ? iconSize / 6.0 : 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PaletteColorPickerButton extends StatelessWidget {
  final ColorTag selectedTag;
  final ValueChanged<ColorTag> onSelected;
  final double iconSize;

  const PaletteColorPickerButton({
    super.key,
    required this.selectedTag,
    required this.onSelected,
    this.iconSize = 22.0,
  });

  String _labelForTag(ColorTag tag) {
    switch (tag) {
      case ColorTag.none:
        return 'color_tag_none'.tr;
      case ColorTag.red:
        return 'color_tag_red'.tr;
      case ColorTag.orange:
        return 'color_tag_orange'.tr;
      case ColorTag.yellow:
        return 'color_tag_yellow'.tr;
      case ColorTag.green:
        return 'color_tag_green'.tr;
      case ColorTag.blue:
        return 'color_tag_blue'.tr;
      case ColorTag.gray:
        return 'color_tag_gray'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasColor = selectedTag != ColorTag.none;
    final activeColor = selectedTag.toColor();

    return PopupMenuButton<ColorTag>(
      tooltip: 'color_picker_tooltip'.tr,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: BorderSide(
          color: theme.dividerColor.withAlpha(40),
          width: 0.8,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 145, maxWidth: 165),
      icon: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: iconSize,
            color: hasColor ? activeColor : null,
          ),
          if (hasColor)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      onSelected: (tag) {
        if (tag == selectedTag) {
          onSelected(ColorTag.none);
        } else {
          onSelected(tag);
        }
      },
      itemBuilder: (popupContext) {
        return ColorTag.values.map((tag) {
          final isSelected = selectedTag == tag;
          final tagColor = tag.toColor();

          return PopupMenuItem<ColorTag>(
            value: tag,
            height: 38.0,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                if (tag == ColorTag.none)
                  Icon(
                    Icons.format_color_reset_outlined,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withAlpha(180),
                  )
                else
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: tagColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? colorScheme.outline : colorScheme.outlineVariant.withAlpha(120),
                        width: isSelected ? 1.5 : 0.8,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _labelForTag(tag),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
