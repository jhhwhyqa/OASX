/// Semantic level parsed from one raw log line.
enum ScriptLogDisplayLevel { info, warning, error, debug, unknown }

/// Local log level filter used by the console toolbar.
enum ScriptLogLevelFilter { all, info, warning, error }

/// Presentation-only decomposition of one raw log line.
///
/// [raw] always keeps the complete source text so details and copy actions
/// never lose data.
class ScriptLogDisplayLine {
  const ScriptLogDisplayLine({
    required this.raw,
    required this.timestamp,
    required this.levelLabel,
    required this.level,
    required this.message,
  });

  final String raw;
  final String timestamp;
  final String? levelLabel;
  final ScriptLogDisplayLevel level;
  final String message;

  /// Whether the line has any level information.
  bool get hasLevel => levelLabel != null;
}

final RegExp _timestampPattern = RegExp(
  r'^\[?(\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:[.,]\d{1,6})?|\d{2}:\d{2}:\d{2}(?:[.,]\d{1,6})?)\]?[ \t]*(?:[-–—|][ \t]*)?',
);

final RegExp _levelPattern = RegExp(
  r'^\[?(INFO|WARNING|WARN|ERROR|ERR|CRITICAL|FATAL|DEBUG|NOTICE|TRACE|SUCCESS)\]?[ \t]*(?:[:|–—-][ \t]*)?',
  caseSensitive: false,
);

/// Parses one raw log line into stable timestamp, level and message columns.
ScriptLogDisplayLine parseScriptLogDisplayLine(String raw) {
  var remainder = raw;
  var timestamp = '';

  final timestampMatch = _timestampPattern.firstMatch(remainder);
  if (timestampMatch != null && timestampMatch.end > 0) {
    timestamp = _formatDisplayTimestamp(timestampMatch.group(1) ?? '');
    remainder = remainder.substring(timestampMatch.end);
  }

  String? levelLabel;
  var level = ScriptLogDisplayLevel.unknown;
  final levelMatch = _levelPattern.firstMatch(remainder);
  if (levelMatch != null && levelMatch.end > 0) {
    final normalized = (levelMatch.group(1) ?? '').toUpperCase();
    level = _levelForToken(normalized);
    levelLabel = _displayLevelLabel(normalized);
    remainder = remainder.substring(levelMatch.end);
  }

  remainder = _trimMessageStart(remainder);
  return ScriptLogDisplayLine(
    raw: raw,
    timestamp: timestamp,
    levelLabel: levelLabel,
    level: level,
    message: remainder,
  );
}

/// Returns whether one line matches the local text search.
bool scriptLogLineMatchesQuery(ScriptLogDisplayLine line, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return line.raw.toLowerCase().contains(normalized);
}

/// Returns whether one line matches the selected level filter.
bool scriptLogLineMatchesLevel(
  ScriptLogDisplayLine line,
  ScriptLogLevelFilter filter,
) {
  return switch (filter) {
    ScriptLogLevelFilter.all => true,
    ScriptLogLevelFilter.info => line.level == ScriptLogDisplayLevel.info,
    ScriptLogLevelFilter.warning => line.level == ScriptLogDisplayLevel.warning,
    ScriptLogLevelFilter.error => line.level == ScriptLogDisplayLevel.error,
  };
}

String _formatDisplayTimestamp(String value) {
  final normalized = value.replaceFirst('T', ' ').replaceAll(',', '.');
  if (normalized.length >= 19 && normalized[4] == '-') {
    // Drop the year in the row; the full timestamp remains in the raw line.
    return normalized.substring(5);
  }
  return normalized;
}

String _displayLevelLabel(String token) {
  return switch (token) {
    'WARN' => 'WARNING',
    'ERR' => 'ERROR',
    'FATAL' => 'ERROR',
    _ => token,
  };
}

ScriptLogDisplayLevel _levelForToken(String token) {
  return switch (token) {
    'INFO' || 'NOTICE' || 'SUCCESS' => ScriptLogDisplayLevel.info,
    'WARNING' || 'WARN' => ScriptLogDisplayLevel.warning,
    'ERROR' || 'ERR' || 'CRITICAL' || 'FATAL' => ScriptLogDisplayLevel.error,
    'DEBUG' || 'TRACE' => ScriptLogDisplayLevel.debug,
    _ => ScriptLogDisplayLevel.unknown,
  };
}

String _trimMessageStart(String value) {
  var index = 0;
  while (index < value.length) {
    final code = value.codeUnitAt(index);
    if (code == 32 || code == 9) {
      index++;
      continue;
    }
    if (code == 58 || code == 45 || code == 124) {
      index++;
      while (index < value.length) {
        final next = value.codeUnitAt(index);
        if (next != 32 && next != 9) {
          break;
        }
        index++;
      }
      continue;
    }
    break;
  }
  return value.substring(index);
}
