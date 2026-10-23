import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/script_state_presentation.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Persistent horizontal config switcher for the desktop console.
class ConfigSwitcherBar extends StatefulWidget {
  const ConfigSwitcherBar({
    super.key,
    required this.controller,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
    required this.onManageConfigsTap,
    required this.onSelectScript,
    required this.onTogglePower,
    this.compact = false,
  });

  final HomeDashboardController controller;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;
  final VoidCallback onManageConfigsTap;
  final Future<void> Function(String scriptName) onSelectScript;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;

  /// Renders a single script selector instead of the chip row.
  final bool compact;

  @override
  State<ConfigSwitcherBar> createState() => _ConfigSwitcherBarState();
}

class _ConfigSwitcherBarState extends State<ConfigSwitcherBar> {
  static const double _barHeight = 56;
  static const double _chipWidthMax = 220;
  static const double _summaryMinWidth = 1240;

  final ScrollController _scrollController = ScrollController();
  final Set<String> _pendingToggles = <String>{};
  DateTime? _lastSyncedAt;

  @override
  void didUpdateWidget(covariant ConfigSwitcherBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final refreshFinished =
        oldWidget.refreshingScripts && !widget.refreshingScripts;
    if (refreshFinished && !widget.controller.isStartupConnectionFailed.value) {
      _lastSyncedAt = DateTime.now();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactBar(context);
    }
    final colors = OasxColors.of(context);
    return SizedBox(
      height: _barHeight,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(OasxRadius.md),
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: OasxSpace.md),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showSummary = constraints.maxWidth >= _summaryMinWidth;
                  return Row(
                    children: [
                      Icon(
                        Icons.dashboard_customize_outlined,
                        size: 16,
                        color: colors.accent,
                      ),
                      const SizedBox(width: OasxSpace.sm),
                      OasxMicroLabel(I18n.scriptList.tr),
                      const SizedBox(width: OasxSpace.md),
                      Expanded(child: _buildConfigList(context)),
                      if (showSummary) ...[
                        const SizedBox(width: OasxSpace.lg),
                        _buildSummary(context),
                      ],
                      const SizedBox(width: OasxSpace.sm),
                      _buildTrailingActions(context),
                    ],
                  );
                },
              ),
            ),
            if (widget.refreshingScripts)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: colors.surfaceSunken,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Compact selector used by the single-pane console.
  Widget _buildCompactBar(BuildContext context) {
    final colors = OasxColors.of(context);
    return SizedBox(
      height: _barHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(OasxRadius.md),
              border: Border.all(color: colors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: OasxSpace.sm),
            child: Obx(() {
              final script = widget.controller.activeScriptModel;
              final state = script == null
                  ? null
                  : widget.controller.scriptStateFor(script);
              final stateColor = state?.color(context) ?? colors.textTertiary;
              final isRunning = script?.state.value == ScriptState.running;
              return Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: I18n.scriptList.tr,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(OasxRadius.xs),
                          onTap: () => _showScriptSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OasxSpace.xs,
                              vertical: OasxSpace.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: stateColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: OasxSpace.sm),
                                Flexible(
                                  child: Text(
                                    script?.name ??
                                        I18n.homeNoScriptSelected.tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                const SizedBox(width: OasxSpace.xxs),
                                Icon(
                                  Icons.expand_more_rounded,
                                  size: 18,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (script != null)
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        tooltip: isRunning ? I18n.stop.tr : I18n.run.tr,
                        onPressed: () => _togglePower(script),
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        style: IconButton.styleFrom(
                          foregroundColor: isRunning
                              ? stateColor
                              : colors.textSecondary,
                        ),
                        icon: const Icon(Icons.power_settings_new_rounded),
                      ),
                    ),
                  _buildConnectionIndicator(context),
                  _buildActionButton(
                    tooltip: I18n.homeConnectionRetryAction.tr,
                    icon: Icons.refresh_rounded,
                    loading: widget.refreshingScripts,
                    onPressed: widget.refreshingScripts
                        ? null
                        : widget.onRefreshScriptsTap,
                  ),
                  _buildActionButton(
                    tooltip: I18n.homeConsoleManageConfigs.tr,
                    icon: Icons.tune_rounded,
                    onPressed: widget.onManageConfigsTap,
                  ),
                  IconButton.filledTonal(
                    tooltip: I18n.configAdd.tr,
                    onPressed: widget.loadingAddScript
                        ? null
                        : widget.onAddScriptTap,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: colors.accentSoft,
                      foregroundColor: colors.accent,
                    ),
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 32,
                    ),
                    icon: widget.loadingAddScript
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_rounded, size: 19),
                  ),
                ],
              );
            }),
          ),
          if (widget.refreshingScripts)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: colors.surfaceSunken,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showScriptSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.62,
          child: _buildScriptSheet(sheetContext),
        ),
      ),
    );
  }

  Widget _buildScriptSheet(BuildContext sheetContext) {
    return Obx(() {
      final scripts = widget.controller.orderedScripts;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OasxSpace.lg,
              OasxSpace.xs,
              OasxSpace.sm,
              OasxSpace.sm,
            ),
            child: Row(
              children: [
                OasxMicroLabel(I18n.scriptList.tr),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    widget.onManageConfigsTap();
                  },
                  child: Text(I18n.homeConsoleManageConfigs.tr),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: scripts.isEmpty
                ? Center(
                    child: Text(
                      I18n.homeEmptyScriptHint.tr,
                      style: Theme.of(sheetContext).textTheme.bodySmall,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OasxSpace.sm,
                      vertical: OasxSpace.sm,
                    ),
                    itemCount: scripts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: OasxSpace.xxs),
                    itemBuilder: (context, index) {
                      final script = scripts[index];
                      final state = widget.controller.scriptStateFor(script);
                      final isSelected =
                          widget.controller.activeScriptName.value ==
                          script.name;
                      final isRunning =
                          script.state.value == ScriptState.running;
                      return Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(OasxRadius.sm),
                          onTap: () async {
                            Navigator.pop(sheetContext);
                            await widget.onSelectScript(script.name);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OasxSpace.sm,
                              vertical: OasxSpace.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? OasxColors.of(context).accentSoft
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                OasxRadius.sm,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: state.color(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: OasxSpace.md),
                                Expanded(
                                  child: Text(
                                    script.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: OasxSpace.sm),
                                OasxStatusPill(
                                  label: state.filterLabel,
                                  color: state.color(context),
                                  dense: true,
                                ),
                                const SizedBox(width: OasxSpace.xs),
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: IconButton(
                                    tooltip: isRunning
                                        ? I18n.stop.tr
                                        : I18n.run.tr,
                                    onPressed: () => _togglePower(script),
                                    padding: EdgeInsets.zero,
                                    iconSize: 19,
                                    style: IconButton.styleFrom(
                                      foregroundColor: isRunning
                                          ? state.color(context)
                                          : OasxColors.of(context).textSecondary,
                                      backgroundColor: isRunning
                                          ? state
                                                .color(context)
                                                .withValues(alpha: 0.10)
                                          : null,
                                    ),
                                    icon: const Icon(
                                      Icons.power_settings_new_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }

  /// Builds the right-aligned config overview.
  ///
  /// Only shown on wide windows so the chip row keeps the space it needs on
  /// narrow layouts.
  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = OasxStateColors.of(context);
    return Obx(() {
      final scripts = widget.controller.orderedScripts;
      if (scripts.isEmpty) {
        return const SizedBox.shrink();
      }
      var running = 0;
      var abnormal = 0;
      for (final script in scripts) {
        switch (script.state.value) {
          case ScriptState.running:
            running += 1;
          case ScriptState.warning:
            abnormal += 1;
          case ScriptState.inactive:
          case ScriptState.updating:
            break;
        }
      }
      final style = theme.textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      );
      final items = <Widget>[
        Text(
          I18n.homeConfigSummaryTotal.trParams({'count': '${scripts.length}'}),
          style: style,
        ),
      ];
      if (running > 0) {
        items.addAll([
          _summarySeparator(scheme),
          _summaryDot(colors.running),
          const SizedBox(width: 4),
          Text(
            I18n.homeConfigSummaryRunning.trParams({'count': '$running'}),
            style: style?.copyWith(color: colors.running),
          ),
        ]);
      }
      if (abnormal > 0) {
        items.addAll([
          _summarySeparator(scheme),
          _summaryDot(colors.abnormal),
          const SizedBox(width: 4),
          Text(
            I18n.homeConfigSummaryAbnormal.trParams({'count': '$abnormal'}),
            style: style?.copyWith(color: colors.abnormal),
          ),
        ]);
      }
      final syncedAt = _lastSyncedAt;
      if (syncedAt != null) {
        items.addAll([
          _summarySeparator(scheme),
          Text(
            I18n.homeConfigSummarySynced.trParams({
              'time': _formatSyncTime(syncedAt),
            }),
            style: style,
          ),
        ]);
      }
      return Row(
        key: const ValueKey<String>('config-summary'),
        mainAxisSize: MainAxisSize.min,
        children: items,
      );
    });
  }

  Widget _summarySeparator(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text('·', style: TextStyle(color: scheme.outline)),
    );
  }

  Widget _summaryDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _formatSyncTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildConfigList(BuildContext context) {
    return Obx(() {
      final scripts = widget.controller.orderedScripts;
      if (scripts.isEmpty) {
        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  I18n.homeEmptyScriptHint.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        );
      }
      return Scrollbar(
        controller: _scrollController,
        thumbVisibility: false,
        thickness: 3,
        radius: const Radius.circular(999),
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: scripts.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) =>
              _buildConfigChip(context, scripts[index]),
        ),
      );
    });
  }

  /// Builds the connection indicator and config actions after the last chip.
  Widget _buildTrailingActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildConnectionIndicator(context),
          _buildActionButton(
            tooltip: I18n.homeConnectionRetryAction.tr,
            icon: Icons.refresh_rounded,
            loading: widget.refreshingScripts,
            onPressed: widget.refreshingScripts
                ? null
                : widget.onRefreshScriptsTap,
          ),
          _buildActionButton(
            tooltip: I18n.homeConsoleManageConfigs.tr,
            icon: Icons.tune_rounded,
            onPressed: widget.onManageConfigsTap,
          ),
          const SizedBox(width: 2),
          IconButton.filledTonal(
            tooltip: I18n.configAdd.tr,
            onPressed: widget.loadingAddScript ? null : widget.onAddScriptTap,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              backgroundColor: OasxColors.of(context).accentSoft,
              foregroundColor: OasxColors.of(context).accent,
            ),
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            icon: widget.loadingAddScript
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigChip(BuildContext context, ScriptModel script) {
    return Obx(() {
      final scheme = Theme.of(context).colorScheme;
      final colors = OasxColors.of(context);
      final isSelected =
          widget.controller.activeScriptName.value == script.name;
      final state = widget.controller.scriptStateFor(script);
      final stateColor = state.color(context);
      final togglePending = _pendingToggles.contains(script.name);
      final isRunning = script.state.value == ScriptState.running;
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: _ConfigSwitcherBarState._chipWidthMax,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isSelected ? scheme.primaryContainer : colors.surfaceSunken,
            borderRadius: BorderRadius.circular(OasxRadius.sm),
            border: Border.all(
              color: isSelected
                  ? scheme.primary.withValues(alpha: 0.45)
                  : colors.border,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(OasxRadius.sm),
              onTap: togglePending
                  ? null
                  : () => widget.onSelectScript(script.name),
              hoverColor: scheme.onSurface.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: state.filterLabel,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: stateColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        script.name,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? scheme.primary : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: togglePending
                          ? const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              tooltip: isRunning ? I18n.stop.tr : I18n.run.tr,
                              onPressed: () => _togglePower(script),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              iconSize: 18,
                              style: IconButton.styleFrom(
                                foregroundColor: isRunning
                                    ? stateColor
                                    : scheme.onSurfaceVariant,
                                backgroundColor: isRunning
                                    ? stateColor.withValues(alpha: 0.10)
                                    : null,
                              ),
                              icon: const Icon(
                                Icons.power_settings_new_rounded,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
      ),
      icon: loading
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 19),
    );
  }

  Widget _buildConnectionIndicator(BuildContext context) {
    return Obx(() {
      if (!widget.controller.isStartupConnectionFailed.value) {
        return const SizedBox.shrink();
      }
      final scheme = Theme.of(context).colorScheme;
      return Tooltip(
        message: I18n.homeConnectionRetryHint.tr,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.cloud_off_rounded, size: 17, color: scheme.error),
        ),
      );
    });
  }

  Future<void> _togglePower(ScriptModel script) async {
    if (_pendingToggles.contains(script.name)) {
      return;
    }
    setState(() {
      _pendingToggles.add(script.name);
    });
    try {
      await widget.onTogglePower(
        script.name,
        script.state.value != ScriptState.running,
      );
    } catch (error) {
      Get.snackbar(I18n.error.tr, '$error');
    } finally {
      if (mounted) {
        setState(() {
          _pendingToggles.remove(script.name);
        });
      }
    }
  }
}
