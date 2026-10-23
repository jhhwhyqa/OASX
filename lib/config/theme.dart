import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:oasx/config/design_system.dart';

export 'package:oasx/config/design_system.dart';

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

/// Semantic colors shared by the workbench surfaces.
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

  /// Palette tuned for dark surfaces.
  static const OasxStateColors dark = OasxStateColors(
    running: Color(0xFF3DDC97),
    stopped: Color(0xFF7A8B95),
    abnormal: Color(0xFFF5B841),
    offline: Color(0xFF63B3FF),
    pending: Color(0xFFF5B841),
    waiting: Color(0xFF8FA3B0),
  );

  /// Palette tuned for light surfaces.
  static const OasxStateColors light = OasxStateColors(
    running: Color(0xFF07704F),
    stopped: Color(0xFF5F7078),
    abnormal: Color(0xFF8A5300),
    offline: Color(0xFF0B5E9E),
    pending: Color(0xFF8A5300),
    waiting: Color(0xFF4E6069),
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

ThemeData lightTheme = _buildTheme(Brightness.light);

ThemeData darkTheme = _buildTheme(Brightness.dark);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark ? OasxColors.dark : OasxColors.light;
  final state = isDark ? OasxStateColors.dark : OasxStateColors.light;
  final scheme = _buildScheme(colors, isDark);
  final textTheme = _buildTextTheme(brightness, colors);

  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(OasxRadius.sm),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.canvas,
    canvasColor: colors.canvas,
    cardColor: colors.surface,
    dividerColor: colors.border,
    splashFactory: InkRipple.splashFactory,
    focusColor: colors.accentSoft,
    hoverColor: colors.textPrimary.withValues(alpha: 0.035),
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    extensions: <ThemeExtension<dynamic>>[colors, state],
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: colors.canvas,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colors.textPrimary,
      iconTheme: IconThemeData(color: colors.textSecondary, size: 19),
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      toolbarHeight: 48,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.md),
        side: BorderSide(color: colors.border),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
      space: 1,
    ),
    iconTheme: IconThemeData(color: colors.textSecondary, size: 19),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceSunken,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: textTheme.bodySmall?.copyWith(color: colors.textTertiary),
      labelStyle: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      floatingLabelStyle: textTheme.bodySmall?.copyWith(color: colors.accent),
      prefixIconColor: colors.textTertiary,
      suffixIconColor: colors.textTertiary,
      iconColor: colors.textTertiary,
      border: inputBorder(colors.border),
      enabledBorder: inputBorder(colors.border),
      focusedBorder: inputBorder(colors.accent, 1.4),
      errorBorder: inputBorder(colors.danger),
      focusedErrorBorder: inputBorder(colors.danger, 1.4),
      disabledBorder: inputBorder(colors.border.withValues(alpha: 0.6)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.accentInk,
        disabledBackgroundColor: colors.surfaceRaised,
        disabledForegroundColor: colors.textTertiary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OasxRadius.sm),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        disabledForegroundColor: colors.textTertiary,
        side: BorderSide(color: colors.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OasxRadius.sm),
        ),
        textStyle: textTheme.labelLarge,
      ).copyWith(
        overlayColor: WidgetStatePropertyAll(colors.accentSoft),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.textSecondary,
        disabledForegroundColor: colors.textTertiary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OasxRadius.xs),
        ),
        textStyle: textTheme.labelLarge,
      ).copyWith(
        overlayColor: WidgetStatePropertyAll(colors.accentSoft),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.textSecondary,
        disabledForegroundColor: colors.textTertiary.withValues(alpha: 0.6),
        highlightColor: colors.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OasxRadius.xs),
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent
            : colors.textTertiary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accentSoft
            : colors.surfaceSunken,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent.withValues(alpha: 0.55)
            : colors.borderStrong,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      side: BorderSide(color: colors.borderStrong, width: 1.2),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(colors.accentInk),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.xs),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent
            : colors.borderStrong,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceSunken,
      selectedColor: colors.accentSoft,
      disabledColor: colors.surfaceRaised,
      side: BorderSide(color: colors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.pill),
      ),
      labelStyle: textTheme.labelMedium?.copyWith(color: colors.textSecondary),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: colors.accent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.lg),
        side: BorderSide(color: colors.border),
      ),
      titleTextStyle: textTheme.titleMedium?.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.textSecondary,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: colors.borderStrong,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(OasxRadius.lg),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceRaised,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.textPrimary,
      ),
      actionTextColor: colors.accent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        side: BorderSide(color: colors.border),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      textStyle: textTheme.bodySmall?.copyWith(color: colors.textPrimary),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(OasxRadius.xs),
        border: Border.all(color: colors.border),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        side: BorderSide(color: colors.border),
      ),
      textStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.surfaceRaised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OasxRadius.sm),
            side: BorderSide(color: colors.border),
          ),
        ),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: colors.textPrimary,
      iconColor: colors.textSecondary,
      selectedColor: colors.accent,
      selectedTileColor: colors.accentSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.sm),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      textColor: colors.textPrimary,
      collapsedTextColor: colors.textPrimary,
      iconColor: colors.textSecondary,
      collapsedIconColor: colors.textSecondary,
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        side: BorderSide(color: colors.border),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        side: BorderSide(color: colors.border),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? colors.borderStrong
            : colors.border,
      ),
      thickness: const WidgetStatePropertyAll(6),
      radius: const Radius.circular(OasxRadius.pill),
      crossAxisMargin: 2,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.accent,
      linearTrackColor: colors.surfaceSunken,
      circularTrackColor: colors.surfaceSunken,
      refreshBackgroundColor: colors.surfaceRaised,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.accent,
      foregroundColor: colors.accentInk,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OasxRadius.md),
      ),
    ),
    toggleButtonsTheme: ToggleButtonsThemeData(
      color: colors.textSecondary,
      selectedColor: colors.accentInk,
      fillColor: colors.accent,
      borderRadius: BorderRadius.circular(OasxRadius.sm),
      borderColor: colors.border,
      selectedBorderColor: colors.accent,
      textStyle: textTheme.labelMedium,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.accent,
      selectionColor: colors.accentSoft,
      selectionHandleColor: colors.accent,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colors.accent,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.accent,
      dividerColor: colors.border,
      labelStyle: textTheme.labelLarge,
      unselectedLabelStyle: textTheme.labelLarge,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: colors.accentSoft,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelSmall?.copyWith(
          color: states.contains(WidgetState.selected)
              ? colors.accent
              : colors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? colors.accent
              : colors.textSecondary,
          size: 21,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colors.surface,
      indicatorColor: colors.accentSoft,
      selectedIconTheme: IconThemeData(color: colors.accent, size: 21),
      unselectedIconTheme: IconThemeData(color: colors.textSecondary, size: 21),
      selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: colors.accent,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: colors.textSecondary,
      ),
      useIndicator: true,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSunken,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        border: inputBorder(colors.border),
        enabledBorder: inputBorder(colors.border),
        focusedBorder: inputBorder(colors.accent, 1.4),
      ),
    ),
    badgeTheme: BadgeThemeData(
      backgroundColor: colors.accent,
      textColor: colors.accentInk,
    ),
  );
}

ColorScheme _buildScheme(OasxColors colors, bool isDark) {
  return ColorScheme(
    brightness: isDark ? Brightness.dark : Brightness.light,
    primary: colors.accent,
    onPrimary: colors.accentInk,
    primaryContainer: colors.accentSoft,
    onPrimaryContainer: colors.textPrimary,
    secondary: colors.info,
    onSecondary: isDark ? const Color(0xFF03121F) : Colors.white,
    secondaryContainer: colors.info.withValues(alpha: isDark ? 0.18 : 0.10),
    onSecondaryContainer: colors.textPrimary,
    tertiary: colors.warning,
    onTertiary: isDark ? const Color(0xFF231803) : Colors.white,
    tertiaryContainer: colors.warning.withValues(alpha: isDark ? 0.18 : 0.10),
    onTertiaryContainer: colors.textPrimary,
    error: colors.danger,
    onError: isDark ? const Color(0xFF2A0705) : Colors.white,
    errorContainer: colors.danger.withValues(alpha: isDark ? 0.18 : 0.10),
    onErrorContainer: colors.textPrimary,
    surface: colors.surface,
    onSurface: colors.textPrimary,
    surfaceContainerLowest: colors.surfaceSunken,
    surfaceContainerLow: colors.surface,
    surfaceContainer: colors.surfaceRaised,
    surfaceContainerHigh: colors.surfaceRaised,
    surfaceContainerHighest: colors.surfaceSunken,
    onSurfaceVariant: colors.textSecondary,
    outline: colors.borderStrong,
    outlineVariant: colors.border,
    shadow: colors.shadow,
    scrim: Colors.black54,
    inverseSurface: isDark ? colors.textPrimary : colors.canvas,
    onInverseSurface: isDark ? colors.canvas : colors.textPrimary,
    inversePrimary: colors.accentHover,
    surfaceTint: Colors.transparent,
  );
}

TextTheme _buildTextTheme(Brightness brightness, OasxColors colors) {
  final baseTheme = TextTheme(
    displaySmall: _style(brightness, 28, FontWeight.w700, -0.6, 1.15),
    headlineSmall: _style(brightness, 22, FontWeight.w700, -0.4, 1.2),
    titleLarge: _style(brightness, 19, FontWeight.w600, -0.2, 1.25),
    titleMedium: _style(brightness, 15, FontWeight.w600, -0.1, 1.3),
    titleSmall: _style(brightness, 13, FontWeight.w600, 0, 1.35),
    bodyLarge: _style(brightness, 14, FontWeight.w400, 0, 1.45),
    bodyMedium: _style(brightness, 13, FontWeight.w400, 0, 1.45),
    bodySmall: _style(brightness, 12, FontWeight.w400, 0, 1.4),
    labelLarge: _style(brightness, 13, FontWeight.w600, 0, 1.3),
    labelMedium: _style(brightness, 12, FontWeight.w500, 0.2, 1.3),
    labelSmall: _style(brightness, 10.5, FontWeight.w600, 1.1, 1.3),
  );
  return _applyFontFamily(baseTheme, brightness).apply(
    bodyColor: colors.textPrimary,
    displayColor: colors.textPrimary,
  );
}

TextStyle _style(
  Brightness brightness,
  double size,
  FontWeight weight,
  double letterSpacing,
  double height,
) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

TextTheme _applyFontFamily(TextTheme textTheme, Brightness brightness) {
  if (kIsWeb) {
    return _applyFontFallback(textTheme, _webChineseFontFallback);
  }
  return textTheme
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
