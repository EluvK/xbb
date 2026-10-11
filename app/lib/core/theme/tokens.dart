import 'package:flutter/material.dart';

/// 现代应用间距设计规范 (Design Tokens)
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// 现代圆角设计规范
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius roundedPill = BorderRadius.all(Radius.circular(pill));
}

/// 现代微阴影规范
class AppShadows {
  static List<BoxShadow> subtle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black.withAlpha(40) : Colors.black.withAlpha(10),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black.withAlpha(60) : Colors.black.withAlpha(14),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black.withAlpha(80) : Colors.black.withAlpha(25),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
