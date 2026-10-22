import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/task_catalog_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Opens the full task catalog and parameter editor for one config.
///
/// The console left column stays focused on the current task snapshot while
/// this dialog reuses the existing catalog for grouping, enable/disable and
/// JSON transfer operations.
Future<void> showTaskCatalogDialog(
  BuildContext context, {
  required HomeDashboardController controller,
  required ScriptModel script,
  required Future<void> Function(String taskName) onOpenTask,
  required Future<void> Function(String taskName) onQuickRun,
  required Future<void> Function(String taskName) onQuickWait,
}) async {
  controller.clearActiveTask();
  final media = MediaQuery.sizeOf(context);
  final width = media.width.clamp(420.0, 980.0);
  final height = media.height.clamp(440.0, 760.0);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final scheme = theme.colorScheme;
      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: scheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        child: SizedBox(
          width: width - 48,
          height: height - 48,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      I18n.taskManageTitle.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        script.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: I18n.cancel.tr,
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TaskCatalogPanel(
                    controller: controller,
                    scriptModel: script,
                    onOpenTask: onOpenTask,
                    onQuickRun: onQuickRun,
                    onQuickWait: onQuickWait,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  controller.clearActiveTask();
}
