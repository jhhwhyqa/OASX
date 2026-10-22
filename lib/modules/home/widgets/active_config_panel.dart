import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/widgets/bulk_quick_schedule_button.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/script_state_presentation.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/modules/home/widgets/task_catalog_panel.dart';
import 'package:oasx/modules/home/widgets/task_status_panel.dart';
import 'package:oasx/modules/home/widgets/workbench_tab_chip.dart';
import 'package:oasx/translation/i18n_content.dart';

class ActiveConfigPanel extends StatelessWidget {
  const ActiveConfigPanel({
    super.key,
    required this.controller,
    required this.layoutMode,
    required this.onChangeTab,
    required this.onOpenTask,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onDeleteScript,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onBulkQuickRun,
    required this.onBulkQuickWait,
    this.onExpandRightSidebar,
    this.onBackToScripts,
  });

  final HomeDashboardController controller;
  final HomeWorkbenchLayoutMode layoutMode;
  final Future<void> Function(HomeWorkbenchTab tab) onChangeTab;
  final Future<void> Function(
    String taskName,
    HomeTaskParameterEntrySource source,
  )
  onOpenTask;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onDeleteScript;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function() onBulkQuickRun;
  final Future<void> Function() onBulkQuickWait;
  final VoidCallback? onExpandRightSidebar;
  final VoidCallback? onBackToScripts;

  @override
  Widget build(BuildContext context) {
    return HomePaneCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Obx(() {
        final script = controller.activeScriptModel;
        final currentTab = controller.displayedWorkbenchTabFor(layoutMode);
        final tabs = controller.workbenchTabsFor(layoutMode);
        if (script == null) {
          return _buildNoSelection(context);
        }
        final isRunning = script.state.value == ScriptState.running;
        final bulkMode = controller.bulkQuickScheduleMode.value;
        final hasBulkTasks = controller
            .quickSchedulableTaskNamesFor(script)
            .isNotEmpty;
        final isBulkIdle = bulkMode == HomeBulkQuickScheduleMode.none;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              script: script,
              isRunning: isRunning,
              bulkMode: bulkMode,
              hasBulkTasks: hasBulkTasks,
              isBulkIdle: isBulkIdle,
            ),
            const SizedBox(height: 10),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tabs
                  .map(
                    (tab) => WorkbenchTabChip(
                      label: _tabLabel(tab),
                      selected: currentTab == tab,
                      onSelected: () => onChangeTab(tab),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildTabContent(script, currentTab)),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required ScriptModel script,
    required bool isRunning,
    required HomeBulkQuickScheduleMode bulkMode,
    required bool hasBulkTasks,
    required bool isBulkIdle,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = controller.scriptStateFor(script);
    final stateColor = state.color(context);
    return Row(
      children: [
        if (onBackToScripts != null) ...[
          IconButton(
            tooltip: I18n.scriptList.tr,
            onPressed: onBackToScripts,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          const SizedBox(width: 2),
        ],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                script.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              ScriptStateBadge(state: state),
            ],
          ),
        ),
        const SizedBox(width: 8),
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
        const SizedBox(width: 2),
        IconButton(
          tooltip: isRunning ? I18n.stop.tr : I18n.run.tr,
          onPressed: () => onTogglePower(script.name, !isRunning),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 38, height: 38),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: isRunning ? stateColor : scheme.onSurfaceVariant,
            backgroundColor: isRunning
                ? stateColor.withValues(alpha: 0.10)
                : null,
          ),
          icon: const Icon(Icons.power_settings_new_rounded, size: 21),
        ),
        if (onExpandRightSidebar != null) ...[
          const SizedBox(width: 2),
          IconButton.filledTonal(
            key: const ValueKey<String>('home-workbench-expand-right-sidebar'),
            tooltip: I18n.homeRestoreSidebar.tr,
            onPressed: onExpandRightSidebar,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.keyboard_double_arrow_left_rounded,
              size: 20,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoSelection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.dashboard_customize_outlined,
                size: 24,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            I18n.homeNoScriptSelected.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(ScriptModel script, HomeWorkbenchTab currentTab) {
    return switch (currentTab) {
      HomeWorkbenchTab.status => TaskStatusPanel(
        controller: controller,
        scriptModel: script,
        canQuickScheduleTask: (taskName) =>
            controller.canQuickScheduleTask(script, taskName),
        onSetNextRun: onSetNextRun,
        onQuickRun: onQuickRun,
        onQuickWait: onQuickWait,
        onEditTask: (taskName) =>
            onOpenTask(taskName, HomeTaskParameterEntrySource.overview),
      ),
      HomeWorkbenchTab.tasks => TaskCatalogPanel(
        controller: controller,
        scriptModel: script,
        onOpenTask: (taskName) =>
            onOpenTask(taskName, HomeTaskParameterEntrySource.tasks),
        onQuickRun: onQuickRun,
        onQuickWait: onQuickWait,
      ),
      HomeWorkbenchTab.stats => const ScriptStatisticsPanel(),
      HomeWorkbenchTab.logs => LogCenterPanel(scriptName: script.name),
    };
  }

  String _tabLabel(HomeWorkbenchTab value) {
    return switch (value) {
      HomeWorkbenchTab.status => I18n.overview.tr,
      HomeWorkbenchTab.tasks => I18n.homeTasksTab.tr,
      HomeWorkbenchTab.stats => I18n.homeStatsTab.tr,
      HomeWorkbenchTab.logs => I18n.log.tr,
    };
  }
}
