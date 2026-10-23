import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oasx/config/design_system.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_console_layout.dart';
import 'package:oasx/modules/home/widgets/config_management_dialog.dart';
import 'package:oasx/modules/home/widgets/config_switcher_bar.dart';
import 'package:oasx/modules/home/widgets/console_stats_pane.dart';
import 'package:oasx/modules/home/widgets/console_task_status_view.dart';
import 'package:oasx/modules/home/widgets/console_task_pane.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
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

enum _ConsoleCompactTab { log, tasks, stats }

class _HomeConsoleState extends State<HomeConsole> {
  bool _logMaximized = false;

  /// Statistics stay folded until the user expands the rail, which keeps the
  /// statistics transport closed during startup and auto deploy.
  bool _statsExpanded = false;
  _ConsoleCompactTab _compactTab = _ConsoleCompactTab.log;
  bool _lastStatsVisible = false;
  double? _dragLeftRatio;
  double? _dragRightRatio;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.controller.setConsoleLayoutActive(true);
      widget.controller.setConsoleStatsVisible(false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        return;
      }
      widget.controller.setConsoleLayoutActive(false);
      widget.controller.setConsoleStatsVisible(false);
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final script = widget.controller.activeScriptModel;
      return LayoutBuilder(
        builder: (context, constraints) {
          final leftRatio =
              _dragLeftRatio ?? widget.controller.homeConsoleLeftRatio.value;
          final rightRatio =
              _dragRightRatio ?? widget.controller.homeConsoleRightRatio.value;
          final layout = resolveHomeConsoleLayout(
            maxWidth: constraints.maxWidth,
            leftRatio: leftRatio,
            rightRatio: rightRatio,
            statsExpanded: _statsExpanded,
          );
          _syncStatsVisibility(layout);
          final compact = layout.mode == HomeConsoleLayoutMode.compact;
          return Column(
            children: [
              ConfigSwitcherBar(
                controller: widget.controller,
                compact: compact,
                loadingAddScript: widget.loadingAddScript,
                refreshingScripts: widget.refreshingScripts,
                onAddScriptTap: widget.onAddScriptTap,
                onRefreshScriptsTap: widget.onRefreshScriptsTap,
                onManageConfigsTap: () => _openConfigManagement(context),
                onSelectScript: widget.onSelectScript,
                onTogglePower: widget.onTogglePower,
              ),
              const SizedBox(height: OasxSpace.md),
              Expanded(
                child: compact
                    ? _buildCompactBody(context, script)
                    : _buildDesktopBody(context, script, layout),
              ),
            ],
          );
        },
      );
    });
  }

  /// Keeps the statistics transport aligned with the active composition.
  ///
  /// Called from build, but only schedules a callback when the resolved
  /// visibility actually changes.
  void _syncStatsVisibility(HomeConsoleLayout layout) {
    final compact = layout.mode == HomeConsoleLayoutMode.compact;
    // A maximized log from a wider layout must not suppress the compact
    // statistics tab, where the maximize control is not available.
    final effectiveMaximized = _logMaximized && !compact;
    final visible =
        !effectiveMaximized &&
        (compact ? _compactTab == _ConsoleCompactTab.stats : _statsExpanded);
    if (visible == _lastStatsVisible) {
      return;
    }
    _lastStatsVisible = visible;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.setConsoleStatsVisible(visible);
      }
    });
  }

  Widget _buildDesktopBody(
    BuildContext context,
    ScriptModel? script,
    HomeConsoleLayout layout,
  ) {
    if (_logMaximized) {
      return _buildCenterPane(
        context,
        script,
        maximized: true,
        onToggleMaximize: _toggleLogMaximized,
      );
    }
    final overlayOpen = _statsExpanded && !layout.canPushStats;
    final row = Row(
      key: const ValueKey<String>('home-console-desktop'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: layout.leftWidth,
          child: _buildLeftPane(context, script),
        ),
        _ConsoleDivider(
          onDragStart: () => _handleLeftDragStart(layout),
          onDragUpdate: (details) => _handleLeftDragUpdate(details, layout),
          onDragEnd: () => _handleLeftDragEnd(),
        ),
        Expanded(
          child: _buildCenterPane(
            context,
            script,
            maximized: false,
            onToggleMaximize: _toggleLogMaximized,
            extraHeaderAction: layout.usesTwoPane
                ? _buildStatsButton(context)
                : null,
          ),
        ),
        if (layout.usesThreePane) ...[
          if (_statsExpanded && layout.canPushStats)
            _ConsoleDivider(
              onDragStart: () => _handleRightDragStart(layout),
              onDragUpdate: (details) =>
                  _handleRightDragUpdate(details, layout),
              onDragEnd: () => _handleRightDragEnd(),
            )
          else
            const SizedBox(width: 8),
          SizedBox(
            width: layout.rightWidth,
            child: _statsExpanded && layout.canPushStats
                ? _buildStatsPane(context, script)
                : _buildStatsRail(context),
          ),
        ],
      ],
    );
    if (!overlayOpen) {
      return row;
    }
    final colors = OasxColors.of(context);
    final overlayWidth = (layout.width * 0.55).clamp(300.0, 360.0);
    return Stack(
      children: [
        Positioned.fill(child: row),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _setStatsExpanded(false),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          width: overlayWidth,
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  _setStatsExpanded(false),
            },
            child: FocusTraversalGroup(
              child: Focus(
                autofocus: true,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(OasxRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow,
                        blurRadius: 24,
                        offset: const Offset(-8, 0),
                      ),
                    ],
                  ),
                  child: _buildStatsPane(context, script),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactBody(BuildContext context, ScriptModel? script) {
    return Column(
      children: [
        _ConsoleViewSwitch(
          value: _compactTab,
          onChanged: _selectCompactTab,
        ),
        const SizedBox(height: OasxSpace.sm),
        Expanded(
          // IndexedStack keeps the log panel (and its local search/filter
          // state) alive while the user moves between compact tabs.
          child: IndexedStack(
            index: _compactTab.index,
            children: [
              _buildCenterPane(
                context,
                script,
                maximized: false,
                onToggleMaximize: null,
              ),
              _buildLeftPane(context, script),
              _buildStatsPane(
                context,
                script,
                onCollapse: () =>
                    _selectCompactTab(_ConsoleCompactTab.log),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectCompactTab(_ConsoleCompactTab tab) {
    if (_compactTab == tab) {
      return;
    }
    setState(() {
      _compactTab = tab;
      _logMaximized = false;
    });
  }

  Widget _buildStatsButton(BuildContext context) {
    return IconButton(
      tooltip: I18n.homeStatsTab.tr,
      onPressed: () => _setStatsExpanded(true),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      icon: const Icon(Icons.insights_rounded, size: 18),
    );
  }

  Widget _buildStatsRail(BuildContext context) {
    return ConsoleStatsRail(onExpand: () => _setStatsExpanded(true));
  }

  Widget _buildStatsPane(
    BuildContext context,
    ScriptModel? script, {
    VoidCallback? onCollapse,
  }) {
    return ConsoleStatsPane(
      scriptName: script?.name ?? '',
      onCollapse: onCollapse ?? () => _setStatsExpanded(false),
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
    required VoidCallback? onToggleMaximize,
    Widget? extraHeaderAction,
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
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (extraHeaderAction != null) extraHeaderAction,
          ConsoleTaskAction(
            controller: widget.controller,
            script: script,
            onTogglePower: widget.onTogglePower,
            onRefreshScripts: widget.onRefreshScriptsTap,
          ),
        ],
      ),
    );
  }

  /// Expands or folds the statistics column.
  ///
  /// Visibility of the statistics transport is resolved from the active
  /// layout in [_syncStatsVisibility], so this only updates local UI state.
  void _setStatsExpanded(bool value) {
    if (_statsExpanded == value) {
      return;
    }
    setState(() {
      _statsExpanded = value;
    });
  }

  Widget _buildPanePlaceholder(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    return HomePaneCard(
      padding: EdgeInsets.zero,
      child: OasxEmptyState(
        icon: icon,
        message: message,
        compact: true,
      ),
    );
  }

  void _toggleLogMaximized() {
    setState(() {
      _logMaximized = !_logMaximized;
    });
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

/// Compact three-way switch shown when the console collapses to one pane.
class _ConsoleViewSwitch extends StatelessWidget {
  const _ConsoleViewSwitch({required this.value, required this.onChanged});

  final _ConsoleCompactTab value;
  final ValueChanged<_ConsoleCompactTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final switchHeight = 40 * scale;
    final items = <(_ConsoleCompactTab, String, IconData)>[
      (_ConsoleCompactTab.log, I18n.log.tr, Icons.terminal_rounded),
      (_ConsoleCompactTab.tasks, I18n.homeTasksTab.tr, Icons.task_alt_rounded),
      (_ConsoleCompactTab.stats, I18n.homeStatsTab.tr, Icons.insights_rounded),
    ];
    return Container(
      height: switchHeight,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceSunken,
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == item.$1,
                label: item.$2,
                excludeSemantics: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: value == item.$1
                        ? colors.accentSoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(OasxRadius.xs),
                    border: Border.all(
                      color: value == item.$1
                          ? colors.accent.withValues(alpha: 0.32)
                          : Colors.transparent,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => onChanged(item.$1),
                      borderRadius: BorderRadius.circular(OasxRadius.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.$3,
                            size: 15,
                            color: value == item.$1
                                ? colors.accent
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: value == item.$1
                                        ? colors.accent
                                        : colors.textSecondary,
                                    fontWeight: value == item.$1
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
