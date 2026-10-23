import 'package:flutter/foundation.dart';
import 'package:oasx/modules/home/models/config_model.dart';

/// Resolved header status for the active config's running task.
enum ConsoleTaskStatusKind {
  /// A task is running and its name is known.
  runningWithTask,

  /// The script reports running but no task name is available yet.
  runningWithoutTask,

  /// The script is known to be idle.
  notStarted,

  /// The script state cannot be determined yet.
  unknown,

  /// The script reported an abnormal state.
  warning,

  /// The dashboard cannot reach the backend.
  disconnected,
}

/// Immutable snapshot of the running-task header state.
@immutable
class ConsoleTaskStatus {
  const ConsoleTaskStatus({required this.kind, required this.taskName});

  final ConsoleTaskStatusKind kind;

  /// Trimmed task name; empty unless [kind] is
  /// [ConsoleTaskStatusKind.runningWithTask].
  final String taskName;

  /// Whether the task should be treated as running.
  bool get isRunning {
    return kind == ConsoleTaskStatusKind.runningWithTask ||
        kind == ConsoleTaskStatusKind.runningWithoutTask;
  }

  /// Whether the header should offer a reconnect action instead of power.
  bool get needsRefresh {
    return kind == ConsoleTaskStatusKind.unknown ||
        kind == ConsoleTaskStatusKind.disconnected;
  }
}

/// Resolves the console task header status.
///
/// The precedence matches the retired running-task card so the header keeps
/// the same messages: connection failure, unknown state, warning, running
/// with a task name, running without a name, then idle. The script state wins
/// over a stale task name so the power action always matches reality.
ConsoleTaskStatus resolveConsoleTaskStatus({
  required String runningTaskName,
  required bool isRunning,
  required bool isUnknown,
  required bool connectionFailed,
  required ScriptState scriptState,
}) {
  final taskName = runningTaskName.trim();
  if (connectionFailed) {
    return const ConsoleTaskStatus(
      kind: ConsoleTaskStatusKind.disconnected,
      taskName: '',
    );
  }
  if (isUnknown) {
    return const ConsoleTaskStatus(
      kind: ConsoleTaskStatusKind.unknown,
      taskName: '',
    );
  }
  if (scriptState == ScriptState.warning) {
    return const ConsoleTaskStatus(
      kind: ConsoleTaskStatusKind.warning,
      taskName: '',
    );
  }
  // The script state is authoritative: the backend can keep the last task
  // name after a stop, and treating that stale name as "running" left the
  // power action stuck on stop so the config could not be started again.
  if (isRunning && taskName.isNotEmpty) {
    return ConsoleTaskStatus(
      kind: ConsoleTaskStatusKind.runningWithTask,
      taskName: taskName,
    );
  }
  if (isRunning) {
    return const ConsoleTaskStatus(
      kind: ConsoleTaskStatusKind.runningWithoutTask,
      taskName: '',
    );
  }
  return const ConsoleTaskStatus(
    kind: ConsoleTaskStatusKind.notStarted,
    taskName: '',
  );
}
