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

class ToggleEnterIntent extends Intent {
  const ToggleEnterIntent();
}

class ToggleTabIntent extends Intent {
  final bool isShift;
  const ToggleTabIntent({this.isShift = false});
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
  late final KCallbackAction<ToggleEnterIntent> _toggleEnterAction;
  late final KCallbackAction<ToggleTabIntent> _toggleTabAction;
  late final Map<Type, Action<Intent>> _actionMap = <Type, Action<Intent>>{
    ToggleBoldIntent: _toggleBoldAction,
    ToggleItalicIntent: _toggleItalicAction,
    ToggleEnterIntent: _toggleEnterAction,
    ToggleTabIntent: _toggleTabAction,
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
    _toggleEnterAction = KCallbackAction<ToggleEnterIntent>(
      onInvoke: (ToggleEnterIntent intent) {
        _toggleEnter();
      },
    );
    _toggleTabAction = KCallbackAction<ToggleTabIntent>(
      onInvoke: (ToggleTabIntent intent) {
        _toggleTab(isShift: intent.isShift);
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
        const SingleActivator(LogicalKeyboardKey.enter):
            const ToggleEnterIntent(),
        const SingleActivator(LogicalKeyboardKey.tab): const ToggleTabIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
            const ToggleTabIntent(isShift: true),
      },
      child: Actions(
        actions: _actionMap,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var body = Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: _toggleBold,
              tooltip: 'Ctrl+B',
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: _toggleItalic,
              tooltip: 'Ctrl+I',
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              onPressed: _toggleList,
              tooltip: 'List',
            ),
            IconButton(
              icon: const Icon(Icons.format_list_numbered),
              onPressed: _toggleOrderedList,
              tooltip: 'Order List',
            ),
            IconButton(
              icon: const Icon(Icons.check_box),
              onPressed: _toggleCheckBox,
              tooltip: 'Check Box',
            ),
            IconButton(
              icon: const Icon(Icons.horizontal_rule),
              onPressed: _toggleHorizontalRule,
              tooltip: 'Horizontal Rule',
            )
          ],
        ),
        Expanded(
          child: TextField(
            focusNode: focusNode,
            expands: true,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            controller: textEditingController,
            decoration: InputDecoration(
              labelText: 'contents:',
              alignLabelWithHint: true,
              hoverColor: colorScheme.surface.withOpacity(0.2),
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

    if (selection.isCollapsed) {
      // 没有选中文本，在光标位置插入或移除加粗标记
      final cursorPosition = selection.baseOffset;
      const prefix = '**';
      const suffix = '**';

      // 检查光标前后是否有加粗标记
      final hasBoldBefore = cursorPosition >= prefix.length &&
          text.substring(cursorPosition - prefix.length, cursorPosition) ==
              prefix;
      final hasBoldAfter = cursorPosition + suffix.length <= text.length &&
          text.substring(cursorPosition, cursorPosition + suffix.length) ==
              suffix;

      if (hasBoldBefore && hasBoldAfter) {
        // 如果光标前后都有加粗标记，移除它们
        final newText = text.replaceRange(
            cursorPosition - prefix.length, cursorPosition + suffix.length, '');
        textEditingController.value = TextEditingValue(
          text: newText,
          selection:
              TextSelection.collapsed(offset: cursorPosition - prefix.length),
        );
      } else {
        // 否则，插入加粗标记
        final newText =
            text.replaceRange(cursorPosition, cursorPosition, '$prefix$suffix');
        textEditingController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
              offset: cursorPosition + prefix.length), // 光标放在标记中间
        );
      }
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final isBold =
          selectedText.startsWith('**') && selectedText.endsWith('**');
      final isItalic =
          selectedText.startsWith('*') && selectedText.endsWith('*');
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
    }
    focusNode.requestFocus();
  }

  void _toggleItalic() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;
    // if (selection.isCollapsed) return;
    if (selection.isCollapsed) {
      // 没有选中文本，在光标位置插入或移除斜体标记
      final cursorPosition = selection.baseOffset;
      const prefix = '*';
      const suffix = '*';

      // 检查光标前后是否有斜体标记
      final hasItalicBefore = cursorPosition >= prefix.length &&
          text.substring(cursorPosition - prefix.length, cursorPosition) ==
              prefix;
      final hasItalicAfter = cursorPosition + suffix.length <= text.length &&
          text.substring(cursorPosition, cursorPosition + suffix.length) ==
              suffix;

      if (hasItalicBefore && hasItalicAfter) {
        // 如果光标前后都有斜体标记，移除它们
        final newText = text.replaceRange(
            cursorPosition - prefix.length, cursorPosition + suffix.length, '');
        textEditingController.value = TextEditingValue(
          text: newText,
          selection:
              TextSelection.collapsed(offset: cursorPosition - prefix.length),
        );
      } else {
        // 否则，插入斜体标记
        final newText =
            text.replaceRange(cursorPosition, cursorPosition, '$prefix$suffix');
        textEditingController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(
              offset: cursorPosition + prefix.length), // 光标放在标记中间
        );
      }
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final isBold =
          selectedText.startsWith('**') && selectedText.endsWith('**');
      final isItalic =
          selectedText.startsWith('*') && selectedText.endsWith('*');
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
    }
    focusNode.requestFocus();
  }

  void _toggleList() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isCollapsed) {
      // 没有选中文本，只在当前行添加/移除列表标记
      final cursorPosition = selection.baseOffset;
      final lineStart = cursorPosition == 0
          ? 0
          : text.lastIndexOf('\n', cursorPosition - 1) + 1;
      final lineEnd = text.indexOf('\n', cursorPosition);
      final lineEndSafe = lineEnd == -1 ? text.length : lineEnd; // 处理没有换行符的情况
      final lineText = text.substring(lineStart, lineEndSafe);

      // 判断当前行是否已经有列表标记
      if (lineText.startsWith('- ')) {
        // 如果有列表标记，移除它
        final newText = lineText.substring(2);
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
          selection: TextSelection.collapsed(offset: cursorPosition - 2),
        );
      } else {
        // 如果没有列表标记，添加它
        final newText = '- $lineText';
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
          selection: TextSelection.collapsed(offset: cursorPosition + 2),
        );
      }
    } else {
      // 选中了多行文本，在每一行前面添加/移除列表标记
      final start = selection.start;
      final end = selection.end;

      // 找到选中区域的起始行和结束行
      final startLineStart =
          start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
      final endLineEnd = text.indexOf('\n', end);
      final endLineEndSafe =
          endLineEnd == -1 ? text.length : endLineEnd; // 处理没有换行符的情况
      final selectedText = text.substring(startLineStart, endLineEndSafe);

      // 按行分割选中的文本
      final lines = selectedText.split('\n');
      final modifiedLines = lines.map((line) {
        if (line.startsWith('- ')) {
          // 如果已经有列表标记，移除它
          return line.substring(2);
        } else {
          // 如果没有列表标记，添加它
          return '- $line';
        }
      }).join('\n');

      // 更新文本和选中区域
      textEditingController.value = textEditingController.value.copyWith(
        text: text.replaceRange(startLineStart, endLineEndSafe, modifiedLines),
        selection: TextSelection(
            baseOffset: startLineStart,
            extentOffset: startLineStart + modifiedLines.length),
      );
    }
    focusNode.requestFocus();
  }

  void _toggleOrderedList() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isCollapsed) {
      // 没有选中文本，只在当前行添加/移除有序列表标记
      final cursorPosition = selection.baseOffset;
      final lineStart = cursorPosition == 0
          ? 0
          : text.lastIndexOf('\n', cursorPosition - 1) + 1;
      final lineEnd = text.indexOf('\n', cursorPosition);
      final lineEndSafe = lineEnd == -1 ? text.length : lineEnd; // 处理没有换行符的情况
      final lineText = text.substring(lineStart, lineEndSafe);

      // 判断当前行是否已经有序列表标记
      final orderedListRegex = RegExp(r'^\d+\. ');
      if (orderedListRegex.hasMatch(lineText)) {
        // 如果有有序列表标记，移除它
        final newText = lineText.replaceFirst(orderedListRegex, '');
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
          selection: TextSelection.collapsed(
              offset: cursorPosition - lineText.indexOf(' ')),
        );
      } else {
        // 如果没有有序列表标记，添加它
        // 找到前面最近的有序列表行，确定当前行的编号
        int currentNumber = 1;
        int previousLineEnd = lineStart - 1;
        while (previousLineEnd >= 0) {
          final previousLineStart = previousLineEnd == 0
              ? 0
              : text.lastIndexOf('\n', previousLineEnd - 1) + 1;
          final previousLineText =
              text.substring(previousLineStart, previousLineEnd);
          if (orderedListRegex.hasMatch(previousLineText)) {
            // 找到前面最近的有序列表行，提取编号并加1
            final match = orderedListRegex.firstMatch(previousLineText);
            if (match != null) {
              currentNumber =
                  int.parse(match.group(0)!.replaceFirst('.', '')) + 1;
            }
            break;
          } else if (previousLineText.trim().isNotEmpty) {
            // 如果前面有非空行但不是有序列表，从1开始
            break;
          }
          previousLineEnd = previousLineStart - 1;
        }

        final newText = '$currentNumber. $lineText';
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
          selection: TextSelection.collapsed(
              offset: cursorPosition + newText.length - lineText.length),
        );
      }
    } else {
      // 选中了多行文本，在每一行前面添加/移除有序列表标记
      final start = selection.start;
      final end = selection.end;

      // 找到选中区域的起始行和结束行
      final startLineStart =
          start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
      final endLineEnd = text.indexOf('\n', end);
      final endLineEndSafe =
          endLineEnd == -1 ? text.length : endLineEnd; // 处理没有换行符的情况
      final selectedText = text.substring(startLineStart, endLineEndSafe);

      // 按行分割选中的文本
      final lines = selectedText.split('\n');
      int currentNumber = 1;

      // 找到前面最近的有序列表行，确定起始编号
      int previousLineEnd = startLineStart - 1;
      while (previousLineEnd >= 0) {
        final previousLineStart = previousLineEnd == 0
            ? 0
            : text.lastIndexOf('\n', previousLineEnd - 1) + 1;
        final previousLineText =
            text.substring(previousLineStart, previousLineEnd);
        final orderedListRegex = RegExp(r'^\d+\. ');
        if (orderedListRegex.hasMatch(previousLineText)) {
          // 找到前面最近的有序列表行，提取编号并加1
          final match = orderedListRegex.firstMatch(previousLineText);
          if (match != null) {
            currentNumber =
                int.parse(match.group(0)!.replaceFirst('.', '')) + 1;
          }
          break;
        } else if (previousLineText.trim().isNotEmpty) {
          // 如果前面有非空行但不是有序列表，从1开始
          break;
        }
        previousLineEnd = previousLineStart - 1;
      }

      final modifiedLines = lines.map((line) {
        final orderedListRegex = RegExp(r'^\d+\. ');
        if (orderedListRegex.hasMatch(line)) {
          // 如果已经有有序列表标记，移除它
          return line.replaceFirst(orderedListRegex, '');
        } else {
          // 如果没有有序列表标记，添加它
          return '${currentNumber++}. $line';
        }
      }).join('\n');

      // 更新文本和选中区域
      textEditingController.value = textEditingController.value.copyWith(
        text: text.replaceRange(startLineStart, endLineEndSafe, modifiedLines),
        selection: TextSelection(
            baseOffset: startLineStart,
            extentOffset: startLineStart + modifiedLines.length),
      );
    }
    focusNode.requestFocus();
  }

  void _toggleCheckBox() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isCollapsed) {
      // 没有选中文本，只在当前行添加/移除复选框标记
      final cursorPosition = selection.baseOffset;
      final lineStart = cursorPosition == 0
          ? 0
          : text.lastIndexOf('\n', cursorPosition - 1) + 1;
      final lineEnd = text.indexOf('\n', cursorPosition);
      final lineEndSafe = lineEnd == -1 ? text.length : lineEnd; // 处理没有换行符的情况
      final lineText = text.substring(lineStart, lineEndSafe);

      // 判断当前行是否已经有复选框标记
      if (lineText.startsWith('- [ ] ')) {
        // 如果有复选框标记，切换为选中状态
        final newText = lineText.replaceFirst('- [ ] ', '- [x] ');
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
          selection: TextSelection.collapsed(offset: cursorPosition),
        );
      } else if (lineText.startsWith('- [x] ')) {
        // 如果复选框已经选中，移除复选框标记
        final newText = lineText.replaceFirst('- [x] ', '');
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
          selection: TextSelection.collapsed(offset: cursorPosition - 6),
        );
      } else {
        // 如果没有复选框标记，添加未选中状态的复选框
        final newText = '- [ ] $lineText';
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
          selection: TextSelection.collapsed(offset: cursorPosition + 6),
        );
      }
    } else {
      // 选中了多行文本，在每一行前面添加/移除复选框标记
      final start = selection.start;
      final end = selection.end;

      // 找到选中区域的起始行和结束行
      final startLineStart =
          start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
      final endLineEnd = text.indexOf('\n', end);
      final endLineEndSafe =
          endLineEnd == -1 ? text.length : endLineEnd; // 处理没有换行符的情况
      final selectedText = text.substring(startLineStart, endLineEndSafe);

      // 按行分割选中的文本
      final lines = selectedText.split('\n');
      final modifiedLines = lines.map((line) {
        if (line.startsWith('- [ ] ')) {
          // 如果复选框未选中，切换为选中状态
          return line.replaceFirst('- [ ] ', '- [x] ');
        } else if (line.startsWith('- [x] ')) {
          // 如果复选框已经选中，移除复选框标记
          return line.replaceFirst('- [x] ', '');
        } else {
          // 如果没有复选框标记，添加未选中状态的复选框
          return '- [ ] $line';
        }
      }).join('\n');

      // 更新文本和选中区域
      textEditingController.value = textEditingController.value.copyWith(
        text: text.replaceRange(startLineStart, endLineEndSafe, modifiedLines),
        selection: TextSelection(
            baseOffset: startLineStart,
            extentOffset: startLineStart + modifiedLines.length),
      );
    }
    focusNode.requestFocus();
  }

  void _toggleHorizontalRule() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isCollapsed) {
      // 没有选中文本，在光标位置插入水平分割线，光标自动移动到下一行
      final cursorPosition = selection.baseOffset;
      final newText = '\n---\n';
      textEditingController.value = textEditingController.value.copyWith(
        text: text.replaceRange(cursorPosition, cursorPosition, newText),
        selection: TextSelection.collapsed(offset: cursorPosition + 5),
      );
    } else {
      // 选中了文本，在选中区域前后插入水平分割线
      final start = selection.start;
      final end = selection.end;
      final newText = '\n---\n';
      textEditingController.value = textEditingController.value.copyWith(
        text: text.replaceRange(start, end, newText),
        selection: TextSelection.collapsed(offset: start + 5),
      );
    }
    focusNode.requestFocus();
  }

  void _toggleEnter() {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isCollapsed) {
      final cursorPosition = selection.baseOffset;

      // 找到当前行的起始和结束位置
      final lineStart = cursorPosition == 0
          ? 0
          : text.lastIndexOf('\n', cursorPosition - 1) + 1;
      final lineEnd = text.indexOf('\n', cursorPosition);
      final lineEndSafe = lineEnd == -1 ? text.length : lineEnd; // 处理没有换行符的情况
      final lineText = text.substring(lineStart, lineEndSafe);

      // 判断当前行是否是列表项
      final orderedListRegex = RegExp(r'^\d+\. ');
      final checkboxRegex = RegExp(r'^- \[[ x]\] '); // 匹配复选框标记 - [ ] 或 - [x]

      if (lineText.startsWith('- ')) {
        // 如果当前行是无序列表
        if (lineText.trim() == '-') {
          // 如果当前行是只有标记的空列表，去掉列表标记
          final newText = text.replaceRange(lineStart, lineEndSafe, '');
          textEditingController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: lineStart),
          );
        } else if (checkboxRegex.hasMatch(lineText)) {
          // 如果当前行是复选框
          final match = checkboxRegex.firstMatch(lineText);
          if (match != null) {
            final checkboxPrefix =
                match.group(0)!; // 获取复选框标记（如 "- [ ] " 或 "- [x] "）
            final contentAfterPrefix =
                lineText.substring(checkboxPrefix.length).trim();

            if (contentAfterPrefix.isEmpty) {
              // 如果当前行是只有标记的空复选框，去掉复选框标记
              final newText = text.replaceRange(lineStart, lineEndSafe, '');
              textEditingController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: lineStart),
              );
            } else {
              // 如果当前行是复选框，新行自动加上复选框标记
              final newText =
                  text.replaceRange(cursorPosition, cursorPosition, '\n- [ ] ');
              textEditingController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(
                    offset: cursorPosition + 7), // 光标放在新行的复选框标记后
              );
            }
          }
        } else {
          // 如果当前行是无序列表，新行自动加上列表标记
          final newText =
              text.replaceRange(cursorPosition, cursorPosition, '\n- ');
          textEditingController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
                offset: cursorPosition + 3), // 光标放在新行的列表标记后
          );
        }
      } else if (orderedListRegex.hasMatch(lineText)) {
        // 如果当前行是有序列表
        final match = orderedListRegex.firstMatch(lineText);
        if (match != null) {
          final listPrefix = match.group(0)!; // 获取有序列表标记（如 "1. "）
          final contentAfterPrefix =
              lineText.substring(listPrefix.length).trim();

          if (contentAfterPrefix.isEmpty) {
            // 如果当前行是只有标记的空有序列表，去掉列表标记
            final newText = text.replaceRange(lineStart, lineEndSafe, '');
            textEditingController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: lineStart),
            );
          } else {
            // 如果当前行是有序列表，新行自动加上有序列表标记
            final currentNumber = int.parse(listPrefix.replaceFirst('.', ''));
            final newNumber = currentNumber + 1;

            // 插入新行并更新后续行的编号
            final newText = text.replaceRange(
                cursorPosition, cursorPosition, '\n$newNumber. ');
            textEditingController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                  offset:
                      cursorPosition + '$newNumber. '.length + 1), // 光标放在新行的标记后
            );

            // 更新后续行的编号
            _updateOrderedListNumbers(
                cursorPosition + '$newNumber. '.length + 1);
          }
        }
      } else {
        // 其他情况，普通回车
        final newText = text.replaceRange(cursorPosition, cursorPosition, '\n');
        textEditingController.value = TextEditingValue(
          text: newText,
          selection:
              TextSelection.collapsed(offset: cursorPosition + 1), // 光标放在新行
        );
      }
    } else {
      // 如果选中了文本，直接插入换行符
      final newText = text.replaceRange(selection.start, selection.end, '\n');
      textEditingController.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: selection.start + 1), // 光标放在新行
      );
    }
    focusNode.requestFocus();
  }

// 辅助函数：更新从指定位置开始的有序列表编号
  void _updateOrderedListNumbers(int startPosition) {
    final text = textEditingController.text;
    final orderedListRegex = RegExp(r'^\d+\. ');

    int currentNumber = 1;
    int lineStart = startPosition;
    while (lineStart < text.length) {
      final lineEnd = text.indexOf('\n', lineStart);
      final lineEndSafe = lineEnd == -1 ? text.length : lineEnd;
      final lineText = text.substring(lineStart, lineEndSafe);

      if (orderedListRegex.hasMatch(lineText)) {
        // 如果当前行是有序列表，更新编号
        final newText =
            lineText.replaceFirst(orderedListRegex, '$currentNumber. ');
        textEditingController.value = textEditingController.value.copyWith(
          text: text.replaceRange(lineStart, lineEndSafe, newText),
        );
        currentNumber++;
      } else if (lineText.trim().isNotEmpty) {
        // 如果遇到非空行但不是有序列表，停止更新
        break;
      }

      lineStart = lineEndSafe + 1;
    }
  }

  void _toggleTab({bool isShift = false}) {
    final text = textEditingController.text;
    final selection = textEditingController.selection;

    if (selection.isCollapsed) {
      final cursorPosition = selection.baseOffset;

      // 找到当前行的起始和结束位置
      final lineStart = cursorPosition == 0
          ? 0
          : text.lastIndexOf('\n', cursorPosition - 1) + 1;
      final lineEnd = text.indexOf('\n', cursorPosition);
      final lineEndSafe = lineEnd == -1 ? text.length : lineEnd;
      final lineText = text.substring(lineStart, lineEndSafe);

      // 判断当前行是否是列表项（无序列表、有序列表或复选框）
      final isUnorderedList = lineText.trimLeft().startsWith('- ');
      final isOrderedList = RegExp(r'^\d+\. ').hasMatch(lineText.trimLeft());
      final isCheckbox = RegExp(r'^- \[[ x]\] ').hasMatch(lineText.trimLeft());

      if (isUnorderedList || isOrderedList || isCheckbox) {
        // 当前行是列表项
        if (isShift) {
          // Shift + Tab：取消缩进
          if (lineText.startsWith('  ')) {
            final newText = text.replaceRange(lineStart, lineStart + 2, '');
            textEditingController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursorPosition - 2),
            );
          }
        } else {
          // Tab：缩进
          final newText = text.replaceRange(lineStart, lineStart, '  ');
          textEditingController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPosition + 2),
          );
        }
      } else {
        // 当前行不是列表项，插入 Tab 字符
        final newText = text.replaceRange(cursorPosition, cursorPosition, '\t');
        textEditingController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: cursorPosition + 1),
        );
      }
    }
    focusNode.requestFocus();
  }
}
