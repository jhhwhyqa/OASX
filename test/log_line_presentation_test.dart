import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/widgets/log_line_presentation.dart';

void main() {
  test('parses full timestamp, level and message', () {
    final line = parseScriptLogDisplayLine(
      '2026-10-22 12:34:56.789 INFO hello world',
    );

    expect(line.raw, '2026-10-22 12:34:56.789 INFO hello world');
    expect(line.timestamp, '10-22 12:34:56.789');
    expect(line.levelLabel, 'INFO');
    expect(line.level, ScriptLogDisplayLevel.info);
    expect(line.message, 'hello world');
  });

  test('parses a bracketed level without a timestamp', () {
    final line = parseScriptLogDisplayLine('WARNING: disk nearly full');

    expect(line.timestamp, isEmpty);
    expect(line.levelLabel, 'WARNING');
    expect(line.level, ScriptLogDisplayLevel.warning);
    expect(line.message, 'disk nearly full');
  });

  test('keeps continuation lines intact', () {
    final line = parseScriptLogDisplayLine('  at foo.bar(baz.dart:10)');

    expect(line.timestamp, isEmpty);
    expect(line.levelLabel, isNull);
    expect(line.level, ScriptLogDisplayLevel.unknown);
    expect(line.message, 'at foo.bar(baz.dart:10)');
    expect(line.raw, '  at foo.bar(baz.dart:10)');
  });

  test('maps critical and error variants to the error level', () {
    final critical = parseScriptLogDisplayLine(
      '2026-10-22 12:34:56 CRITICAL boom',
    );
    final fatal = parseScriptLogDisplayLine('2026-10-22 12:34:56 FATAL boom');
    final shortError = parseScriptLogDisplayLine(
      '2026-10-22 12:34:56 ERR boom',
    );

    expect(critical.level, ScriptLogDisplayLevel.error);
    expect(fatal.level, ScriptLogDisplayLevel.error);
    expect(shortError.levelLabel, 'ERROR');
  });

  test('filters by text and level', () {
    final info = parseScriptLogDisplayLine('2026-10-22 12:34:56 INFO started');
    final error = parseScriptLogDisplayLine('2026-10-22 12:35:00 ERROR failed');

    expect(scriptLogLineMatchesQuery(info, 'started'), isTrue);
    expect(scriptLogLineMatchesQuery(info, 'failed'), isFalse);
    expect(
      scriptLogLineMatchesLevel(error, ScriptLogLevelFilter.error),
      isTrue,
    );
    expect(
      scriptLogLineMatchesLevel(error, ScriptLogLevelFilter.info),
      isFalse,
    );
    expect(scriptLogLineMatchesLevel(info, ScriptLogLevelFilter.all), isTrue);
  });
}
