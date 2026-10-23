import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/home_console_layout.dart';

void main() {
  test('console collapses to one pane below the two-pane breakpoint', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: kHomeConsoleTwoPaneMinWidth - 1,
      leftRatio: 0.26,
      rightRatio: 0.29,
    );

    expect(layout.mode, HomeConsoleLayoutMode.compact);
    expect(layout.canShow, isFalse);
  });

  test('700px keeps the task column and a readable log', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: kHomeConsoleTwoPaneMinWidth,
      leftRatio: 0.26,
      rightRatio: 0.29,
    );

    expect(layout.mode, HomeConsoleLayoutMode.twoPane);
    expect(layout.canShow, isTrue);
    expect(layout.leftWidth, greaterThanOrEqualTo(kHomeConsoleMinLeftWidth));
    expect(layout.centerWidth, greaterThanOrEqualTo(kHomeConsoleMinCenterWidth));
    expect(layout.rightWidth, 0);
    expect(
      layout.leftWidth + layout.centerWidth,
      closeTo(layout.availableWidth, 0.001),
    );
  });

  test('three-pane layout starts at 1000px with statistics collapsed', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: kHomeConsoleThreePaneMinWidth,
      leftRatio: 0.26,
      rightRatio: 0.29,
    );

    expect(layout.mode, HomeConsoleLayoutMode.threePane);
    expect(layout.rightWidth, kHomeConsoleCollapsedRightWidth);
    expect(layout.centerWidth, greaterThanOrEqualTo(
      kHomeConsoleThreePaneMinCenterWidth,
    ));
    expect(layout.canPushStats, isFalse);
  });

  test('1280px expanded statistics keep the log column dominant', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: 1280,
      leftRatio: 0.26,
      rightRatio: 0.29,
      statsExpanded: true,
    );

    expect(layout.canPushStats, isTrue);
    expect(layout.leftWidth, greaterThanOrEqualTo(kHomeConsoleMinLeftWidth));
    expect(layout.centerWidth, greaterThanOrEqualTo(
      kHomeConsoleThreePaneMinCenterWidth,
    ));
    expect(layout.rightWidth, greaterThanOrEqualTo(kHomeConsoleMinRightWidth));
    expect(layout.centerWidth, greaterThan(layout.leftWidth));
    expect(layout.centerWidth, greaterThan(layout.rightWidth));
    expect(
      layout.leftWidth + layout.centerWidth + layout.rightWidth,
      closeTo(layout.availableWidth, 0.001),
    );
  });

  test('expanded statistics never shrink the log below its minimum', () {
    final threshold = resolveHomeConsoleLayout(
      maxWidth: 1080,
      leftRatio: 0.26,
      rightRatio: 0.29,
      statsExpanded: true,
    );
    expect(
      threshold.centerWidth,
      greaterThanOrEqualTo(kHomeConsoleThreePaneMinCenterWidth - 0.001),
    );

    final wide = resolveHomeConsoleLayout(
      maxWidth: 1200,
      leftRatio: 0.45,
      rightRatio: 0.45,
      statsExpanded: true,
    );
    expect(
      wide.centerWidth,
      greaterThanOrEqualTo(kHomeConsoleThreePaneMinCenterWidth - 0.001),
    );
    expect(
      wide.leftWidth + wide.centerWidth + wide.rightWidth,
      closeTo(wide.availableWidth, 0.001),
    );
  });

  test('very wide expanded layouts cap the side columns', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: 1920,
      leftRatio: 0.26,
      rightRatio: 0.29,
      statsExpanded: true,
    );

    expect(
      layout.leftWidth,
      lessThanOrEqualTo(kHomeConsoleMaxLeftWidth + 0.001),
    );
    expect(
      layout.rightWidth,
      lessThanOrEqualTo(kHomeConsoleMaxRightWidth + 0.001),
    );
    expect(layout.centerWidth, greaterThan(layout.leftWidth));
    expect(layout.centerWidth, greaterThan(layout.rightWidth));
  });

  test('ratio sanitizers fall back for invalid values', () {
    expect(sanitizeHomeConsoleLeftRatio(null), kHomeConsoleDefaultLeftRatio);
    expect(
      sanitizeHomeConsoleRightRatio('not-a-number'),
      kHomeConsoleDefaultRightRatio,
    );
    expect(sanitizeHomeConsoleLeftRatio(9), kHomeConsoleMaxRatio);
    expect(sanitizeHomeConsoleRightRatio(-1), kHomeConsoleMinRatio);
  });

  test('live divider clamps preserve the minimum log width', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: 1280,
      leftRatio: 0.26,
      rightRatio: 0.29,
      statsExpanded: true,
    );
    final left = clampHomeConsoleLeftRatio(layout: layout, targetRatio: 0.9);
    final right = clampHomeConsoleRightRatio(layout: layout, targetRatio: 0.9);

    expect(left, lessThanOrEqualTo(layout.maxLeftRatio));
    expect(right, lessThanOrEqualTo(layout.maxRightRatio));
    final resolved = resolveHomeConsoleLayout(
      maxWidth: 1280,
      leftRatio: left,
      rightRatio: right,
      statsExpanded: true,
    );
    expect(
      resolved.centerWidth,
      greaterThanOrEqualTo(kHomeConsoleThreePaneMinCenterWidth - 0.001),
    );
    expect(
      resolved.leftWidth + resolved.centerWidth + resolved.rightWidth,
      closeTo(resolved.availableWidth, 0.001),
    );
  });
}
