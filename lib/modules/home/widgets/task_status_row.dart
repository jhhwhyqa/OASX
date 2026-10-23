import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/widgets/split_scroll_row.dart';
import 'package:oasx/modules/home/widgets/task_status_swipe_container.dart';
import 'package:oasx/translation/i18n_content.dart';

part 'task_status_row_parts.dart';

/// Describes one task row rendered inside the overview task list.
class TaskStatusViewData {
  const TaskStatusViewData({
    required this.rowId,
    required this.name,
    required this.type,
    this.timeText = '',
  });

  final String rowId;
  final String name;
  final TaskStatusType type;
  final String timeText;
}

/// Defines the three task states rendered in the overview tab.
enum TaskStatusType { running, pending, waiting }

/// Renders one swipe-to-disable task row for the overview tab.
class TaskStatusRow extends StatelessWidget {
  const TaskStatusRow({
    super.key,
    required this.task,
    required this.canQuickSchedule,
    required this.quickScheduleLocked,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
    required this.onDisableTask,
    required this.onDismissed,
    required this.swipeEnabled,
  });

  final TaskStatusViewData task;
  final bool canQuickSchedule;
  final bool quickScheduleLocked;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;
  final Future<bool> Function(String taskName) onDisableTask;
  final ValueChanged<String> onDismissed;
  final bool swipeEnabled;
  static const double _actionExtent = 132;

  @override
  Widget build(BuildContext context) {
    final rowBackground = _rowBackground(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Narrow rows keep one overflow menu instead of three pinned icons so
        // the task name keeps as much width as possible.
        final compactActions =
            constraints.maxWidth < 240 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.25;
        return TaskStatusSwipeContainer(
          enabled: swipeEnabled,
          onConfirmDismiss: () => onDisableTask(task.name),
          onDismissed: () => onDismissed(task.rowId),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: rowBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderColor(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SplitScrollRow(
                minHeight: 40,
                trailingExtent: compactActions ? 44 : _actionExtent,
                trailingBackgroundColor: rowBackground,
                trailing: _TaskActionBar(
                  compact: compactActions,
                  onQuickRun: !quickScheduleLocked && canQuickSchedule
                      ? () => onQuickRun(task.name)
                      : null,
                  onQuickWait: !quickScheduleLocked && canQuickSchedule
                      ? () => onQuickWait(task.name)
                      : null,
                  onEditTask: () => onEditTask(task.name),
                ),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TaskTypeIcon(type: task.type),
                    const SizedBox(width: 10),
                    // A little vertical breathing room keeps scaled CJK glyphs
                    // inside the row's horizontal scroll viewport.
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _TaskMeta(
                        task: task,
                        onSetNextRun: onSetNextRun,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Resolves the row background by task bucket.
  Color _rowBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (task.type) {
      TaskStatusType.running => scheme.primaryContainer.withValues(alpha: 0.22),
      TaskStatusType.pending => scheme.surfaceContainerHigh.withValues(
        alpha: 0.62,
      ),
      TaskStatusType.waiting => scheme.surfaceContainerHigh.withValues(
        alpha: 0.30,
      ),
    };
  }

  /// Resolves the row border tint by task bucket.
  Color _borderColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (task.type) {
      TaskStatusType.running => scheme.primary.withValues(alpha: 0.32),
      TaskStatusType.pending => scheme.outlineVariant.withValues(alpha: 0.7),
      TaskStatusType.waiting => scheme.outlineVariant.withValues(alpha: 0.55),
    };
  }
}
