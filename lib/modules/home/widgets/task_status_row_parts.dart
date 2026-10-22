part of 'task_status_row.dart';

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.controller,
    required this.sourceScriptName,
    required this.task,
    required this.onSetNextRun,
    required this.dragEnabled,
  });

  final HomeDashboardController controller;
  final String sourceScriptName;
  final TaskStatusViewData task;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;
  final bool dragEnabled;

  @override
  Widget build(BuildContext context) {
    final payload = controller.buildTaskDragPayload(
      sourceConfig: sourceScriptName,
      taskName: task.name,
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = Text(
      task.name.tr,
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        dragEnabled
            ? Draggable<ConfigDragPayload>(
                data: payload,
                feedback: DragCopyFeedback(label: payload.displayLabel),
                onDragStarted: () => controller.startConfigDrag(payload),
                onDragCompleted: controller.clearConfigDrag,
                onDraggableCanceled: (_, __) => controller.clearConfigDrag(),
                onDragEnd: (_) => controller.clearConfigDrag(),
                child: title,
              )
            : title,
        if (task.timeText.isNotEmpty) ...[
          const SizedBox(height: 2),
          DateTimePicker(
            value: task.timeText,
            notHoverStyle: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            hoverStyle: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
            ),
            onChange: (value) => unawaited(onSetNextRun(task.name, value)),
          ),
        ],
      ],
    );
  }
}

class _TaskTypeIcon extends StatelessWidget {
  const _TaskTypeIcon({required this.type});

  final TaskStatusType type;

  @override
  Widget build(BuildContext context) {
    final colors = OasxStateColors.of(context);
    final (icon, color) = switch (type) {
      TaskStatusType.running => (Icons.bolt_rounded, colors.running),
      TaskStatusType.pending => (Icons.layers_rounded, colors.pending),
      TaskStatusType.waiting => (Icons.schedule_rounded, colors.waiting),
    };
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _TaskActionBar extends StatelessWidget {
  const _TaskActionBar({
    required this.onQuickRun,
    required this.onQuickWait,
    required this.onEditTask,
  });

  final VoidCallback? onQuickRun;
  final VoidCallback? onQuickWait;
  final VoidCallback? onEditTask;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TaskActionIcon(
          icon: Icons.flash_on_rounded,
          tooltip: I18n.homeQuickRun.tr,
          onPressed: onQuickRun,
        ),
        _TaskActionIcon(
          icon: Icons.schedule_rounded,
          tooltip: I18n.homeQuickWait.tr,
          onPressed: onQuickWait,
        ),
        _TaskActionIcon(
          icon: Icons.tune_rounded,
          tooltip: I18n.homeOpenTaskParams.tr,
          onPressed: onEditTask,
        ),
      ],
    );
  }
}

class _TaskActionIcon extends StatelessWidget {
  const _TaskActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      iconSize: 19,
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}
