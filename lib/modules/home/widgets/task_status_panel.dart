import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_status_row.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Renders the overview task list for the active config workbench.
class TaskStatusPanel extends StatefulWidget {
  const TaskStatusPanel({
    super.key,
    required this.controller,
    required this.scriptModel,
    required this.canQuickScheduleTask,
    required this.onSetNextRun,
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final HomeDashboardController controller;
  final ScriptModel scriptModel;
  final bool Function(String taskName) canQuickScheduleTask;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final Future<void> Function(String taskName) onQuickRun;
  final Future<void> Function(String taskName) onQuickWait;
  final Future<void> Function(String taskName) onEditTask;

  @override
  State<TaskStatusPanel> createState() => _TaskStatusPanelState();
}

class _TaskStatusPanelState extends State<TaskStatusPanel> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _hiddenTaskIds = <String>{};
  String _searchQuery = '';

  @override
  void didUpdateWidget(covariant TaskStatusPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptModel.name == widget.scriptModel.name) {
      return;
    }
    _clearSearchState();
    _scrollTaskListToTop();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final dragPayload = widget.controller.activeDragPayload.value;
      final quickScheduleLocked = widget.controller.isBulkQuickScheduling;
      final rawTasks = _collectTasks(widget.scriptModel);
      _pruneHiddenTaskIds(rawTasks);
      final visibleTasks = rawTasks
          .where((task) => !_hiddenTaskIds.contains(task.rowId))
          .where(_matchesTaskQuery)
          .toList();
      return Column(
        children: [
          _buildSearchField(context),
          const SizedBox(height: 8),
          Expanded(
            child: visibleTasks.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    key: const PageStorageKey<String>('home-task-status-list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 2),
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return TaskStatusRow(
                        key: ValueKey(task.rowId),
                        controller: widget.controller,
                        sourceScriptName: widget.scriptModel.name,
                        task: task,
                        canQuickSchedule: widget.canQuickScheduleTask(
                          task.name,
                        ),
                        quickScheduleLocked: quickScheduleLocked,
                        onSetNextRun: widget.onSetNextRun,
                        onQuickRun: widget.onQuickRun,
                        onQuickWait: widget.onQuickWait,
                        onEditTask: widget.onEditTask,
                        onDisableTask: _disableTask,
                        onDismissed: _markTaskHidden,
                        dragEnabled: widget.controller.canUseDesktopDragCopy,
                        swipeEnabled: !_isSwipeDisabled(task),
                        activeDragPayload: dragPayload,
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  /// Builds the local overview search field above the task list.
  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderSide = BorderSide(color: scheme.outlineVariant);
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() {
        _searchQuery = value.trim().toLowerCase();
      }),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        hintText: I18n.taskSearchHint.tr,
        hintStyle: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 17,
          color: scheme.onSurfaceVariant,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: I18n.clear.tr,
                onPressed: _clearSearch,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close_rounded, size: 15),
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 28,
          minHeight: 28,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: scheme.primary.withValues(alpha: 0.8),
            width: 1.3,
          ),
        ),
      ),
    );
  }

  /// Clears the local task search.
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  /// Returns the placeholder message for the current filtered view.
  String get _emptyMessage {
    return _searchQuery.isEmpty ? I18n.homeNoTask.tr : I18n.taskNotFound.tr;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isEmpty
                  ? Icons.inbox_outlined
                  : Icons.search_off_rounded,
              size: 24,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              _emptyMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Collects the current overview task snapshot from the active script model.
  List<TaskStatusViewData> _collectTasks(ScriptModel model) {
    final tasks = <TaskStatusViewData>[];
    final runningName = model.runningTask.value.taskName.value.trim();
    if (runningName.isNotEmpty) {
      tasks.add(
        TaskStatusViewData(
          rowId: 'running::$runningName',
          name: runningName,
          type: TaskStatusType.running,
        ),
      );
    }
    for (final entry in model.pendingTaskList.indexed) {
      final name = entry.$2.taskName.value.trim();
      if (name.isEmpty) {
        continue;
      }
      final timeText = entry.$2.nextRun.value.trim();
      tasks.add(
        TaskStatusViewData(
          rowId: 'pending::${entry.$1}::$name::$timeText',
          name: name,
          type: TaskStatusType.pending,
          timeText: timeText,
        ),
      );
    }
    for (final entry in model.waitingTaskList.indexed) {
      final name = entry.$2.taskName.value.trim();
      if (name.isEmpty) {
        continue;
      }
      final timeText = entry.$2.nextRun.value.trim();
      tasks.add(
        TaskStatusViewData(
          rowId: 'waiting::${entry.$1}::$name::$timeText',
          name: name,
          type: TaskStatusType.waiting,
          timeText: timeText,
        ),
      );
    }
    return tasks;
  }

  /// Returns whether one overview task matches the local search query.
  bool _matchesTaskQuery(TaskStatusViewData task) {
    if (_searchQuery.isEmpty) {
      return true;
    }
    final localized = task.name.tr.toLowerCase();
    final original = task.name.toLowerCase();
    return localized.contains(_searchQuery) || original.contains(_searchQuery);
  }

  /// Requests disabling one overview task across the current linker scope.
  Future<bool> _disableTask(String taskName) {
    return widget.controller.toggleTaskEnabled(
      scriptName: widget.scriptModel.name,
      taskName: taskName,
      enable: false,
    );
  }

  /// Returns whether the overview row must reject left-swipe interaction.
  bool _isSwipeDisabled(TaskStatusViewData task) {
    return widget.scriptModel.state.value == ScriptState.running &&
        task.type == TaskStatusType.running;
  }

  /// Records one task that already finished its left-slide removal animation.
  void _markTaskHidden(String rowId) {
    setState(() {
      _hiddenTaskIds.add(rowId);
    });
  }

  /// Clears local search and hidden-row state when the active config changes.
  void _clearSearchState() {
    _hiddenTaskIds.clear();
    _searchController.clear();
    _searchQuery = '';
  }

  void _scrollTaskListToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
  }

  /// Releases optimistic hidden rows once the backend snapshot no longer emits them.
  void _pruneHiddenTaskIds(List<TaskStatusViewData> tasks) {
    final activeIds = tasks.map((task) => task.rowId).toSet();
    final staleIds = _hiddenTaskIds
        .where((rowId) => !activeIds.contains(rowId))
        .toList();
    if (staleIds.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || staleIds.isEmpty) {
        return;
      }
      setState(() {
        _hiddenTaskIds.removeAll(staleIds);
      });
    });
  }
}
