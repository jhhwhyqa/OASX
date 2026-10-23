import 'package:flutter/material.dart';

/// Monospace stack used by logs, identifiers and numeric readouts.
///
/// The app ships no mono font asset, so the stack relies on fonts that ship
/// with the target platforms and falls back to the generic family last.
const List<String> kOasxMonoFontFallback = <String>[
  'Consolas',
  'Cascadia Mono',
  'Cascadia Code',
  'SF Mono',
  'Menlo',
  'DejaVu Sans Mono',
  // Logs contain Chinese, so keep CJK faces in the fallback chain instead of
  // relying on platform-specific fallback behaviour.
  'Microsoft YaHei',
  'PingFang SC',
  'Hiragino Sans GB',
  'Noto Sans SC',
  'Noto Sans CJK SC',
  'WenQuanYi Micro Hei',
  'monospace',
];

/// Spacing scale. Keep layout gaps on these steps so density stays coherent.
abstract final class OasxSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii for the console surfaces, controls and pills.
abstract final class OasxRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Semantic colors for the "deep space console" art direction.
///
/// Widgets should read these through [OasxColors.of] rather than hard-coding
/// palette values, so the light and dark themes stay in sync.
@immutable
class OasxColors extends ThemeExtension<OasxColors> {
  const OasxColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.accentHover,
    required this.accentSoft,
    required this.accentInk,
    required this.warning,
    required this.danger,
    required this.info,
    required this.gridLine,
    required this.logBackground,
    required this.logText,
    required this.logTimestamp,
    required this.logTrace,
    required this.logDebug,
    required this.logInfo,
    required this.logWarning,
    required this.logError,
    required this.shadow,
  });

  /// Night-first palette used as the primary product look.
  static const OasxColors dark = OasxColors(
    canvas: Color(0xFF0B0F12),
    surface: Color(0xFF11181D),
    surfaceRaised: Color(0xFF172128),
    surfaceSunken: Color(0xFF090D10),
    border: Color(0xFF23313A),
    borderStrong: Color(0xFF33454F),
    textPrimary: Color(0xFFE8F0F4),
    textSecondary: Color(0xFF9DB0BB),
    textTertiary: Color(0xFF7E929E),
    accent: Color(0xFF3DDC97),
    accentHover: Color(0xFF6BEAB4),
    accentSoft: Color(0x263DDC97),
    accentInk: Color(0xFF04150F),
    warning: Color(0xFFF5B841),
    danger: Color(0xFFFF7A70),
    info: Color(0xFF63B3FF),
    gridLine: Color(0x0DFFFFFF),
    logBackground: Color(0xFF0C1216),
    logText: Color(0xFFC7D6DF),
    logTimestamp: Color(0xFF6F8A96),
    logTrace: Color(0xFF7A8B95),
    logDebug: Color(0xFF8FB0C0),
    logInfo: Color(0xFF7FC4FF),
    logWarning: Color(0xFFF5C16C),
    logError: Color(0xFFFF8A80),
    shadow: Color(0x66000000),
  );

  /// Daylight companion palette with the same hierarchy and accent meaning.
  static const OasxColors light = OasxColors(
    canvas: Color(0xFFF1F4F5),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF7FAFA),
    surfaceSunken: Color(0xFFE8EDEF),
    border: Color(0xFFD7E0E3),
    borderStrong: Color(0xFFBCC9CE),
    textPrimary: Color(0xFF0F171B),
    textSecondary: Color(0xFF4E6069),
    textTertiary: Color(0xFF566A73),
    accent: Color(0xFF077054),
    accentHover: Color(0xFF055C45),
    accentSoft: Color(0x14077054),
    accentInk: Color(0xFFFFFFFF),
    warning: Color(0xFF8A5300),
    danger: Color(0xFFB3261E),
    info: Color(0xFF0B5E9E),
    gridLine: Color(0x12000000),
    logBackground: Color(0xFFF6F9F9),
    logText: Color(0xFF17262D),
    logTimestamp: Color(0xFF5A6F78),
    logTrace: Color(0xFF7C8F98),
    logDebug: Color(0xFF405A66),
    logInfo: Color(0xFF0B5E9E),
    logWarning: Color(0xFF8A5A00),
    logError: Color(0xFFB3261E),
    shadow: Color(0x1F000000),
  );

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color accentHover;
  final Color accentSoft;
  final Color accentInk;
  final Color warning;
  final Color danger;
  final Color info;
  final Color gridLine;
  final Color logBackground;
  final Color logText;
  final Color logTimestamp;
  final Color logTrace;
  final Color logDebug;
  final Color logInfo;
  final Color logWarning;
  final Color logError;
  final Color shadow;

  /// Resolves the palette for the active theme.
  static OasxColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<OasxColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  OasxColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? accentHover,
    Color? accentSoft,
    Color? accentInk,
    Color? warning,
    Color? danger,
    Color? info,
    Color? gridLine,
    Color? logBackground,
    Color? logText,
    Color? logTimestamp,
    Color? logTrace,
    Color? logDebug,
    Color? logInfo,
    Color? logWarning,
    Color? logError,
    Color? shadow,
  }) {
    return OasxColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentSoft: accentSoft ?? this.accentSoft,
      accentInk: accentInk ?? this.accentInk,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      gridLine: gridLine ?? this.gridLine,
      logBackground: logBackground ?? this.logBackground,
      logText: logText ?? this.logText,
      logTimestamp: logTimestamp ?? this.logTimestamp,
      logTrace: logTrace ?? this.logTrace,
      logDebug: logDebug ?? this.logDebug,
      logInfo: logInfo ?? this.logInfo,
      logWarning: logWarning ?? this.logWarning,
      logError: logError ?? this.logError,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  OasxColors lerp(ThemeExtension<OasxColors>? other, double t) {
    if (other is! OasxColors) {
      return this;
    }
    return OasxColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      gridLine: Color.lerp(gridLine, other.gridLine, t)!,
      logBackground: Color.lerp(logBackground, other.logBackground, t)!,
      logText: Color.lerp(logText, other.logText, t)!,
      logTimestamp: Color.lerp(logTimestamp, other.logTimestamp, t)!,
      logTrace: Color.lerp(logTrace, other.logTrace, t)!,
      logDebug: Color.lerp(logDebug, other.logDebug, t)!,
      logInfo: Color.lerp(logInfo, other.logInfo, t)!,
      logWarning: Color.lerp(logWarning, other.logWarning, t)!,
      logError: Color.lerp(logError, other.logError, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Shared text styles that sit on top of the Material [TextTheme].
abstract final class OasxText {
  /// Uppercase micro label used for pane headers and metadata groups.
  static TextStyle micro(BuildContext context, {Color? color}) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      color: color ?? OasxColors.of(context).textTertiary,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
    );
  }

  /// Monospace style for logs, paths, identifiers and numeric readouts.
  static TextStyle mono(
    BuildContext context, {
    double size = 12.5,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.5,
  }) {
    return TextStyle(
      // A primary family is required: fallback families only apply to glyphs
      // missing from the primary face.
      fontFamily: 'Consolas',
      fontFamilyFallback: kOasxMonoFontFallback,
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? OasxColors.of(context).logText,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Numeric readout with tabular figures and tightened tracking.
  static TextStyle figure(
    BuildContext context, {
    double size = 20,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: -0.3,
      color: color ?? OasxColors.of(context).textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
