import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/home_console_layout.dart';

void main() {
  test('console is hidden below the desktop breakpoint', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: kHomeConsoleMinWidth - 1,
      leftRatio: 0.26,
      rightRatio: 0.29,
    );

    expect(layout.canShow, isFalse);
  });

  test('1280px layout keeps the log column dominant', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: 1280,
      leftRatio: 0.26,
      rightRatio: 0.29,
    );

    expect(layout.canShow, isTrue);
    expect(layout.leftWidth, greaterThanOrEqualTo(kHomeConsoleMinLeftWidth));
    expect(
      layout.centerWidth,
      greaterThanOrEqualTo(kHomeConsoleMinCenterWidth),
    );
    expect(layout.rightWidth, greaterThanOrEqualTo(kHomeConsoleMinRightWidth));
    expect(layout.centerWidth, greaterThan(layout.leftWidth));
    expect(layout.centerWidth, greaterThan(layout.rightWidth));
    expect(
      layout.leftWidth + layout.centerWidth + layout.rightWidth,
      closeTo(layout.availableWidth, 0.001),
    );
  });

  test('very wide layouts cap both side columns', () {
    final layout = resolveHomeConsoleLayout(
      maxWidth: 1920,
      leftRatio: 0.26,
      rightRatio: 0.29,
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
      maxWidth: 1080,
      leftRatio: 0.26,
      rightRatio: 0.29,
    );
    final left = clampHomeConsoleLeftRatio(layout: layout, targetRatio: 0.9);
    final right = clampHomeConsoleRightRatio(layout: layout, targetRatio: 0.9);

    expect(left, lessThanOrEqualTo(layout.maxLeftRatio));
    expect(right, lessThanOrEqualTo(layout.maxRightRatio));
    final resolved = resolveHomeConsoleLayout(
      maxWidth: 1080,
      leftRatio: left,
      rightRatio: right,
    );
    expect(
      resolved.centerWidth,
      greaterThanOrEqualTo(kHomeConsoleMinCenterWidth - 0.001),
    );
    expect(
      resolved.leftWidth + resolved.centerWidth + resolved.rightWidth,
      closeTo(resolved.availableWidth, 0.001),
    );
  });
}
