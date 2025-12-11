import 'package:flutter/material.dart';

enum InputTitleEnum { title, description }

extension InputTitleExtension on InputTitleEnum {
  String get title {
    switch (this) {
      case InputTitleEnum.title:
        return '名称';
      case InputTitleEnum.description:
        return '描述';
    }
  }

  IconData get icon {
    switch (this) {
      case InputTitleEnum.title:
        return Icons.title;
      case InputTitleEnum.description:
        return Icons.description;
    }
  }

  Color get color {
    switch (this) {
      case InputTitleEnum.title:
        return Colors.blue;
      case InputTitleEnum.description:
        return Colors.green;
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

  final InputTitleEnum title;
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
                color: title.color,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: Center(child: Icon(title.icon, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                // flex: 1,
                child: Text(title.title, style: Theme.of(context).textTheme.bodyMedium),
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
