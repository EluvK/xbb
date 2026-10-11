import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:xbb/core/theme/tokens.dart';

/// 跨平台桌面端现代化沉浸式无边框窗口顶栏
/// 支持拖拽移动窗口、双击最大化/还原、以及最小化/最大化/关闭按钮
class DesktopTitleBar extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final double height;

  const DesktopTitleBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.height = 36.0,
  });

  @override
  State<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends State<DesktopTitleBar> with WindowListener {
  bool _isMaximized = false;

  bool get _isDesktop => !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  bool get _isTestEnvironment => Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void initState() {
    super.initState();
    if (_isDesktop && !_isTestEnvironment) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (_isDesktop && !_isTestEnvironment) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = maximized);
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  void _handleDoubleClick() async {
    if (!_isDesktop || _isTestEnvironment) return;
    try {
      if (_isMaximized) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.colorScheme.surfaceContainerLowest;
    final buttonHoverColor = isDark ? Colors.white12 : Colors.black12;

    return Material(
      color: backgroundColor,
      child: SizedBox(
        height: widget.height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // 左侧 Leading / 图标或自定义控件
          if (widget.leading != null) widget.leading!,
          // 标题与可拖动空白区域
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: _handleDoubleClick,
              child: DragToMoveArea(
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    if (widget.title != null)
                      widget.title!
                    else
                      Text(
                        'XBB Workspace',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          // 自定义 Action 列表
          if (widget.actions != null) ...widget.actions!,
          // 桌面窗口控制按钮 (最小化、最大化/还原、关闭)
          _buildWindowButton(
            icon: Icons.minimize,
            iconSize: 14,
            tooltip: '最小化',
            hoverColor: buttonHoverColor,
            onPressed: () async {
              if (!_isTestEnvironment) await windowManager.minimize();
            },
          ),
          _buildWindowButton(
            icon: _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
            iconSize: 14,
            tooltip: _isMaximized ? '还原' : '最大化',
            hoverColor: buttonHoverColor,
            onPressed: () async {
              if (!_isTestEnvironment) {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              }
            },
          ),
          _buildWindowButton(
            icon: Icons.close,
            iconSize: 14,
            tooltip: '关闭到托盘',
            hoverColor: Colors.redAccent.withValues(alpha: 0.8),
            iconHoverColor: Colors.white,
            onPressed: () async {
              if (!_isTestEnvironment) await windowManager.close();
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required double iconSize,
    required String tooltip,
    required Color hoverColor,
    Color? iconHoverColor,
    required VoidCallback onPressed,
  }) {
    return _WindowHoverButton(
      icon: icon,
      iconSize: iconSize,
      tooltip: tooltip,
      hoverColor: hoverColor,
      iconHoverColor: iconHoverColor,
      onPressed: onPressed,
    );
  }
}

class _WindowHoverButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final String tooltip;
  final Color hoverColor;
  final Color? iconHoverColor;
  final VoidCallback onPressed;

  const _WindowHoverButton({
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    required this.hoverColor,
    this.iconHoverColor,
    required this.onPressed,
  });

  @override
  State<_WindowHoverButton> createState() => _WindowHoverButtonState();
}

class _WindowHoverButtonState extends State<_WindowHoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalColor = theme.colorScheme.onSurfaceVariant;
    final activeIconColor = _isHovered ? (widget.iconHoverColor ?? theme.colorScheme.onSurface) : normalColor;

    Widget button = InkWell(
      onTap: widget.onPressed,
      child: Container(
        width: 44,
        alignment: Alignment.center,
        color: _isHovered ? widget.hoverColor : Colors.transparent,
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: activeIconColor,
        ),
      ),
    );

    if (Overlay.maybeOf(context) != null) {
      button = Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: button,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: button,
    );
  }
}
