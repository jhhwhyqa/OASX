import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:chinese_font_library/chinese_font_library.dart';

const List<String> _webChineseFontFallback = <String>[
  'PingFang SC',
  'Hiragino Sans GB',
  'Microsoft YaHei',
  'Noto Sans SC',
  'Noto Sans CJK SC',
  'Source Han Sans SC',
  'WenQuanYi Micro Hei',
  'sans-serif',
];

/// 用枚举太麻烦了
enum ColorSeed {
  baseColor('M3 Baseline', Color(0xff6750a4)),
  indigo('Indigo', Colors.indigo),
  blue('Blue', Colors.blue),
  teal('Teal', Colors.teal),
  green('Green', Colors.green),
  yellow('Yellow', Colors.yellow),
  orange('Orange', Colors.orange),
  deepOrange('Deep Orange', Colors.deepOrange),
  pink('Pink', Colors.pink);

  const ColorSeed(this.label, this.color);
  final String label;
  final Color color;
}

const Map<String, Color> colorSeedMap = {
  'M3 Baseline': Color(0xff6750a4),
  'Indigo': Colors.indigo,
  'Blue': Colors.blue,
  'Teal': Colors.teal,
  'Green': Colors.green,
  'Yellow': Colors.yellow,
  'Orange': Colors.orange,
  'Deep Orange': Colors.deepOrange,
  'Pink': Colors.pink,
};

/// Semantic colors shared by the home workbench surfaces.
///
/// Components read these values through [OasxStateColors.of] so the same
/// widget tree keeps adequate contrast in both light and dark themes.
@immutable
class OasxStateColors extends ThemeExtension<OasxStateColors> {
  const OasxStateColors({
    required this.running,
    required this.stopped,
    required this.abnormal,
    required this.offline,
    required this.pending,
    required this.waiting,
  });

  /// Palette tuned for light surfaces.
  static const OasxStateColors light = OasxStateColors(
    running: Color(0xFF2E7D32),
    stopped: Color(0xFF6B6F73),
    abnormal: Color(0xFFB45F06),
    offline: Color(0xFF1565C0),
    pending: Color(0xFFB45F06),
    waiting: Color(0xFF546E7A),
  );

  /// Palette tuned for dark surfaces.
  static const OasxStateColors dark = OasxStateColors(
    running: Color(0xFF81C784),
    stopped: Color(0xFF9AA0A6),
    abnormal: Color(0xFFFFB74D),
    offline: Color(0xFF64B5F6),
    pending: Color(0xFFFFB74D),
    waiting: Color(0xFF90A4AE),
  );

  final Color running;
  final Color stopped;
  final Color abnormal;
  final Color offline;
  final Color pending;
  final Color waiting;

  /// Resolves the palette for the active theme.
  static OasxStateColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<OasxStateColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  OasxStateColors copyWith({
    Color? running,
    Color? stopped,
    Color? abnormal,
    Color? offline,
    Color? pending,
    Color? waiting,
  }) {
    return OasxStateColors(
      running: running ?? this.running,
      stopped: stopped ?? this.stopped,
      abnormal: abnormal ?? this.abnormal,
      offline: offline ?? this.offline,
      pending: pending ?? this.pending,
      waiting: waiting ?? this.waiting,
    );
  }

  @override
  OasxStateColors lerp(ThemeExtension<OasxStateColors>? other, double t) {
    if (other is! OasxStateColors) {
      return this;
    }
    return OasxStateColors(
      running: Color.lerp(running, other.running, t)!,
      stopped: Color.lerp(stopped, other.stopped, t)!,
      abnormal: Color.lerp(abnormal, other.abnormal, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      waiting: Color.lerp(waiting, other.waiting, t)!,
    );
  }
}

ThemeData lightTheme = ThemeData(
  colorSchemeSeed: ColorSeed.baseColor.color,
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: _buildTextTheme(Brightness.light),
  scaffoldBackgroundColor: const Color.fromRGBO(255, 251, 255, 1),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Color.fromRGBO(255, 251, 255, 1),
  ),
  extensions: const <ThemeExtension<dynamic>>[OasxStateColors.light],
);

ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: ColorSeed.baseColor.color,
  brightness: Brightness.dark,
  textTheme: _buildTextTheme(Brightness.dark),
  scaffoldBackgroundColor: const Color.fromRGBO(49, 48, 51, 1),
  navigationRailTheme: const NavigationRailThemeData(
    backgroundColor: Color.fromRGBO(49, 48, 51, 1),
  ),
  extensions: const <ThemeExtension<dynamic>>[OasxStateColors.dark],
);

TextTheme _buildTextTheme(Brightness brightness) {
  const baseTheme = TextTheme(
    bodyLarge: TextStyle(),
    bodyMedium: TextStyle(),
    bodySmall: TextStyle(),
    labelLarge: TextStyle(),
    labelMedium: TextStyle(),
    labelSmall: TextStyle(),
    titleLarge: TextStyle(),
    titleMedium: TextStyle(),
    titleSmall: TextStyle(),
  );
  if (kIsWeb) {
    return _applyFontFallback(baseTheme, _webChineseFontFallback);
  }
  return baseTheme
      .apply(fontFamily: 'LatoLato')
      .useSystemChineseFont(brightness);
}

TextTheme _applyFontFallback(TextTheme textTheme, List<String> fallback) {
  return textTheme.copyWith(
    bodyLarge: _applyTextStyleFallback(textTheme.bodyLarge, fallback),
    bodyMedium: _applyTextStyleFallback(textTheme.bodyMedium, fallback),
    bodySmall: _applyTextStyleFallback(textTheme.bodySmall, fallback),
    labelLarge: _applyTextStyleFallback(textTheme.labelLarge, fallback),
    labelMedium: _applyTextStyleFallback(textTheme.labelMedium, fallback),
    labelSmall: _applyTextStyleFallback(textTheme.labelSmall, fallback),
    titleLarge: _applyTextStyleFallback(textTheme.titleLarge, fallback),
    titleMedium: _applyTextStyleFallback(textTheme.titleMedium, fallback),
    titleSmall: _applyTextStyleFallback(textTheme.titleSmall, fallback),
  );
}

TextStyle? _applyTextStyleFallback(TextStyle? style, List<String> fallback) {
  return style?.copyWith(fontFamilyFallback: fallback);
}
