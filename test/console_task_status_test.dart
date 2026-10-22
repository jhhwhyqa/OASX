import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/console_task_status.dart';

void main() {
  ConsoleTaskStatus resolve({
    String runningTaskName = '',
    bool isRunning = false,
    bool isUnknown = false,
    bool connectionFailed = false,
    ScriptState scriptState = ScriptState.inactive,
  }) {
    return resolveConsoleTaskStatus(
      runningTaskName: runningTaskName,
      isRunning: isRunning,
      isUnknown: isUnknown,
      connectionFailed: connectionFailed,
      scriptState: scriptState,
    );
  }

  test('reports the running task name', () {
    final status = resolve(
      runningTaskName: 'daily quest',
      isRunning: true,
      scriptState: ScriptState.running,
    );

    expect(status.kind, ConsoleTaskStatusKind.runningWithTask);
    expect(status.taskName, 'daily quest');
    expect(status.isRunning, isTrue);
    expect(status.needsRefresh, isFalse);
  });

  test('trims the running task name', () {
    final status = resolve(
      runningTaskName: '  daily quest  ',
      isRunning: true,
      scriptState: ScriptState.running,
    );

    expect(status.kind, ConsoleTaskStatusKind.runningWithTask);
    expect(status.taskName, 'daily quest');
  });

  test('keeps running when the task name is not reported yet', () {
    final status = resolve(
      runningTaskName: '   ',
      isRunning: true,
      scriptState: ScriptState.running,
    );

    expect(status.kind, ConsoleTaskStatusKind.runningWithoutTask);
    expect(status.taskName, isEmpty);
    expect(status.isRunning, isTrue);
  });

  test('connection failure wins over every other signal', () {
    final status = resolve(
      runningTaskName: 'daily quest',
      isRunning: true,
      isUnknown: true,
      connectionFailed: true,
      scriptState: ScriptState.running,
    );

    expect(status.kind, ConsoleTaskStatusKind.disconnected);
    expect(status.taskName, isEmpty);
    expect(status.isRunning, isFalse);
    expect(status.needsRefresh, isTrue);
  });

  test('unknown state offers the reconnect action', () {
    final status = resolve(isUnknown: true, scriptState: ScriptState.updating);

    expect(status.kind, ConsoleTaskStatusKind.unknown);
    expect(status.needsRefresh, isTrue);
  });

  test('warning takes precedence over a stale task name', () {
    final status = resolve(
      runningTaskName: 'daily quest',
      scriptState: ScriptState.warning,
    );

    expect(status.kind, ConsoleTaskStatusKind.warning);
    expect(status.taskName, isEmpty);
    expect(status.isRunning, isFalse);
  });

  test('idle script is reported as not started', () {
    final status = resolve(scriptState: ScriptState.inactive);

    expect(status.kind, ConsoleTaskStatusKind.notStarted);
    expect(status.taskName, isEmpty);
    expect(status.isRunning, isFalse);
    expect(status.needsRefresh, isFalse);
  });
}
