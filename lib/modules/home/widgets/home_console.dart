import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/controllers/statistics_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_console_layout.dart';
import 'package:oasx/modules/home/widgets/config_management_dialog.dart';
import 'package:oasx/modules/home/widgets/config_switcher_bar.dart';
import 'package:oasx/modules/home/widgets/console_stats_pane.dart';
import 'package:oasx/modules/home/widgets/console_task_status_view.dart';
import 'package:oasx/modules/home/widgets/console_task_pane.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/task_catalog_dialog.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Three-column desktop console for the home dashboard.
class HomeConsole extends StatefulWidget {
  const HomeConsole({
    super.key,
    required this.controller,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
    required this.onSelectScript,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onDeleteScript,
    required this.onExportScript,
    required this.onSetTaskNextRun,
    required this.onQuickRunTask,
    required this.onQuickWaitTask,
    required this.onBulkQuickRun,
    required this.onBulkQuickWait,
    required this.onOpenTask,
  });

  final HomeDashboardController controller;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;
  final Future<void> Function(String scriptName) onSelectScript;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onDeleteScript;
  final Future<void> Function(String scriptName) onExportScript;
  final Future<void> Function(String taskName, String nextRun) onSetTaskNextRun;
  final Future<void> Function(String taskName) onQuickRunTask;
  final Future<void> Function(String taskName) onQuickWaitTask;
  final Future<void> Function() onBulkQuickRun;
  final Future<void> Function() onBulkQuickWait;
  final Future<void> Function(
    String taskName,
    HomeTaskParameterEntrySource source,
  )
  onOpenTask;

  @override
  State<HomeConsole> createState() => _HomeConsoleState();
}

class _HomeConsoleState extends State<HomeConsole> {
  bool _logMaximized = false;
  double? _dragLeftRatio;
  double? _dragRightRatio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.controller.setConsoleStatsVisible(!_logMaximized);
      // The auto deploy flow replaces this console with the loading placeholder
      // and remounts it afterwards. Rebind the statistics here so a visibility
      // flag that was already true does not leave the pane on an empty state.
      if (Get.isRegistered<HomeStatisticsController>()) {
        unawaited(Get.find<HomeStatisticsController>().syncStatisticsBinding());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        return;
      }
      widget.controller.setConsoleStatsVisible(false);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConfigSwitcherBar(
          controller: widget.controller,
          loadingAddScript: widget.loadingAddScript,
          refreshingScripts: widget.refreshingScripts,
          onAddScriptTap: widget.onAddScriptTap,
          onRefreshScriptsTap: widget.onRefreshScriptsTap,
          onManageConfigsTap: () => _openConfigManagement(context),
          onSelectScript: widget.onSelectScript,
          onTogglePower: widget.onTogglePower,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Obx(() {
                final script = widget.controller.activeScriptModel;
                final leftRatio =
                    _dragLeftRatio ??
                    widget.controller.homeConsoleLeftRatio.value;
                final rightRatio =
                    _dragRightRatio ??
                    widget.controller.homeConsoleRightRatio.value;
                final layout = resolveHomeConsoleLayout(
                  maxWidth: constraints.maxWidth,
                  leftRatio: leftRatio,
                  rightRatio: rightRatio,
                );
                if (_logMaximized) {
                  return _buildCenterPane(
                    context,
                    script,
                    maximized: true,
                    onToggleMaximize: _toggleLogMaximized,
                  );
                }
                if (!layout.canShow) {
                  return _buildCenterPane(
                    context,
                    script,
                    maximized: false,
                    onToggleMaximize: _toggleLogMaximized,
                  );
                }
                return Row(
                  key: const ValueKey<String>('home-console-desktop'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: layout.leftWidth,
                      child: _buildLeftPane(context, script),
                    ),
                    _ConsoleDivider(
                      onDragStart: () => _handleLeftDragStart(layout),
                      onDragUpdate: (details) =>
                          _handleLeftDragUpdate(details, layout),
                      onDragEnd: () => _handleLeftDragEnd(),
                    ),
                    SizedBox(
                      width: layout.centerWidth,
                      child: _buildCenterPane(
                        context,
                        script,
                        maximized: false,
                        onToggleMaximize: _toggleLogMaximized,
                      ),
                    ),
                    _ConsoleDivider(
                      onDragStart: () => _handleRightDragStart(layout),
                      onDragUpdate: (details) =>
                          _handleRightDragUpdate(details, layout),
                      onDragEnd: () => _handleRightDragEnd(),
                    ),
                    SizedBox(
                      width: layout.rightWidth,
                      child: _buildRightPane(context, script),
                    ),
                  ],
                );
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPane(BuildContext context, ScriptModel? script) {
    if (script == null) {
      return _buildPanePlaceholder(
        context,
        icon: Icons.task_alt_rounded,
        message: I18n.homeNoScriptSelected.tr,
      );
    }
    return ConsoleTaskPane(
      controller: widget.controller,
      script: script,
      onSetNextRun: widget.onSetTaskNextRun,
      onQuickRun: widget.onQuickRunTask,
      onQuickWait: widget.onQuickWaitTask,
      onEditTask: (taskName) =>
          _openTaskCatalog(context, script, initialTaskName: taskName),
      onBulkQuickRun: widget.onBulkQuickRun,
      onBulkQuickWait: widget.onBulkQuickWait,
      onOpenTaskCatalog: () => _openTaskCatalog(context, script),
    );
  }

  Future<void> _openTaskCatalog(
    BuildContext context,
    ScriptModel script, {
    String? initialTaskName,
  }) {
    return showTaskCatalogDialog(
      context,
      controller: widget.controller,
      script: script,
      initialTaskName: initialTaskName,
      onOpenTask: (taskName) =>
          widget.onOpenTask(taskName, HomeTaskParameterEntrySource.tasks),
      onQuickRun: widget.onQuickRunTask,
      onQuickWait: widget.onQuickWaitTask,
    );
  }

  Widget _buildCenterPane(
    BuildContext context,
    ScriptModel? script, {
    required bool maximized,
    required VoidCallback onToggleMaximize,
  }) {
    if (script == null) {
      return _buildPanePlaceholder(
        context,
        icon: Icons.terminal_rounded,
        message: I18n.homeNoScriptSelected.tr,
      );
    }
    return LogCenterPanel(
      scriptName: script.name,
      showTitle: true,
      isMaximized: maximized,
      onToggleMaximize: onToggleMaximize,
      headerStatus: ConsoleTaskStatusView(
        controller: widget.controller,
        script: script,
      ),
      headerAction: ConsoleTaskAction(
        controller: widget.controller,
        script: script,
        onTogglePower: widget.onTogglePower,
        onRefreshScripts: widget.onRefreshScriptsTap,
      ),
    );
  }

  Widget _buildRightPane(BuildContext context, ScriptModel? script) {
    if (script == null) {
      return _buildPanePlaceholder(
        context,
        icon: Icons.insights_rounded,
        message: I18n.homeNoScriptSelected.tr,
      );
    }
    return ConsoleStatsPane(scriptName: script.name);
  }

  Widget _buildPanePlaceholder(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return HomePaneCard(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLogMaximized() {
    setState(() {
      _logMaximized = !_logMaximized;
    });
    widget.controller.setConsoleStatsVisible(!_logMaximized);
  }

  void _handleLeftDragStart(HomeConsoleLayout layout) {
    setState(() {
      _dragLeftRatio = layout.appliedLeftRatio;
    });
  }

  void _handleLeftDragUpdate(
    DragUpdateDetails details,
    HomeConsoleLayout layout,
  ) {
    final available = layout.availableWidth;
    if (available <= 0) {
      return;
    }
    final current = _dragLeftRatio ?? layout.appliedLeftRatio;
    final target = current + details.delta.dx / available;
    final clamped = clampHomeConsoleLeftRatio(
      layout: layout,
      targetRatio: target,
    );
    if ((clamped - current).abs() < 0.00001) {
      return;
    }
    setState(() {
      _dragLeftRatio = clamped;
    });
  }

  void _handleLeftDragEnd() {
    final ratio = _dragLeftRatio;
    if (ratio != null) {
      widget.controller.setHomeConsoleLeftRatio(ratio);
    }
    setState(() {
      _dragLeftRatio = null;
    });
  }

  void _handleRightDragStart(HomeConsoleLayout layout) {
    setState(() {
      _dragRightRatio = layout.appliedRightRatio;
    });
  }

  void _handleRightDragUpdate(
    DragUpdateDetails details,
    HomeConsoleLayout layout,
  ) {
    final available = layout.availableWidth;
    if (available <= 0) {
      return;
    }
    final current = _dragRightRatio ?? layout.appliedRightRatio;
    final target = current - details.delta.dx / available;
    final clamped = clampHomeConsoleRightRatio(
      layout: layout,
      targetRatio: target,
    );
    if ((clamped - current).abs() < 0.00001) {
      return;
    }
    setState(() {
      _dragRightRatio = clamped;
    });
  }

  void _handleRightDragEnd() {
    final ratio = _dragRightRatio;
    if (ratio != null) {
      widget.controller.setHomeConsoleRightRatio(ratio);
    }
    setState(() {
      _dragRightRatio = null;
    });
  }

  Future<void> _openConfigManagement(BuildContext context) {
    return showConfigManagementDialog(
      context,
      controller: widget.controller,
      loadingAddScript: widget.loadingAddScript,
      refreshingScripts: widget.refreshingScripts,
      onAddScriptTap: widget.onAddScriptTap,
      onRefreshScriptsTap: widget.onRefreshScriptsTap,
      onActivateScript: widget.onSelectScript,
      onTogglePower: widget.onTogglePower,
      onRenameScript: widget.onRenameScript,
      onExportScript: widget.onExportScript,
      onDeleteScript: widget.onDeleteScript,
    );
  }
}

class _ConsoleDivider extends StatefulWidget {
  const _ConsoleDivider({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final VoidCallback onDragStart;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  State<_ConsoleDivider> createState() => _ConsoleDividerState();
}

class _ConsoleDividerState extends State<_ConsoleDivider> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => widget.onDragStart(),
        onHorizontalDragUpdate: widget.onDragUpdate,
        onHorizontalDragEnd: (_) => widget.onDragEnd(),
        child: SizedBox(
          width: kHomeConsoleDividerWidth,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final lineHeight = (constraints.maxHeight * 0.6).clamp(
                24.0,
                72.0,
              );
              return Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: _hovered ? 3 : 2,
                  height: lineHeight,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? scheme.primary.withValues(alpha: 0.55)
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
