import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// 现代应用主题构建工厂
class AppTheme {
  static const FlexScheme defaultScheme = FlexScheme.blumineBlue;
  static const String defaultFontFamily = 'lxgw';

  static ThemeData light({
    FlexScheme scheme = defaultScheme,
    String? fontFamily = defaultFontFamily,
  }) {
    return FlexThemeData.light(
      scheme: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: false,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        cardElevation: 0.5,
        elevatedButtonSchemeColor: SchemeColor.primary,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 10.0,
      ),
      keyColors: const FlexKeyColors(useSecondary: true),
      tones: FlexTones.material(Brightness.light).onMainsUseBW(),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: fontFamily,
    );
  }

  static ThemeData dark({
    FlexScheme scheme = defaultScheme,
    String? fontFamily = defaultFontFamily,
  }) {
    return FlexThemeData.dark(
      scheme: scheme,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 14,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: false,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        cardElevation: 0.5,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorRadius: 10.0,
      ),
      keyColors: const FlexKeyColors(useSecondary: true),
      tones: FlexTones.material(Brightness.dark).onMainsUseBW(),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: fontFamily,
    );
  }
}
