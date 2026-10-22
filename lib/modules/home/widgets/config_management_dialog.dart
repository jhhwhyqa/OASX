import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/config_collection_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Opens the full config management surface.
///
/// The existing collection panel is reused so search, filtering, ordering,
/// linking, drag-copy targets and destructive actions keep one implementation.
Future<void> showConfigManagementDialog(
  BuildContext context, {
  required HomeDashboardController controller,
  required bool loadingAddScript,
  required bool refreshingScripts,
  required VoidCallback onAddScriptTap,
  required VoidCallback onRefreshScriptsTap,
  required Future<void> Function(String scriptName) onActivateScript,
  required Future<void> Function(String scriptName, bool enable) onTogglePower,
  required Future<void> Function(String scriptName) onRenameScript,
  required Future<void> Function(String scriptName) onExportScript,
  required Future<void> Function(String scriptName) onDeleteScript,
}) {
  final media = MediaQuery.sizeOf(context);
  final width = media.width.clamp(360.0, 860.0);
  final height = media.height.clamp(420.0, 700.0);
  return showDialog<void>(
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
                      Icons.tune_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      I18n.homeConsoleManageConfigs.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
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
                  child: ConfigCollectionPanel(
                    controller: controller,
                    fillHeight: true,
                    loadingAddScript: loadingAddScript,
                    refreshingScripts: refreshingScripts,
                    onAddScriptTap: onAddScriptTap,
                    onRefreshScriptsTap: onRefreshScriptsTap,
                    onActivateScript: (scriptName) async {
                      await onActivateScript(scriptName);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    onTogglePower: onTogglePower,
                    onRenameScript: onRenameScript,
                    onExportScript: onExportScript,
                    onDeleteScript: onDeleteScript,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
