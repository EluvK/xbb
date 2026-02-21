import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  settings;

  @override
  Color get gColor {
    switch (this) {
      case AppFeatureMetaEnum.enableNotes:
        return Colors.green;
      case AppFeatureMetaEnum.settings:
        return Colors.grey;
    }
  }

  @override
  IconData get gIcon {
    switch (this) {
      case AppFeatureMetaEnum.enableNotes:
        return Icons.library_books_outlined;
      case AppFeatureMetaEnum.settings:
        return Icons.settings_rounded;
    }
  }

  @override
  String get gTitle {
    switch (this) {
      case AppFeatureMetaEnum.enableNotes:
        return 'app_enable_note_feature'.tr;
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
                // flex: 1,
                child: Text(title.gTitle, style: Theme.of(context).textTheme.bodyMedium),
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
                    hintText: optional ? 'optional'.tr : '',
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
