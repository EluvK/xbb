import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/utils/utils.dart';

abstract interface class TitleInterface {
  String get gTitle;
  IconData get gIcon;
  Color get gColor;
}

enum SyncStoreInputMetaEnum implements TitleInterface {
  address,
  enableTunnel;

  @override
  Color get gColor {
    switch (this) {
      case SyncStoreInputMetaEnum.address:
        return Colors.orange;
      case SyncStoreInputMetaEnum.enableTunnel:
        return Colors.blue;
    }
  }

  @override
  IconData get gIcon {
    switch (this) {
      case SyncStoreInputMetaEnum.address:
        return Icons.cloud;
      case SyncStoreInputMetaEnum.enableTunnel:
        return Icons.link;
    }
  }

  @override
  String get gTitle {
    switch (this) {
      case SyncStoreInputMetaEnum.address:
        return 'app_server_url'.tr;
      case SyncStoreInputMetaEnum.enableTunnel:
        return 'app_enable_tunnel'.tr;
    }
  }
}

enum AppSettingMetaEnum implements TitleInterface {
  themeMode,
  language,
  fontScale;

  @override
  Color get gColor {
    switch (this) {
      case AppSettingMetaEnum.themeMode:
        return Colors.purple;
      case AppSettingMetaEnum.language:
        return Colors.teal;
      case AppSettingMetaEnum.fontScale:
        return Colors.indigo;
    }
  }

  @override
  IconData get gIcon {
    switch (this) {
      case AppSettingMetaEnum.themeMode:
        return Icons.brightness_6;
      case AppSettingMetaEnum.language:
        return Icons.language;
      case AppSettingMetaEnum.fontScale:
        return Icons.format_size;
    }
  }

  @override
  String get gTitle {
    switch (this) {
      case AppSettingMetaEnum.themeMode:
        return 'app_theme_mode'.tr;
      case AppSettingMetaEnum.language:
        return 'app_language'.tr;
      case AppSettingMetaEnum.fontScale:
        return 'app_font_scale'.tr;
    }
  }
}

enum AppFeatureMetaEnum implements TitleInterface {
  enableNotes,
  enableTracker,
  enableTask,
  enableClipboardBackup,
  enableClipboardListening,
  enableChat,
  startupTab,
  taskWidget,
  settings;

  @override
  Color get gColor {
    switch (this) {
      case AppFeatureMetaEnum.enableNotes:
        return Colors.green;
      case AppFeatureMetaEnum.enableTracker:
        return Colors.orange;
      case AppFeatureMetaEnum.enableTask:
        return Colors.teal;
      case AppFeatureMetaEnum.enableClipboardBackup:
        return Colors.deepPurple;
      case AppFeatureMetaEnum.enableClipboardListening:
        return Colors.indigo;
      case AppFeatureMetaEnum.enableChat:
        return Colors.blueAccent;
      case AppFeatureMetaEnum.startupTab:
        return Colors.cyan;
      case AppFeatureMetaEnum.taskWidget:
        return Colors.blue;
      case AppFeatureMetaEnum.settings:
        return Colors.grey;
    }
  }

  @override
  IconData get gIcon {
    switch (this) {
      case AppFeatureMetaEnum.enableNotes:
        return Icons.library_books_outlined;
      case AppFeatureMetaEnum.enableTracker:
        return Icons.track_changes;
      case AppFeatureMetaEnum.enableTask:
        return Icons.check_box_rounded;
      case AppFeatureMetaEnum.enableClipboardBackup:
        return Icons.content_paste_rounded;
      case AppFeatureMetaEnum.enableClipboardListening:
        return Icons.hearing_rounded;
      case AppFeatureMetaEnum.enableChat:
        return Icons.chat_rounded;
      case AppFeatureMetaEnum.startupTab:
        return Icons.play_circle_outline_rounded;
      case AppFeatureMetaEnum.taskWidget:
        return Icons.add_to_home_screen_rounded;
      case AppFeatureMetaEnum.settings:
        return Icons.settings_rounded;
    }
  }

  @override
  String get gTitle {
    switch (this) {
      case AppFeatureMetaEnum.enableNotes:
        return 'app_enable_note_feature'.tr;
      case AppFeatureMetaEnum.enableTracker:
        return 'app_enable_tracker_feature'.tr;
      case AppFeatureMetaEnum.enableTask:
        return 'app_enable_task_feature'.tr;
      case AppFeatureMetaEnum.enableClipboardBackup:
        return 'app_enable_clipboard_backup_feature'.tr;
      case AppFeatureMetaEnum.enableClipboardListening:
        return 'app_enable_clipboard_listening_feature'.tr;
      case AppFeatureMetaEnum.enableChat:
        return 'app_enable_chat_feature'.tr;
      case AppFeatureMetaEnum.startupTab:
        return 'app_startup_tab'.tr;
      case AppFeatureMetaEnum.taskWidget:
        return 'task_widget_label'.tr;
      case AppFeatureMetaEnum.settings:
        return 'app_enable_setting'.tr;
    }
  }
}

enum InputTitleEnum implements TitleInterface {
  title,
  description;

  @override
  Color get gColor {
    switch (this) {
      case InputTitleEnum.title:
        return Colors.blue;
      case InputTitleEnum.description:
        return Colors.green;
    }
  }

  @override
  IconData get gIcon {
    switch (this) {
      case InputTitleEnum.title:
        return Icons.title;
      case InputTitleEnum.description:
        return Icons.description;
    }
  }

  @override
  String get gTitle {
    switch (this) {
      case InputTitleEnum.title:
        return 'input_title'.tr;
      case InputTitleEnum.description:
        return 'input_description'.tr;
    }
  }
}

class TextInputWidget extends StatefulWidget {
  const TextInputWidget({
    super.key,
    required this.title,
    required this.onFinished,
    required this.initialValue,
    this.onFocusChange,
    this.autoFocus = false,
    this.optional = false,
    this.helperText,
    this.inputType,
    this.tailButton,
  });
  final TitleInterface title;
  final String initialValue;
  final void Function(bool)? onFocusChange;
  final bool autoFocus;
  final bool optional;
  final void Function(String) onFinished;
  final String? helperText;
  final TextInputType? inputType;
  final Widget? tailButton;

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  String? _lastCommittedValue;

  void _ensureVisibleAfterFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusNode.hasFocus) return;
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.25,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _commitInput({bool showSavedTip = false}) {
    final value = _controller.text;
    if (_lastCommittedValue == value) {
      return;
    }
    _lastCommittedValue = value;
    widget.onFinished(value);
    if (showSavedTip) {
      successSimpleFlushBar('input_saved'.tr);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _lastCommittedValue = widget.initialValue;

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _ensureVisibleAfterFocus();
      } else {
        _commitInput();
      }
    });
  }

  @override
  void didUpdateWidget(covariant TextInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && _controller.text != widget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _focusNode.requestFocus();
        },
        onFocusChange: widget.onFocusChange,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: widget.title.gColor,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(widget.title.gIcon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // flex: 1,
                child: Text(widget.title.gTitle, style: Theme.of(context).textTheme.bodyMedium),
              ),
              Flexible(
                flex: 2,
                child: TextField(
                  autofocus: widget.autoFocus,
                  focusNode: _focusNode,
                  controller: _controller,
                  scrollPadding: EdgeInsets.only(
                    left: 20,
                    top: 20,
                    right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 100,
                  ),
                  onTapOutside: (_) {
                    _focusNode.unfocus();
                    _commitInput();
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.all(8),
                    hintText: widget.optional ? 'optional'.tr : '',
                    hintStyle: const TextStyle(color: Colors.grey),
                    helperText: widget.helperText,
                  ),
                  keyboardType: widget.inputType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  onSubmitted: (value) {
                    print(value);
                    _commitInput(showSavedTip: true);
                  },
                ),
              ),
              if (widget.tailButton != null) ...[const SizedBox(width: 8), widget.tailButton!],
            ],
          ),
        ),
      ),
    );
  }
}

class UserDefinedInputWidget extends StatelessWidget {
  const UserDefinedInputWidget({super.key, required this.title, required this.widget});
  final TitleInterface title;
  final Widget widget;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: title.gColor,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(title.gIcon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title.gTitle, style: Theme.of(context).textTheme.bodyMedium),
                // flex: 1,
              ),
              Flexible(
                flex: 2,
                child: Align(alignment: Alignment.centerRight, child: widget),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BoolSelectorInputWidget extends StatelessWidget {
  const BoolSelectorInputWidget({super.key, required this.title, required this.initialValue, required this.onChanged});
  final TitleInterface title;
  final bool initialValue;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: title.gColor,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(title.gIcon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title.gTitle, style: Theme.of(context).textTheme.bodyMedium)),
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Switch(value: initialValue, onChanged: (newValue) => onChanged(newValue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
