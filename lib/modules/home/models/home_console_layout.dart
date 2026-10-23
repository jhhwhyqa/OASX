import 'package:flutter/foundation.dart';

/// Minimum content width required by the three-column desktop console.
const double kHomeConsoleMinWidth = 1080;

/// Hit area reserved for each console divider.
const double kHomeConsoleDividerWidth = 14;

/// Minimum width of the task column.
const double kHomeConsoleMinLeftWidth = 260;

/// Maximum width of the task column on very wide windows.
const double kHomeConsoleMaxLeftWidth = 420;

/// Minimum width kept for the log column.
const double kHomeConsoleMinCenterWidth = 480;

/// Width of the collapsed statistics rail.
const double kHomeConsoleCollapsedRightWidth = 48;

/// Minimum width of the statistics column.
const double kHomeConsoleMinRightWidth = 280;

/// Maximum width of the statistics column on very wide windows.
const double kHomeConsoleMaxRightWidth = 460;

/// Default share of the available width used by the task column.
const double kHomeConsoleDefaultLeftRatio = 0.26;

/// Default share of the available width used by the statistics column.
const double kHomeConsoleDefaultRightRatio = 0.29;

/// Legal persisted ratio range for both side columns.
const double kHomeConsoleMinRatio = 0.15;
const double kHomeConsoleMaxRatio = 0.45;

/// Sanitizes a persisted task-column ratio.
double sanitizeHomeConsoleLeftRatio(dynamic rawValue) {
  return _sanitizeRatio(rawValue, kHomeConsoleDefaultLeftRatio);
}

/// Sanitizes a persisted statistics-column ratio.
double sanitizeHomeConsoleRightRatio(dynamic rawValue) {
  return _sanitizeRatio(rawValue, kHomeConsoleDefaultRightRatio);
}

double _sanitizeRatio(dynamic rawValue, double defaultValue) {
  final value = switch (rawValue) {
    num() => rawValue.toDouble(),
    String() => double.tryParse(rawValue),
    _ => null,
  };
  if (value == null || !value.isFinite) {
    return defaultValue;
  }
  return value.clamp(kHomeConsoleMinRatio, kHomeConsoleMaxRatio).toDouble();
}

/// Resolved pixel geometry for the desktop console.
@immutable
class HomeConsoleLayout {
  const HomeConsoleLayout({
    required this.canShow,
    required this.width,
    required this.availableWidth,
    required this.leftWidth,
    required this.centerWidth,
    required this.rightWidth,
    required this.appliedLeftRatio,
    required this.appliedRightRatio,
    required this.minLeftRatio,
    required this.maxLeftRatio,
    required this.minRightRatio,
    required this.maxRightRatio,
  });

  /// Creates a result for windows that are too narrow for the console.
  const HomeConsoleLayout.hidden()
    : canShow = false,
      width = 0,
      availableWidth = 0,
      leftWidth = 0,
      centerWidth = 0,
      rightWidth = 0,
      appliedLeftRatio = kHomeConsoleDefaultLeftRatio,
      appliedRightRatio = kHomeConsoleDefaultRightRatio,
      minLeftRatio = kHomeConsoleMinRatio,
      maxLeftRatio = kHomeConsoleMaxRatio,
      minRightRatio = kHomeConsoleMinRatio,
      maxRightRatio = kHomeConsoleMaxRatio;

  /// Whether the console can be rendered at this width.
  final bool canShow;

  /// Total content width.
  final double width;

  /// Width available to the three columns after removing dividers.
  final double availableWidth;

  final double leftWidth;
  final double centerWidth;
  final double rightWidth;

  /// Effective ratios after clamping to pixel constraints.
  final double appliedLeftRatio;
  final double appliedRightRatio;

  final double minLeftRatio;
  final double maxLeftRatio;
  final double minRightRatio;
  final double maxRightRatio;
}

/// Resolves the three-column console geometry for one width.
HomeConsoleLayout resolveHomeConsoleLayout({
  required double maxWidth,
  required double leftRatio,
  required double rightRatio,
}) {
  final width = maxWidth.isFinite ? maxWidth : 0.0;
  if (width < kHomeConsoleMinWidth) {
    return const HomeConsoleLayout.hidden();
  }
  final available = width - kHomeConsoleDividerWidth * 2;
  if (available <= 0) {
    return const HomeConsoleLayout.hidden();
  }

  final normalizedLeft = sanitizeHomeConsoleLeftRatio(leftRatio);
  final normalizedRight = sanitizeHomeConsoleRightRatio(rightRatio);

  final minLeftRatio = kHomeConsoleMinLeftWidth / available;
  final maxLeftRatio = _minRatio(
    kHomeConsoleMaxLeftWidth / available,
    1 - (kHomeConsoleMinCenterWidth + kHomeConsoleMinRightWidth) / available,
  );
  final appliedLeftRatio = normalizedLeft
      .clamp(minLeftRatio, maxLeftRatio)
      .toDouble();
  final leftWidth = appliedLeftRatio * available;

  final minRightRatio = kHomeConsoleMinRightWidth / available;
  final maxRightRatio = _minRatio(
    kHomeConsoleMaxRightWidth / available,
    1 - (kHomeConsoleMinCenterWidth + leftWidth) / available,
  );
  final appliedRightRatio = normalizedRight
      .clamp(minRightRatio, maxRightRatio)
      .toDouble();
  final rightWidth = appliedRightRatio * available;
  final centerWidth = available - leftWidth - rightWidth;

  return HomeConsoleLayout(
    canShow: true,
    width: width,
    availableWidth: available,
    leftWidth: leftWidth,
    centerWidth: centerWidth,
    rightWidth: rightWidth,
    appliedLeftRatio: appliedLeftRatio,
    appliedRightRatio: appliedRightRatio,
    minLeftRatio: minLeftRatio,
    maxLeftRatio: maxLeftRatio,
    minRightRatio: minRightRatio,
    maxRightRatio: maxRightRatio,
  );
}

/// Clamps a live left-divider ratio to the current legal range.
double clampHomeConsoleLeftRatio({
  required HomeConsoleLayout layout,
  required double targetRatio,
}) {
  return targetRatio.clamp(layout.minLeftRatio, layout.maxLeftRatio).toDouble();
}

/// Clamps a live right-divider ratio to the current legal range.
double clampHomeConsoleRightRatio({
  required HomeConsoleLayout layout,
  required double targetRatio,
}) {
  return targetRatio
      .clamp(layout.minRightRatio, layout.maxRightRatio)
      .toDouble();
}

double _minRatio(double left, double right) {
  return left < right ? left : right;
}
