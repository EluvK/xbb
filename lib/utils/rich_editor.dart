import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KCallbackAction<T extends Intent> extends CallbackAction<T> {
  KCallbackAction({required void Function(T) super.onInvoke});
}

class ToggleBoldIntent extends Intent {
  const ToggleBoldIntent();
}

class ToggleItalicIntent extends Intent {
  const ToggleItalicIntent();
}

class RichEditor extends StatefulWidget {
  const RichEditor({
    super.key,
    required this.textEditingController,
  });
  final TextEditingController textEditingController;

  @override
  State<RichEditor> createState() => _RichEditorState();
}

class _RichEditorState extends State<RichEditor> {
  FocusNode focusNode = FocusNode();
  late TextEditingController textEditingController;

  // shortcut key binding
  late final KCallbackAction<ToggleBoldIntent> _toggleBoldAction;
  late final KCallbackAction<ToggleItalicIntent> _toggleItalicAction;
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ToggleBoldIntent: _toggleBoldAction,
    ToggleItalicIntent: _toggleItalicAction,
  };

  @override
  void initState() {
    textEditingController = widget.textEditingController;
    _toggleBoldAction = KCallbackAction<ToggleBoldIntent>(
      onInvoke: (ToggleBoldIntent intent) {
        _toggleBold();
      },
    );
    _toggleItalicAction = KCallbackAction<ToggleItalicIntent>(
      onInvoke: (ToggleItalicIntent intent) {
        _toggleItalic();
      },
    );
    super.initState();
  }

  Shortcuts shortcuts(Widget child) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            const ToggleBoldIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyI):
            const ToggleItalicIntent(),
      },
      child: Actions(
        actions: _actionMap,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var body = Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: _toggleBold,
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: _toggleItalic,
            ),
          ],
        ),
        Expanded(
          child: TextField(
            focusNode: focusNode,
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            controller: textEditingController,
            decoration: const InputDecoration(
              labelText: 'contents:',
              alignLabelWithHint: true,
            ),
          ),
        ),
      ],
    );
    return shortcuts(body);
  }

  void _toggleBold() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;
    if (selection.isCollapsed) return;

    final selectedText = text.substring(selection.start, selection.end);
    final isBold = selectedText.startsWith('**') && selectedText.endsWith('**');
    final isItalic = selectedText.startsWith('*') && selectedText.endsWith('*');
    String newText;

    if (isBold) {
      newText = selectedText.substring(2, selectedText.length - 2);
    } else if (isItalic) {
      newText = '**${selectedText.substring(1, selectedText.length - 1)}**';
    } else {
      newText = '**$selectedText**';
    }

    textEditingController.value = TextEditingValue(
      text: text.replaceRange(selection.start, selection.end, newText),
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + newText.length,
      ),
    );
    focusNode.requestFocus();
  }

  void _toggleItalic() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;
    if (selection.isCollapsed) return;

    final selectedText = text.substring(selection.start, selection.end);
    final isBold = selectedText.startsWith('**') && selectedText.endsWith('**');
    final isItalic = selectedText.startsWith('*') && selectedText.endsWith('*');
    String newText;

    if (isItalic) {
      newText = selectedText.substring(1, selectedText.length - 1);
    } else if (isBold) {
      newText = '*${selectedText.substring(2, selectedText.length - 2)}*';
    } else {
      newText = '*$selectedText*';
    }

    textEditingController.value = TextEditingValue(
      text: text.replaceRange(selection.start, selection.end, newText),
      selection: TextSelection(
        baseOffset: selection.start,
        extentOffset: selection.start + newText.length,
      ),
    );
    focusNode.requestFocus();
  }
}
