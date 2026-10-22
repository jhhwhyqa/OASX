import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/console_task_status.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Key used by widget tests to locate the running task name.
const ValueKey<String> kConsoleTaskStatusNameKey = ValueKey<String>(
  'home-console-task-status-name',
);

/// Key used by widget tests to locate the power/reconnect action.
const ValueKey<String> kConsoleTaskActionKey = ValueKey<String>(
  'home-console-task-action',
);

/// Minimum width before the header keeps the textual status next to the name.
const double kConsoleTaskStatusTextMinWidth = 160;

/// Compact running-task status rendered inside the log center header.
///
/// The view owns its [Obx] subscription so task heartbeats only rebuild this
/// small widget instead of the log panel that holds the scroll controllers.
class ConsoleTaskStatusView extends StatelessWidget {
  const ConsoleTaskStatusView({
    super.key,
    required this.controller,
    required this.script,
  });

  final HomeDashboardController controller;
  final ScriptModel script;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final status = _resolveLiveStatus(controller, script);
          final presentation = _presentation(context, status);
          final showStatusText =
              constraints.maxWidth >= _statusTextMinWidth(context);
          // When the header squeezes the status slot below the dot width,
          // dropping the dot keeps the row from overflowing. The name stays
          // in the tree so layout never throws at pathological widths.
          final showDot = constraints.maxWidth >= 14;
          final hasName = status.taskName.isNotEmpty;
          final textTheme = Theme.of(context).textTheme;
          final scheme = Theme.of(context).colorScheme;
          final nameStyle = textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          );
          final statusStyle = textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: presentation.color,
          );
          final row = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot) ...[
                _StatusDot(
                  color: presentation.color,
                  filled: presentation.filledDot,
                ),
                const SizedBox(width: 6),
              ],
              if (hasName)
                Flexible(
                  child: Text(
                    status.taskName,
                    key: kConsoleTaskStatusNameKey,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: nameStyle,
                  ),
                ),
              if (hasName && showStatusText) ...[
                const SizedBox(width: 6),
                Text(
                  '·',
                  style: textTheme.labelSmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(width: 6),
              ],
              if (!hasName || showStatusText)
                Flexible(
                  child: Text(
                    presentation.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: statusStyle,
                  ),
                ),
            ],
          );
          final semanticsLabel = hasName
              ? '${I18n.homeConsoleRunningTask.tr}: '
                    '${status.taskName}, ${presentation.label}'
              : presentation.label;
          return Tooltip(
            message: presentation.tooltip,
            waitDuration: const Duration(milliseconds: 500),
            child: Semantics(
              container: true,
              label: semanticsLabel,
              excludeSemantics: true,
              child: row,
            ),
          );
        });
      },
    );
  }

  _StatusPresentation _presentation(
    BuildContext context,
    ConsoleTaskStatus status,
  ) {
    final colors = OasxStateColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return switch (status.kind) {
      ConsoleTaskStatusKind.runningWithTask => _StatusPresentation(
        label: I18n.homeConsoleTaskRunning.tr,
        tooltip: I18n.homeConsoleRunningTask.tr,
        color: colors.running,
        filledDot: true,
      ),
      ConsoleTaskStatusKind.runningWithoutTask => _StatusPresentation(
        label:
            '${I18n.homeConsoleTaskRunning.tr} · '
            '${I18n.homeConsoleTaskUnreported.tr}',
        tooltip: I18n.homeConsoleTaskUnreported.tr,
        color: colors.running,
        filledDot: true,
      ),
      ConsoleTaskStatusKind.notStarted => _StatusPresentation(
        label: I18n.homeConsoleNotStarted.tr,
        tooltip: I18n.homeConsoleNotStarted.tr,
        color: scheme.outline,
        filledDot: false,
      ),
      ConsoleTaskStatusKind.unknown => _StatusPresentation(
        label: I18n.homeConsoleStatusUnknown.tr,
        tooltip: I18n.homeConsoleStatusUnknown.tr,
        color: colors.abnormal,
        filledDot: true,
      ),
      ConsoleTaskStatusKind.warning => _StatusPresentation(
        label: I18n.homeScriptAbnormal.tr,
        tooltip: I18n.homeScriptAbnormal.tr,
        color: colors.abnormal,
        filledDot: true,
      ),
      ConsoleTaskStatusKind.disconnected => _StatusPresentation(
        label: I18n.homeConsoleDisconnected.tr,
        tooltip: I18n.homeConnectionRetryHint.tr,
        color: colors.abnormal,
        filledDot: true,
      ),
    };
  }

  double _statusTextMinWidth(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    return kConsoleTaskStatusTextMinWidth * scale;
  }
}

/// Resolves the live console status from the dashboard and script state.
///
/// Both the header view and the action share this helper so the visible state
/// and the offered action never disagree.
ConsoleTaskStatus _resolveLiveStatus(
  HomeDashboardController controller,
  ScriptModel script,
) {
  final connectionFailed = controller.isStartupConnectionFailed.value;
  final checking = controller.isStartupChecking.value;
  final state = script.state.value;
  final runningName = script.runningTask.value.taskName.value.trim();
  return resolveConsoleTaskStatus(
    runningTaskName: runningName,
    isRunning: state == ScriptState.running,
    isUnknown:
        connectionFailed ||
        state == ScriptState.updating ||
        (checking && runningName.isEmpty),
    connectionFailed: connectionFailed,
    scriptState: state,
  );
}

/// Power or reconnect action for the active config.
class ConsoleTaskAction extends StatefulWidget {
  const ConsoleTaskAction({
    super.key,
    required this.controller,
    required this.script,
    required this.onTogglePower,
    this.onRefreshScripts,
  });

  final HomeDashboardController controller;
  final ScriptModel script;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final VoidCallback? onRefreshScripts;

  @override
  State<ConsoleTaskAction> createState() => _ConsoleTaskActionState();
}

class _ConsoleTaskActionState extends State<ConsoleTaskAction> {
  bool _busy = false;

  @override
  void didUpdateWidget(covariant ConsoleTaskAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.script.name != widget.script.name) {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = _resolveLiveStatus(widget.controller, widget.script);
      final colors = OasxStateColors.of(context);
      final scheme = Theme.of(context).colorScheme;

      if (status.needsRefresh) {
        final refresh = widget.onRefreshScripts;
        if (refresh == null) {
          return const SizedBox.shrink();
        }
        return _buildButton(
          icon: Icons.refresh_rounded,
          tooltip: I18n.homeConnectionRetryAction.tr,
          onPressed: refresh,
          foreground: colors.abnormal,
        );
      }

      final isRunning = status.isRunning;
      return _buildButton(
        icon: Icons.power_settings_new_rounded,
        tooltip: (isRunning ? I18n.stop : I18n.run).tr,
        onPressed: () => _togglePower(!isRunning),
        foreground: isRunning ? colors.running : scheme.onSurfaceVariant,
        background: isRunning ? colors.running.withValues(alpha: 0.10) : null,
      );
    });
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color foreground,
    Color? background,
  }) {
    return IconButton(
      key: kConsoleTaskActionKey,
      tooltip: tooltip,
      onPressed: _busy ? null : onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
      iconSize: 20,
      style: IconButton.styleFrom(
        fixedSize: const Size(36, 36),
        foregroundColor: foreground,
        backgroundColor: background,
        disabledForegroundColor: foreground.withValues(alpha: 0.38),
      ),
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
    );
  }

  Future<void> _togglePower(bool enable) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
    });
    try {
      await widget.onTogglePower(widget.script.name, enable);
    } catch (error) {
      Get.snackbar(I18n.error.tr, '$error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: color, width: 1.4),
      ),
    );
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.tooltip,
    required this.color,
    required this.filledDot,
  });

  final String label;
  final String tooltip;
  final Color color;
  final bool filledDot;
}
