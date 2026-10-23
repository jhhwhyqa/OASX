import 'package:flutter/foundation.dart';

/// Minimum content width that can host the three-column console.
const double kHomeConsoleThreePaneMinWidth = 1000;

/// Minimum content width that can host the task + log two-column console.
const double kHomeConsoleTwoPaneMinWidth = 700;

/// Width above which the statistics column can push the log instead of
/// overlaying it.
const double kHomeConsoleStatsPushMinWidth = 1080;

/// Backwards-compatible alias for the three-pane threshold.
const double kHomeConsoleMinWidth = kHomeConsoleThreePaneMinWidth;

/// Hit area reserved for each console divider.
const double kHomeConsoleDividerWidth = 14;

/// Minimum width of the task column.
const double kHomeConsoleMinLeftWidth = 240;

/// Maximum width of the task column on very wide windows.
const double kHomeConsoleMaxLeftWidth = 360;

/// Minimum width kept for the log column in the two-pane layout.
const double kHomeConsoleMinCenterWidth = 440;

/// Minimum width kept for the log column in the three-pane layout.
const double kHomeConsoleThreePaneMinCenterWidth = 480;

/// Width of the collapsed statistics rail.
const double kHomeConsoleCollapsedRightWidth = 48;

/// Minimum width of the expanded statistics column.
const double kHomeConsoleMinRightWidth = 280;

/// Maximum width of the expanded statistics column.
const double kHomeConsoleMaxRightWidth = 400;

/// Default share of the available width used by the task column.
const double kHomeConsoleDefaultLeftRatio = 0.26;

/// Default share of the available width used by the statistics column.
const double kHomeConsoleDefaultRightRatio = 0.29;

/// Legal persisted ratio range for both side columns.
const double kHomeConsoleMinRatio = 0.15;
const double kHomeConsoleMaxRatio = 0.45;

/// Active composition of the home console.
enum HomeConsoleLayoutMode { compact, twoPane, threePane }

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

/// Resolved pixel geometry for the home console.
@immutable
class HomeConsoleLayout {
  const HomeConsoleLayout({
    required this.mode,
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
    required this.canPushStats,
  });

  /// Creates a result for widths that only support one pane.
  const HomeConsoleLayout.compact()
    : mode = HomeConsoleLayoutMode.compact,
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
      maxRightRatio = kHomeConsoleMaxRatio,
      canPushStats = false;

  final HomeConsoleLayoutMode mode;

  /// Total content width.
  final double width;

  /// Width available after removing dividers.
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

  /// Whether the expanded statistics column fits without shrinking the log
  /// below its minimum readable width.
  final bool canPushStats;

  /// Whether the console can render more than one pane.
  bool get canShow => mode != HomeConsoleLayoutMode.compact;

  bool get usesThreePane => mode == HomeConsoleLayoutMode.threePane;

  bool get usesTwoPane => mode == HomeConsoleLayoutMode.twoPane;
}

/// Resolves the console geometry for one width.
///
/// [statsExpanded] only affects three-pane layouts above
/// [kHomeConsoleStatsPushMinWidth]. Below that width the right column stays
/// collapsed and the statistics pane is presented as an overlay by the caller.
HomeConsoleLayout resolveHomeConsoleLayout({
  required double maxWidth,
  required double leftRatio,
  required double rightRatio,
  bool statsExpanded = false,
}) {
  final width = maxWidth.isFinite ? maxWidth : 0.0;
  if (width < kHomeConsoleTwoPaneMinWidth) {
    return const HomeConsoleLayout.compact();
  }
  if (width < kHomeConsoleThreePaneMinWidth) {
    return _resolveTwoPane(width: width, leftRatio: leftRatio);
  }
  return _resolveThreePane(
    width: width,
    leftRatio: leftRatio,
    rightRatio: rightRatio,
    statsExpanded: statsExpanded,
  );
}

HomeConsoleLayout _resolveTwoPane({
  required double width,
  required double leftRatio,
}) {
  final available = width - kHomeConsoleDividerWidth;
  if (available <= 0) {
    return const HomeConsoleLayout.compact();
  }
  const minLeft = kHomeConsoleMinLeftWidth;
  final maxLeft = _minRatio(
    kHomeConsoleMaxLeftWidth,
    available - kHomeConsoleMinCenterWidth,
  );
  final normalizedLeft = sanitizeHomeConsoleLeftRatio(leftRatio);
  final appliedLeftRatio = normalizedLeft
      .clamp(minLeft / available, maxLeft / available)
      .toDouble();
  final leftWidth = appliedLeftRatio * available;
  final centerWidth = available - leftWidth;
  return HomeConsoleLayout(
    mode: HomeConsoleLayoutMode.twoPane,
    width: width,
    availableWidth: available,
    leftWidth: leftWidth,
    centerWidth: centerWidth,
    rightWidth: 0,
    appliedLeftRatio: appliedLeftRatio,
    appliedRightRatio: 0,
    minLeftRatio: minLeft / available,
    maxLeftRatio: maxLeft / available,
    minRightRatio: 0,
    maxRightRatio: 0,
    canPushStats: false,
  );
}

HomeConsoleLayout _resolveThreePane({
  required double width,
  required double leftRatio,
  required double rightRatio,
  required bool statsExpanded,
}) {
  final available = width - kHomeConsoleDividerWidth * 2;
  if (available <= 0) {
    return const HomeConsoleLayout.compact();
  }
  final wantsExpanded =
      statsExpanded && width >= kHomeConsoleStatsPushMinWidth;
  final normalizedLeft = sanitizeHomeConsoleLeftRatio(leftRatio);
  final normalizedRight = sanitizeHomeConsoleRightRatio(rightRatio);

  const minRight = kHomeConsoleMinRightWidth;
  const minLeft = kHomeConsoleMinLeftWidth;
  final maxLeft = _minRatio(
    kHomeConsoleMaxLeftWidth,
    available -
        kHomeConsoleThreePaneMinCenterWidth -
        (wantsExpanded ? minRight : kHomeConsoleCollapsedRightWidth),
  );
  final appliedLeftRatio = normalizedLeft
      .clamp(minLeft / available, maxLeft / available)
      .toDouble();
  final leftWidth = appliedLeftRatio * available;

  // Clamp the right column against the width the left column actually took,
  // otherwise both side caps can be satisfied while the log falls below its
  // minimum.
  final maxRightForExpanded = _minRatio(
    kHomeConsoleMaxRightWidth,
    available - leftWidth - kHomeConsoleThreePaneMinCenterWidth,
  );
  final canExpand = wantsExpanded && maxRightForExpanded >= minRight;
  final rightWidth = canExpand
      ? (normalizedRight * available)
            .clamp(minRight.toDouble(), maxRightForExpanded)
            .toDouble()
      : kHomeConsoleCollapsedRightWidth;
  final appliedRightRatio = rightWidth / available;
  final minRightRatio = canExpand ? minRight / available : 0.0;
  final maxRightRatio = canExpand ? maxRightForExpanded / available : 0.0;
  final centerWidth = available - leftWidth - rightWidth;

  return HomeConsoleLayout(
    mode: HomeConsoleLayoutMode.threePane,
    width: width,
    availableWidth: available,
    leftWidth: leftWidth,
    centerWidth: centerWidth,
    rightWidth: rightWidth,
    appliedLeftRatio: appliedLeftRatio,
    appliedRightRatio: appliedRightRatio,
    minLeftRatio: minLeft / available,
    maxLeftRatio: maxLeft / available,
    minRightRatio: minRightRatio,
    maxRightRatio: maxRightRatio,
    canPushStats: canExpand,
  );
}

/// Clamps a live left-divider ratio to the current legal range.
double clampHomeConsoleLeftRatio({
  required HomeConsoleLayout layout,
  required double targetRatio,
}) {
  if (!layout.canShow) {
    return targetRatio;
  }
  return targetRatio.clamp(layout.minLeftRatio, layout.maxLeftRatio).toDouble();
}

/// Clamps a live right-divider ratio to the current legal range.
double clampHomeConsoleRightRatio({
  required HomeConsoleLayout layout,
  required double targetRatio,
}) {
  if (!layout.canPushStats || layout.maxRightRatio <= 0) {
    return targetRatio;
  }
  return targetRatio
      .clamp(layout.minRightRatio, layout.maxRightRatio)
      .toDouble();
}

double _minRatio(double left, double right) {
  return left < right ? left : right;
}
