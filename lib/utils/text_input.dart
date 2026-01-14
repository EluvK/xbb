import 'package:flutter/material.dart';

abstract interface class TitleInterface {
  String get _title;
  IconData get _icon;
  Color get _color;
}

enum SyncStoreInputMetaEnum implements TitleInterface {
  address,
  enableTunnel;

  @override
  Color get _color {
    switch (this) {
      case SyncStoreInputMetaEnum.address:
        return Colors.orange;
      case SyncStoreInputMetaEnum.enableTunnel:
        return Colors.blue;
    }
  }

  @override
  IconData get _icon {
    switch (this) {
      case SyncStoreInputMetaEnum.address:
        return Icons.cloud;
      case SyncStoreInputMetaEnum.enableTunnel:
        return Icons.link;
    }
  }

  @override
  String get _title {
    switch (this) {
      case SyncStoreInputMetaEnum.address:
        return '服务器地址';
      case SyncStoreInputMetaEnum.enableTunnel:
        return '启用加密隧道';
    }
  }
}

enum AppSettingMetaEnum implements TitleInterface {
  themeMode,
  language,
  fontScale;

  @override
  Color get _color {
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
  IconData get _icon {
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
  String get _title {
    switch (this) {
      case AppSettingMetaEnum.themeMode:
        return '主题模式';
      case AppSettingMetaEnum.language:
        return '语言';
      case AppSettingMetaEnum.fontScale:
        return '字体大小';
    }
  }
}

enum InputTitleEnum implements TitleInterface {
  title,
  description;

  @override
  Color get _color {
    switch (this) {
      case InputTitleEnum.title:
        return Colors.blue;
      case InputTitleEnum.description:
        return Colors.green;
    }
  }

  @override
  IconData get _icon {
    switch (this) {
      case InputTitleEnum.title:
        return Icons.title;
      case InputTitleEnum.description:
        return Icons.description;
    }
  }

  @override
  String get _title {
    switch (this) {
      case InputTitleEnum.title:
        return '名称';
      case InputTitleEnum.description:
        return '描述';
    }
  }
}

class TextInputWidget extends StatelessWidget {
  TextInputWidget({
    super.key,
    required this.title,
    required this.onChanged,
    required this.initialValue,
    this.onFocusChange,
    this.autoFocus = false,
    this.optional = false,
  });
  final focusNode = FocusNode();

  final TitleInterface title;
  final String initialValue;
  final void Function(bool)? onFocusChange;
  final bool autoFocus;
  final bool optional;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          focusNode.requestFocus();
        },
        onFocusChange: onFocusChange,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
          child: Row(
            children: [
              Material(
                color: title._color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(title._icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // flex: 1,
                child: Text(title._title, style: Theme.of(context).textTheme.bodyMedium),
              ),
              Flexible(
                flex: 2,
                child: TextField(
                  autofocus: autoFocus,
                  focusNode: focusNode,
                  controller: TextEditingController(text: initialValue),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.all(8),
                    hintText: optional ? '(可选)' : '',
                    hintStyle: const TextStyle(color: Colors.grey),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    print(value);
                    onChanged(value);
                  },
                ),
              ),
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
                color: title._color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(title._icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title._title, style: Theme.of(context).textTheme.bodyMedium),
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
                color: title._color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(title._icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title._title, style: Theme.of(context).textTheme.bodyMedium)),
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
