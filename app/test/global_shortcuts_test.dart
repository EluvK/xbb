import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/core/shortcuts/app_shortcuts.dart';
import 'package:xbb/core/shortcuts/command_palette_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('桌面端全局快捷键体系测试 (Shortcuts & Actions)', () {
    testWidgets('Cmd/Ctrl+K, Cmd/Ctrl+N, Cmd/Ctrl+S, ESC 能够准确分发到 AppShortcutDispatcher', (tester) async {
      bool searchTriggered = false;
      bool newTriggered = false;
      bool saveTriggered = false;
      bool escTriggered = false;

      AppShortcutDispatcher.instance.onSearch = () => searchTriggered = true;
      AppShortcutDispatcher.instance.onNewItem = () => newTriggered = true;
      AppShortcutDispatcher.instance.onSave = () => saveTriggered = true;
      AppShortcutDispatcher.instance.onEscape = () => escTriggered = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlobalShortcutsWrapper(
              child: Center(
                child: Text('Shortcuts Test'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 1. 模拟按下 Cmd + K (macOS)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();
      expect(searchTriggered, isTrue);

      // 2. 模拟按下 Ctrl + N (Windows/Linux)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(newTriggered, isTrue);

      // 3. 模拟按下 Cmd + S
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pump();
      expect(saveTriggered, isTrue);

      // 4. 模拟按下 ESC
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(escTriggered, isTrue);

      // 清理
      AppShortcutDispatcher.instance.onSearch = null;
      AppShortcutDispatcher.instance.onNewItem = null;
      AppShortcutDispatcher.instance.onSave = null;
      AppShortcutDispatcher.instance.onEscape = null;
    });

    testWidgets('CommandPaletteDialog 能够展示命令列表并支持关键字过滤与点击执行', (tester) async {
      bool action1Called = false;
      bool action2Called = false;

      final items = [
        CommandPaletteItem(
          title: '切换至待办事项',
          subtitle: '导航至待办模块',
          icon: Icons.checklist,
          shortcutHint: 'Cmd+1',
          onExecute: () => action1Called = true,
        ),
        CommandPaletteItem(
          title: '快速撰写笔记',
          subtitle: '跳转至笔记并新建',
          icon: Icons.edit_note,
          shortcutHint: 'Cmd+2',
          onExecute: () => action2Called = true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => CommandPaletteDialog.show(context, items: items),
                child: const Text('Open Palette'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 打开面板
      await tester.tap(find.text('Open Palette'));
      await tester.pumpAndSettle();

      // 验证两条选项正常渲染
      expect(find.text('切换至待办事项'), findsOneWidget);
      expect(find.text('快速撰写笔记'), findsOneWidget);

      // 在搜索框输入过滤关键字 "待办"
      await tester.enterText(find.byType(TextField), '待办');
      await tester.pumpAndSettle();

      expect(find.text('切换至待办事项'), findsOneWidget);
      expect(find.text('快速撰写笔记'), findsNothing);

      // 点击执行
      await tester.tap(find.text('切换至待办事项'));
      await tester.pumpAndSettle();

      expect(action1Called, isTrue);
      expect(action2Called, isFalse);
    });
  });
}
