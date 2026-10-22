import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/config_collection_script_label.dart';
import 'package:oasx/modules/home/widgets/config_collection_task_preview.dart';
import 'package:oasx/modules/home/widgets/config_state_indicator.dart';
import 'package:oasx/modules/home/widgets/script_state_presentation.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionTile extends StatelessWidget {
  const ConfigCollectionTile({
    super.key,
    required this.controller,
    required this.script,
    required this.onTap,
    required this.onTogglePower,
    required this.onRename,
    required this.onExport,
    required this.onDelete,
    this.dragHandle,
  });

  static const _actionSpacing = 6.0;
  static const _compactLayoutThreshold = 200.0;
  final HomeDashboardController controller;
  final ScriptModel script;
  final VoidCallback onTap;
  final VoidCallback onTogglePower;
  final VoidCallback onRename;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  /// Optional reorder handle rendered before the config content.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final isActive = controller.activeScriptName.value == script.name;
          final showLinkCheckbox = controller.isLinkModeEnabled.value;
          final isLinked = controller.isScriptLinked(script.name);
          final isDragCopyLoading = controller.isDragCopyPendingFor(
            script.name,
          );
          final state = controller.scriptCollectionStateFor(script);
          final compactThreshold =
              ConfigCollectionTile._compactLayoutThreshold +
              (showLinkCheckbox ? 64 : 0) +
              (dragHandle != null ? 28 : 0);
          final isCompact = constraints.maxWidth < compactThreshold;
          final rowColor = isActive
              ? scheme.primaryContainer.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.32 : 0.40,
                )
              : Colors.transparent;
          return Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                color: rowColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? scheme.primary.withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: isDragCopyLoading ? null : onTap,
                hoverColor: scheme.onSurface.withValues(alpha: 0.04),
                focusColor: scheme.primary.withValues(alpha: 0.08),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: isCompact ? 8 : 9,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (dragHandle != null)
                        SizedBox(
                          width: 24,
                          height: 36,
                          child: Center(child: dragHandle),
                        ),
                      if (showLinkCheckbox) ...[
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: Checkbox(
                            value: isLinked,
                            onChanged: (value) => controller.setScriptLinked(
                              script.name,
                              value ?? false,
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                            side: BorderSide(color: scheme.outline),
                          ),
                        ),
                        const SizedBox(width: 2),
                      ],
                      Expanded(
                        child: Stack(
                          children: [
                            AbsorbPointer(
                              absorbing: isDragCopyLoading,
                              child: _ScriptMeta(
                                script: script,
                                state: state,
                                isActive: isActive,
                                compact: isCompact,
                                powerButton: _PowerButton(
                                  isRunning:
                                      script.state.value == ScriptState.running,
                                  stateColor: state.color(context),
                                  onTogglePower: onTogglePower,
                                ),
                                popupButton: _ActionMenuButton(
                                  onRename: onRename,
                                  onExport: onExport,
                                  onDelete: onDelete,
                                ),
                              ),
                            ),
                            if (isDragCopyLoading)
                              const Positioned.fill(
                                child: _DragCopyLoadingMask(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

class _ScriptMeta extends StatelessWidget {
  const _ScriptMeta({
    required this.script,
    required this.state,
    required this.isActive,
    required this.compact,
    required this.powerButton,
    required this.popupButton,
  });

  final ScriptModel script;
  final HomeScriptStateFilter state;
  final bool isActive;
  final bool compact;
  final Widget powerButton;
  final Widget popupButton;

  @override
  Widget build(BuildContext context) {
    final color = state.color(context);
    if (compact) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _StatusAccentBar(color: color),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 2,
                    children: [powerButton, popupButton],
                  ),
                  const SizedBox(height: 2),
                  ConfigCollectionScriptLabel(
                    script: script,
                    centered: true,
                    selected: isActive,
                  ),
                  if (state.statusLabel != null) ...[
                    const SizedBox(height: 4),
                    Tooltip(
                      message: state.filterLabel,
                      child: ConfigStateIndicator(state: state, size: 8),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StatusAccentBar(color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConfigCollectionScriptLabel(
                      script: script,
                      centered: false,
                      selected: isActive,
                    ),
                    if (state.statusLabel != null)
                      ScriptStateBadge(state: state),
                  ],
                ),
                const SizedBox(height: 5),
                ConfigCollectionTaskPreview(script: script),
              ],
            ),
          ),
          const SizedBox(width: ConfigCollectionTile._actionSpacing),
          powerButton,
          popupButton,
        ],
      ),
    );
  }
}

class _DragCopyLoadingMask extends StatelessWidget {
  const _DragCopyLoadingMask();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.68),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    );
  }
}

class _StatusAccentBar extends StatelessWidget {
  const _StatusAccentBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 3,
      height: double.infinity,
      child: Center(
        child: FractionallySizedBox(
          heightFactor: 0.72,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.isRunning,
    required this.stateColor,
    required this.onTogglePower,
  });

  final bool isRunning;
  final Color stateColor;
  final VoidCallback onTogglePower;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: isRunning ? I18n.stop.tr : I18n.run.tr,
      onPressed: onTogglePower,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
      iconSize: 20,
      style: IconButton.styleFrom(
        foregroundColor: isRunning ? stateColor : scheme.onSurfaceVariant,
        backgroundColor: isRunning ? stateColor.withValues(alpha: 0.10) : null,
      ),
      icon: const Icon(Icons.power_settings_new_rounded),
    );
  }
}

class _ActionMenuButton extends StatelessWidget {
  const _ActionMenuButton({
    required this.onRename,
    required this.onExport,
    required this.onDelete,
  });

  final VoidCallback onRename;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 32,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        tooltip: I18n.homeScriptActions.tr,
        icon: Icon(
          Icons.more_vert_rounded,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        onSelected: (value) async {
          if (value == 'rename') {
            onRename();
            return;
          }
          if (value == 'export') {
            onExport();
            return;
          }
          onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'rename',
            child: _ActionMenuItem(
              icon: Icons.edit_outlined,
              label: I18n.rename.tr,
            ),
          ),
          PopupMenuItem(
            value: 'export',
            child: _ActionMenuItem(
              icon: Icons.ios_share_rounded,
              label: I18n.configExport.tr,
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: _ActionMenuItem(
              icon: Icons.delete_outline_rounded,
              label: I18n.delete.tr,
              color: scheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionMenuItem extends StatelessWidget {
  const _ActionMenuItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    );
  }
}
