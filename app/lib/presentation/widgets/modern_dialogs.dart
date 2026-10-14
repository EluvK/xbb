import 'package:flutter/material.dart';
import 'package:xbb/core/core.dart';
import 'package:xbb/core/theme/tokens.dart';

bool isMobileScreen(BuildContext context) {
  return AppPlatform.isMobile || MediaQuery.sizeOf(context).width < 640;
}

class ModernInputDecoration {
  static InputDecoration field(
    BuildContext context, {
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool isDense = true,
    EdgeInsetsGeometry? contentPadding,
    bool filled = true,
    Color? fillColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: isDense,
      filled: filled,
      fillColor: fillColor ?? colorScheme.surfaceContainerLow,
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.roundedMd,
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.roundedMd,
        borderSide: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.roundedMd,
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.roundedMd,
        borderSide: BorderSide(
          color: colorScheme.error,
        ),
      ),
    );
  }
}

class AppFeedback {
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showFloatingSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: Colors.green,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showFloatingSnackBar(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: Colors.redAccent,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showFloatingSnackBar(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: Colors.blueAccent,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _showFloatingSnackBar(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: Colors.orangeAccent,
      duration: duration,
    );
  }

  static void _showFloatingSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.roundedMd),
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerHighest,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdaptiveModalContainer extends StatelessWidget {
  final Widget? leading;
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final List<Widget>? headerActions;
  final Widget child;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const AdaptiveModalContainer({
    super.key,
    this.leading,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.headerActions,
    required this.child,
    this.actions,
    this.padding,
    this.scrollable = true,
    this.showCloseButton = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isMobile = isMobileScreen(context);

    final titleSection = (title != null || titleWidget != null || leading != null)
        ? Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      titleWidget ??
                          Text(
                            title ?? '',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerActions != null) ...headerActions!,
                if (showCloseButton)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          )
        : null;

    final bodyWidget = scrollable
        ? SingleChildScrollView(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          )
        : Padding(
            padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
            child: child,
          );

    final actionSection = actions != null && actions!.isNotEmpty
        ? Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(60),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  actions![i],
                ],
              ],
            ),
          )
        : null;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(AppRadius.xl))
            : BorderRadius.circular(AppRadius.lg),
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMobile)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withAlpha(80),
                    borderRadius: AppRadius.roundedPill,
                  ),
                ),
              ),
            if (titleSection != null) ...[
              titleSection,
              Divider(height: 1, color: colorScheme.outlineVariant.withAlpha(60)),
            ],
            Flexible(child: bodyWidget),
            if (actionSection != null) actionSection,
          ],
        ),
      ),
    );
  }
}

Future<T?> showAdaptiveModal<T>(
  BuildContext context, {
  required Widget Function(BuildContext context) builder,
  String? title,
  Widget? leading,
  List<Widget>? headerActions,
  List<Widget>? actions,
  bool isDismissible = true,
  bool enableDrag = true,
  double maxWidth = 540,
  double maxHeightFactor = 0.88,
  bool isScrollControlled = true,
}) {
  final isMobile = isMobileScreen(context);

  if (isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * maxHeightFactor,
            ),
            child: builder(ctx),
          ),
        );
      },
    );
  }

  return showDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: MediaQuery.sizeOf(ctx).height * maxHeightFactor,
          ),
          child: Material(
            color: theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withAlpha(60),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 6,
            shadowColor: Colors.black.withAlpha(40),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

Future<bool?> showAdaptiveConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool isDanger = false,
  IconData? icon,
}) {
  return showAdaptiveModal<bool>(
    context,
    maxWidth: 440,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;
      final actualIcon = icon ?? (isDanger ? Icons.delete_outline_rounded : Icons.info_outline_rounded);
      final iconColor = isDanger ? colorScheme.error : colorScheme.primary;

      return AdaptiveModalContainer(
        titleWidget: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(24),
                shape: BoxShape.circle,
              ),
              child: Icon(actualIcon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText ?? 'cancel'.tr),
          ),
          FilledButton(
            style: isDanger
                ? FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmText ?? (isDanger ? '删除' : 'confirm'.tr)),
          ),
        ],
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      );
    },
  );
}

Future<String?> showAdaptiveTextInputDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  String? initialValue,
  String? hintText,
  String? labelText,
  String? confirmText,
  String? cancelText,
  IconData? prefixIcon,
  int maxLines = 1,
  TextInputType? keyboardType,
  bool autofocus = true,
}) {
  final controller = TextEditingController(text: initialValue ?? '');

  return showAdaptiveModal<String>(
    context,
    maxWidth: 460,
    builder: (ctx) {
      return AdaptiveModalContainer(
        title: title,
        subtitle: subtitle,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelText ?? 'cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop(controller.text.trim());
            },
            child: Text(confirmText ?? 'confirm'.tr),
          ),
        ],
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onSubmitted: (_) {
            Navigator.of(ctx).pop(controller.text.trim());
          },
          decoration: ModernInputDecoration.field(
            ctx,
            hintText: hintText,
            labelText: labelText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          ),
        ),
      );
    },
  );
}
