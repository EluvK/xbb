import 'package:flutter/material.dart';
import 'package:xbb/core/theme/tokens.dart';

/// 现代圆角微边框卡片组件
class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final bool selected;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.radius = AppRadius.md,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = backgroundColor ??
        (selected
            ? colorScheme.primaryContainer.withAlpha(80)
            : colorScheme.surfaceContainerLowest);

    final border = borderColor ??
        (selected
            ? colorScheme.primary.withAlpha(160)
            : colorScheme.outlineVariant.withAlpha(80));

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: selected ? 1.5 : 1.0),
        boxShadow: AppShadows.subtle(context),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          onLongPress: onLongPress,
          child: content,
        ),
      );
    }

    return content;
  }
}

/// 现代胶囊状态徽标
class ModernBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const ModernBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: AppRadius.roundedPill,
        border: Border.all(color: c.withAlpha(60), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: c),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 现代扁平搜索栏
class ModernSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  const ModernSearchField({
    super.key,
    this.hintText = '搜索...',
    this.onChanged,
    this.controller,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: controller != null && controller!.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 16),
                onPressed: () {
                  controller?.clear();
                  onChanged?.call('');
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLow,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(60),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.roundedMd,
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(60),
          ),
        ),
      ),
    );
  }
}

/// 现代优雅空状态展示
class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
