part of 'task_status_row.dart';

class _TaskMeta extends StatelessWidget {
  const _TaskMeta({
    required this.task,
    required this.onSetNextRun,
  });

  final TaskStatusViewData task;
  final Future<void> Function(String taskName, String nextRun) onSetNextRun;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = Text(
      task.name.tr,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        title,
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
    this.compact = false,
  });

  final VoidCallback? onQuickRun;
  final VoidCallback? onQuickWait;
  final VoidCallback? onEditTask;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return PopupMenuButton<String>(
        tooltip: I18n.taskManageTitle.tr,
        icon: const Icon(Icons.more_horiz_rounded, size: 20),
        onSelected: (value) {
          switch (value) {
            case 'run':
              onQuickRun?.call();
              break;
            case 'wait':
              onQuickWait?.call();
              break;
            case 'edit':
              onEditTask?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'run',
            enabled: onQuickRun != null,
            child: _TaskMenuItem(
              icon: Icons.flash_on_rounded,
              label: I18n.homeQuickRun.tr,
            ),
          ),
          PopupMenuItem(
            value: 'wait',
            enabled: onQuickWait != null,
            child: _TaskMenuItem(
              icon: Icons.schedule_rounded,
              label: I18n.homeQuickWait.tr,
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            enabled: onEditTask != null,
            child: _TaskMenuItem(
              icon: Icons.tune_rounded,
              label: I18n.homeOpenTaskParams.tr,
            ),
          ),
        ],
      );
    }
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

class _TaskMenuItem extends StatelessWidget {
  const _TaskMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 17, color: colors.textSecondary),
        const SizedBox(width: OasxSpace.sm),
        Text(label),
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
