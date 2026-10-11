import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局快捷键意图定义 (Shortcuts Intents)
class GlobalSearchIntent extends Intent {
  const GlobalSearchIntent();
}

class GlobalNewItemIntent extends Intent {
  const GlobalNewItemIntent();
}

class GlobalSaveIntent extends Intent {
  const GlobalSaveIntent();
}

class GlobalEscapeIntent extends Intent {
  const GlobalEscapeIntent();
}

/// 全局快捷键分发调度器，支持子模块动态注册高优先级回调
class AppShortcutDispatcher {
  static final AppShortcutDispatcher instance = AppShortcutDispatcher._();
  AppShortcutDispatcher._();

  VoidCallback? onSearch;
  VoidCallback? onNewItem;
  VoidCallback? onSave;
  VoidCallback? onEscape;

  void triggerSearch() => onSearch?.call();
  void triggerNewItem() => onNewItem?.call();
  void triggerSave() => onSave?.call();
  void triggerEscape() => onEscape?.call();
}

/// 全局快捷键按键映射表 (兼容 macOS Cmd 与 Windows/Linux Ctrl)
final Map<ShortcutActivator, Intent> kGlobalShortcutBindings = {
  // Cmd/Ctrl + K: 全局搜索 / 快捷命令面板
  const SingleActivator(LogicalKeyboardKey.keyK, meta: true): const GlobalSearchIntent(),
  const SingleActivator(LogicalKeyboardKey.keyK, control: true): const GlobalSearchIntent(),

  // Cmd/Ctrl + N: 快速新建
  const SingleActivator(LogicalKeyboardKey.keyN, meta: true): const GlobalNewItemIntent(),
  const SingleActivator(LogicalKeyboardKey.keyN, control: true): const GlobalNewItemIntent(),

  // Cmd/Ctrl + S: 手动保存
  const SingleActivator(LogicalKeyboardKey.keyS, meta: true): const GlobalSaveIntent(),
  const SingleActivator(LogicalKeyboardKey.keyS, control: true): const GlobalSaveIntent(),

  // ESC: 退出编辑态或关闭弹窗
  const SingleActivator(LogicalKeyboardKey.escape): const GlobalEscapeIntent(),
};

/// 挂载在应用顶层的快捷键与动作包装器
class GlobalShortcutsWrapper extends StatelessWidget {
  final Widget child;

  const GlobalShortcutsWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: kGlobalShortcutBindings,
      child: Actions(
        actions: {
          GlobalSearchIntent: CallbackAction<GlobalSearchIntent>(
            onInvoke: (_) {
              AppShortcutDispatcher.instance.triggerSearch();
              return null;
            },
          ),
          GlobalNewItemIntent: CallbackAction<GlobalNewItemIntent>(
            onInvoke: (_) {
              AppShortcutDispatcher.instance.triggerNewItem();
              return null;
            },
          ),
          GlobalSaveIntent: CallbackAction<GlobalSaveIntent>(
            onInvoke: (_) {
              AppShortcutDispatcher.instance.triggerSave();
              return null;
            },
          ),
          GlobalEscapeIntent: CallbackAction<GlobalEscapeIntent>(
            onInvoke: (_) {
              AppShortcutDispatcher.instance.triggerEscape();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}
