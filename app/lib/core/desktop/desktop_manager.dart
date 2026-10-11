import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/clipboard_tray.dart';

/// 统一跨端桌面集成管理器 (Windows/macOS/Linux)
/// 负责基于 window_manager 的沉浸式无边框窗口与关闭拦截（最小化到托盘），
/// 以及基于 tray_manager 的系统托盘驻留、快捷菜单与点击唤醒。
class DesktopManager with WindowListener, TrayListener {
  static final DesktopManager instance = DesktopManager._();
  DesktopManager._();

  static const String _storageWindowWidthKey = 'desktop_window_width';
  static const String _storageWindowHeightKey = 'desktop_window_height';
  static const String _storageWindowXKey = 'desktop_window_pos_x';
  static const String _storageWindowYKey = 'desktop_window_pos_y';

  bool _initialized = false;
  bool _minimizeToTrayOnClose = true;
  Timer? _saveBoundsDebounce;

  bool get isInitialized => _initialized;
  bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  bool get isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

  /// 初始化桌面端窗口与系统托盘
  Future<void> init({bool minimizeToTrayOnClose = true}) async {
    _minimizeToTrayOnClose = minimizeToTrayOnClose;
    if (!isDesktop || isTestEnvironment) {
      _initialized = true;
      return;
    }

    try {
      // 1. 初始化 WindowManager
      await windowManager.ensureInitialized();
      windowManager.addListener(this);

      // 读取已持久化的窗口尺寸与位置
      final box = GetStorage(GET_STORAGE_FILE_KEY);
      final double width = (box.read<num>(_storageWindowWidthKey) ?? 1200).toDouble();
      final double height = (box.read<num>(_storageWindowHeightKey) ?? 800).toDouble();
      final double? posX = box.read<num>(_storageWindowXKey)?.toDouble();
      final double? posY = box.read<num>(_storageWindowYKey)?.toDouble();

      final windowOptions = WindowOptions(
        size: Size(width, height),
        minimumSize: const Size(800, 600),
        center: posX == null || posY == null,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (posX != null && posY != null) {
          try {
            await windowManager.setPosition(Offset(posX, posY));
          } catch (_) {}
        }
        await windowManager.show();
        await windowManager.focus();
        await windowManager.setPreventClose(true);
      });

      // 2. 初始化 TrayManager
      trayManager.addListener(this);
      await _setupTrayIconAndMenu();

      _initialized = true;
    } catch (e) {
      debugPrint('[DesktopManager] init error: $e');
    }
  }

  /// 销毁并清理监听
  Future<void> dispose() async {
    if (!isDesktop || isTestEnvironment) return;
    try {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
      await trayManager.destroy();
    } catch (e) {
      debugPrint('[DesktopManager] dispose error: $e');
    }
  }

  /// 设置并刷新托盘图标与上下文菜单
  Future<void> _setupTrayIconAndMenu() async {
    if (!isDesktop || isTestEnvironment) return;
    try {
      String iconPath = Platform.isWindows ? 'assets/images/app_icon.ico' : 'assets/images/app_icon.png';
      // 如果本地没有指定资源，使用系统默认标识或静默尝试
      try {
        await trayManager.setIcon(iconPath);
      } catch (_) {
        // 托盘图标设置异常时不阻塞菜单初始化
      }

      await updateTrayMenu();
    } catch (e) {
      debugPrint('[DesktopManager] setup tray error: $e');
    }
  }

  /// 刷新托盘右键上下文菜单
  Future<void> updateTrayMenu() async {
    if (!isDesktop || isTestEnvironment) return;
    try {
      final isListening = ClipboardTrayService.instance.isListeningActive;
      final menu = Menu(
        items: [
          MenuItem(
            key: 'show_window',
            label: '显示主窗口 (Show Window)',
          ),
          MenuItem.separator(),
          MenuItem.checkbox(
            key: 'toggle_listening',
            label: isListening ? '剪贴板后台监听: 运行中 (Listening)' : '剪贴板后台监听: 已暂停 (Paused)',
            checked: isListening,
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'exit_app',
            label: '退出应用 (Exit)',
          ),
        ],
      );
      await trayManager.setContextMenu(menu);
      await trayManager.setToolTip(
        isListening ? 'XBB Workspace (剪贴板监听中)' : 'XBB Workspace (已暂停)',
      );
    } catch (e) {
      debugPrint('[DesktopManager] updateTrayMenu error: $e');
    }
  }

  /// 恢复并聚焦主窗口
  Future<void> showMainWindow() async {
    if (!isDesktop || isTestEnvironment) return;
    try {
      final isMinimized = await windowManager.isMinimized();
      if (isMinimized) {
        await windowManager.restore();
      }
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('[DesktopManager] showMainWindow error: $e');
    }
  }

  /// 彻底退出应用
  Future<void> exitApp() async {
    if (!isDesktop || isTestEnvironment) return;
    try {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
      exit(0);
    } catch (e) {
      debugPrint('[DesktopManager] exitApp error: $e');
      exit(0);
    }
  }

  // --- WindowListener 事件回调 ---

  @override
  void onWindowClose() async {
    if (!isDesktop || isTestEnvironment) return;
    if (_minimizeToTrayOnClose) {
      // 拦截关闭操作，实现关闭时最小化到系统托盘 (Hide to Tray)
      try {
        await windowManager.hide();
      } catch (e) {
        debugPrint('[DesktopManager] hide to tray error: $e');
      }
    } else {
      await exitApp();
    }
  }

  @override
  void onWindowResized() {
    _debouncePersistWindowBounds();
  }

  @override
  void onWindowMoved() {
    _debouncePersistWindowBounds();
  }

  void _debouncePersistWindowBounds() {
    if (!isDesktop || isTestEnvironment) return;
    _saveBoundsDebounce?.cancel();
    _saveBoundsDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final bounds = await windowManager.getBounds();
        final box = GetStorage(GET_STORAGE_FILE_KEY);
        await box.write(_storageWindowWidthKey, bounds.width);
        await box.write(_storageWindowHeightKey, bounds.height);
        await box.write(_storageWindowXKey, bounds.left);
        await box.write(_storageWindowYKey, bounds.top);
      } catch (e) {
        debugPrint('[DesktopManager] save window bounds error: $e');
      }
    });
  }

  // --- TrayListener 事件回调 ---

  @override
  void onTrayIconMouseDown() {
    showMainWindow();
  }

  @override
  void onTrayIconRightMouseDown() {
    if (!isDesktop || isTestEnvironment) return;
    try {
      trayManager.popUpContextMenu();
    } catch (e) {
      debugPrint('[DesktopManager] popUpContextMenu error: $e');
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_window':
        await showMainWindow();
        break;
      case 'toggle_listening':
        final current = ClipboardTrayService.instance.isListeningActive;
        await ClipboardTrayService.instance.setListeningEnabled(!current);
        await updateTrayMenu();
        break;
      case 'exit_app':
        await exitApp();
        break;
    }
  }
}
