import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/models/config_drag_payload.dart';
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
  });

  final HomeDashboardController controller;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;
  final VoidCallback onManageConfigsTap;
  final Future<void> Function(String scriptName) onSelectScript;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;

  @override
  State<ConfigSwitcherBar> createState() => _ConfigSwitcherBarState();
}

class _ConfigSwitcherBarState extends State<ConfigSwitcherBar> {
  static const double _barHeight = 58;
  static const double _chipWidthMax = 220;
  static const double _summaryMinWidth = 1320;

  final ScrollController _scrollController = ScrollController();
  final Set<String> _pendingToggles = <String>{};
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _lastSyncedAt = DateTime.now();
  }

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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: _barHeight,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showSummary = constraints.maxWidth >= _summaryMinWidth;
                return Row(
                  children: [
                    Icon(
                      Icons.dashboard_customize_outlined,
                      size: 17,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      I18n.scriptList.tr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildConfigList(context)),
                    if (showSummary) ...[
                      const SizedBox(width: 16),
                      _buildSummary(context),
                    ],
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
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
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
            const SizedBox(width: 8),
            _buildTrailingActions(context),
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
          // The trailing actions follow the last config so they move right as
          // configs are added instead of being pinned to the bar edge.
          itemCount: scripts.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == scripts.length) {
              return _buildTrailingActions(context);
            }
            return _buildConfigChip(context, scripts[index]);
          },
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
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: widget.loadingAddScript
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigChip(BuildContext context, ScriptModel script) {
    return DragTarget<ConfigDragPayload>(
      onWillAcceptWithDetails: (details) {
        return details.data.canDropOn(script.name) &&
            !widget.controller.isDragCopyPendingFor(script.name);
      },
      onAcceptWithDetails: (details) async {
        widget.controller.clearConfigDrag();
        await widget.controller.acceptConfigDrag(
          payload: details.data,
          destinationConfig: script.name,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        return Obx(() {
          final scheme = Theme.of(context).colorScheme;
          final isSelected =
              widget.controller.activeScriptName.value == script.name;
          final state = widget.controller.scriptStateFor(script);
          final stateColor = state.color(context);
          final dragCopyLoading = widget.controller.isDragCopyPendingFor(
            script.name,
          );
          final togglePending = _pendingToggles.contains(script.name);
          final isRunning = script.state.value == ScriptState.running;
          return ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _ConfigSwitcherBarState._chipWidthMax,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primaryContainer.withValues(alpha: 0.45)
                    : scheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDropTarget
                      ? scheme.primary
                      : isSelected
                      ? scheme.primary.withValues(alpha: 0.45)
                      : scheme.outlineVariant.withValues(alpha: 0.75),
                  width: isDropTarget ? 1.5 : 1,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: dragCopyLoading || togglePending
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
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? scheme.primary
                                      : scheme.onSurface,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: dragCopyLoading || togglePending
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
                                  tooltip: isRunning
                                      ? I18n.stop.tr
                                      : I18n.run.tr,
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
      },
    );
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
