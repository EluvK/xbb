import 'package:flutter/material.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/utils/double_click.dart';

/// A generic ListTileCard widget to display DataItem<T> information.
class ListTileCard<T> extends StatefulWidget {
  const ListTileCard({
    super.key,
    required this.dataItem,
    required this.onUpdateLocalField,
    this.title,
    this.subtitle,
    required this.onTap,
    this.enableLongPressPreview,
    this.isSelected = false,
    this.enableSwitchArchivedStatus = true,
    this.enableSwitchColorTag = true,
    this.onEditButton,
    this.onDeleteButton,
    this.onDeleteButtonCondition,
    this.enableChildrenUpdateNumber,
  });

  final DataItem<T> dataItem;
  final Function({ColorTag? colorTag, SyncStatus? syncStatus}) onUpdateLocalField;
  final String? title;
  final String? subtitle;
  final Function() onTap;

  // todo add Badge for new/updated items

  /// Content to show on long press preview
  final String? enableLongPressPreview;

  /// Selected card show extra border
  final bool isSelected;

  final bool enableSwitchArchivedStatus;
  final bool enableSwitchColorTag;
  final Function()? onEditButton;
  final Function()? onDeleteButton;
  final bool Function()? onDeleteButtonCondition;
  final int Function()? enableChildrenUpdateNumber;

  @override
  State<ListTileCard<T>> createState() => _ListTileCardState<T>();
}

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

enum _MoreContentState { none, buttons, preview }

class _ListTileCardState<T> extends State<ListTileCard<T>> {
  var moreContentState = _MoreContentState.none;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    var isNew = widget.dataItem.syncStatus == SyncStatus.synced;
    var isArchived = widget.dataItem.syncStatus == SyncStatus.archived;
    var isDeleted = widget.dataItem.syncStatus == SyncStatus.deleted;
    var isFailed = widget.dataItem.syncStatus == SyncStatus.failed;

    List<Widget> leadingIcons = [];
    if (isFailed) {
      leadingIcons.add(const Icon(Icons.sync_disabled_rounded, color: Colors.redAccent, size: 16));
    }
    if (widget.enableChildrenUpdateNumber != null) {
      int updateNumber = widget.enableChildrenUpdateNumber!();
      if (updateNumber > 0) {
        leadingIcons.add(Text("✨$updateNumber", style: const TextStyle(fontSize: 12)));
      }
    }

    if (isNew) {
      leadingIcons.add(const Icon(Icons.star_outline_rounded, color: Colors.redAccent, size: 16));
    }
    if (isDeleted) {
      leadingIcons.add(const Icon(Icons.delete, color: Colors.grey, size: 16));
    }
    if (widget.dataItem.colorTag != ColorTag.none) {
      leadingIcons.add(Icon(Icons.brightness_1_rounded, color: widget.dataItem.colorTag.toColor(), size: 16));
    }

    Widget listTile = ListTile(
      title: Text(
        widget.title ?? widget.dataItem.id,
        style: TextStyle(decoration: isDeleted ? TextDecoration.lineThrough : null, fontSize: 18),
      ),
      subtitle: widget.subtitle != null
          ? Text(
              widget.subtitle!,
              style: TextStyle(decoration: isDeleted ? TextDecoration.lineThrough : null, fontSize: 14),
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
      minLeadingWidth: 0,
      leading: Column(mainAxisAlignment: MainAxisAlignment.spaceAround, children: leadingIcons),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(() {
              moreContentState = moreContentState == _MoreContentState.buttons
                  ? _MoreContentState.none
                  : _MoreContentState.buttons;
            }),
            icon: Icon(color: colorScheme.primary, Icons.more_horiz),
          ),
        ],
      ),
      onTap: () {
        if (isNew) {
          setState(() {
            widget.onUpdateLocalField(syncStatus: SyncStatus.archived);
          });
        }
        widget.onTap();
      },
      onLongPress: (widget.enableLongPressPreview != null)
          ? () => setState(() {
              moreContentState = moreContentState == _MoreContentState.preview
                  ? _MoreContentState.none
                  : _MoreContentState.preview;
            })
          : null,
    );

    Widget? moreContent;
    if (moreContentState == _MoreContentState.buttons) {
      List<Widget> buttons = [];
      if (widget.enableSwitchArchivedStatus && (isNew || isArchived)) {
        buttons.add(
          IconButton(
            onPressed: () {
              setState(() {
                if (isArchived) {
                  widget.onUpdateLocalField(syncStatus: SyncStatus.synced);
                } else if (isNew) {
                  widget.onUpdateLocalField(syncStatus: SyncStatus.archived);
                }
              });
            },
            icon: isArchived ? const Icon(Icons.mark_email_unread_rounded) : const Icon(Icons.mark_email_read_rounded),
            tooltip: isArchived ? '标记未读' : '标记已读',
          ),
        );
      }
      if (widget.onEditButton != null) {
        buttons.add(IconButton(onPressed: widget.onEditButton, icon: const Icon(Icons.edit_rounded), tooltip: '编辑'));
      }
      if (widget.enableSwitchColorTag) {
        buttons.add(
          InlineColorPickerButton(
            value: widget.dataItem.colorTag,
            onSelected: (tag) {
              setState(() {
                widget.onUpdateLocalField(colorTag: tag);
              });
            },
          ),
        );
      }
      if (widget.onDeleteButton != null) {
        buttons.add(
          DoubleClickButton(
            buttonBuilder: (onPressed) =>
                IconButton(onPressed: onPressed, icon: const Icon(Icons.delete_rounded), tooltip: '删除'),
            onDoubleClick: widget.onDeleteButton!,
            firstClickHint: '双击删除',
            firstClickCheckCondition: widget.onDeleteButtonCondition,
            upperPosition: true,
          ),
        );
      }
      moreContent = Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: buttons);
    } else if (moreContentState == _MoreContentState.preview) {
      moreContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(widget.enableLongPressPreview ?? ''),
      );
    }

    return Card(
      shadowColor: widget.isSelected ? Colors.lightGreen[400] : Colors.grey,
      elevation: widget.isSelected ? 4.0 : 2.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          listTile,
          Visibility(visible: moreContent != null, child: const Divider()),
          Visibility(visible: moreContent != null, child: moreContent ?? Container()),
        ],
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: expanded
          ? ColorPickerButtons(
              selectedTag: widget.value,
              onSelected: (tag) {
                widget.onSelected(tag);
                // should wait for inner animation to finish
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() => expanded = false);
                  }
                });
              },
            )
          : IconButton(
              icon: const Icon(Icons.color_lens_rounded),
              onPressed: () => setState(() => expanded = !expanded),
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
            // add padding for easier tap area
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
