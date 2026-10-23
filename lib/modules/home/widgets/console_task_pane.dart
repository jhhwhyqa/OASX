import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/bulk_quick_schedule_button.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/task_status_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Left console column: the active config task list.
class ConsoleTaskPane extends StatelessWidget {
  const ConsoleTaskPane({
    super.key,
    required this.controller,
    required this.script,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
    required this.onBulkQuickRun,
    required this.onBulkQuickWait,
    required this.onOpenTaskCatalog,
  });

  final HomeDashboardController controller;
  final ScriptModel script;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;
  final Future<void> Function() onBulkQuickRun;
  final Future<void> Function() onBulkQuickWait;
  final VoidCallback onOpenTaskCatalog;

  @override
  Widget build(BuildContext context) {
    return HomePaneCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Obx(() {
        final bulkMode = controller.bulkQuickScheduleMode.value;
        final isBulkIdle = bulkMode == HomeBulkQuickScheduleMode.none;
        final hasBulkTasks = controller
            .quickSchedulableTaskNamesFor(script)
            .isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(
              context,
              bulkMode: bulkMode,
              isBulkIdle: isBulkIdle,
              hasBulkTasks: hasBulkTasks,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TaskStatusPanel(
                controller: controller,
                scriptModel: script,
                canQuickScheduleTask: (taskName) =>
                    controller.canQuickScheduleTask(script, taskName),
                onSetNextRun: onSetNextRun,
                onQuickRun: onQuickRun,
                onQuickWait: onQuickWait,
                onEditTask: onEditTask,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required HomeBulkQuickScheduleMode bulkMode,
    required bool isBulkIdle,
    required bool hasBulkTasks,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final taskCount = _taskCount();
    return LayoutBuilder(
      builder: (context, constraints) {
        // At the minimum task width the two bulk actions no longer fit next to
        // the title, count and manage button. They stay reachable from the
        // task catalog instead of overflowing the header.
        final showBulkActions = constraints.maxWidth >= 240;
        return Row(
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                I18n.homeTasksTab.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$taskCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: I18n.taskManageTitle.tr,
              onPressed: onOpenTaskCatalog,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
              ),
              icon: const Icon(Icons.list_alt_rounded, size: 18),
            ),
            if (showBulkActions) ...[
              BulkQuickScheduleButton(
                icon: Icons.flash_on_rounded,
                tooltip: I18n.homeQuickRunAll.tr,
                loading: bulkMode == HomeBulkQuickScheduleMode.runNow,
                onPressed: isBulkIdle && hasBulkTasks ? onBulkQuickRun : null,
              ),
              BulkQuickScheduleButton(
                icon: Icons.schedule_rounded,
                tooltip: I18n.homeQuickWaitAll.tr,
                loading: bulkMode == HomeBulkQuickScheduleMode.waitNow,
                onPressed: isBulkIdle && hasBulkTasks ? onBulkQuickWait : null,
              ),
            ],
          ],
        );
      },
    );
  }

  int _taskCount() {
    final running = script.runningTask.value.taskName.value.trim().isEmpty
        ? 0
        : 1;
    return running +
        script.pendingTaskList.length +
        script.waitingTaskList.length;
  }
}
