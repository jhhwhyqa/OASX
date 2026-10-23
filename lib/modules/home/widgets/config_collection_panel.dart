import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/widgets/config_collection_tile.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/script_state_presentation.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigCollectionPanel extends StatefulWidget {
  static const _compactHeaderThreshold = 220.0;
  static const _compactFilterThreshold = 150.0;
  static const _visibleStateFilters = [
    HomeScriptStateFilter.all,
    HomeScriptStateFilter.running,
    HomeScriptStateFilter.stopped,
    HomeScriptStateFilter.abnormal,
  ];

  const ConfigCollectionPanel({
    super.key,
    required this.controller,
    required this.fillHeight,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
    required this.onActivateScript,
    required this.onTogglePower,
    required this.onRenameScript,
    required this.onExportScript,
    required this.onDeleteScript,
  });

  final HomeDashboardController controller;
  final bool fillHeight;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;
  final Future<void> Function(String scriptName) onActivateScript;
  final Future<void> Function(String scriptName, bool enable) onTogglePower;
  final Future<void> Function(String scriptName) onRenameScript;
  final Future<void> Function(String scriptName) onExportScript;
  final Future<void> Function(String scriptName) onDeleteScript;

  @override
  State<ConfigCollectionPanel> createState() => _ConfigCollectionPanelState();
}

class _ConfigCollectionPanelState extends State<ConfigCollectionPanel> {
  /// Tracks whether the compact filter row should show the search field.
  bool _showCompactSearch = false;

  /// Controller reused when the compact search field is visible.
  late final TextEditingController _searchController;
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchQuery.value,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomePaneCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Obx(() {
        final scripts = widget.controller.visibleScripts;
        final hasConfigs = widget.controller.orderedScripts.isNotEmpty;
        final searchValue = widget.controller.searchQuery.value;
        if (_searchController.text != searchValue) {
          _searchController.value = TextEditingValue(
            text: searchValue,
            selection: TextSelection.collapsed(offset: searchValue.length),
          );
        }
        final listView = SizedBox.expand(
          child: ReorderableListView.builder(
            scrollController: _listScrollController,
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(vertical: 2),
            itemCount: scripts.length,
            // ignore: deprecated_member_use
            onReorder: widget.controller.reorderVisibleScripts,
            itemBuilder: (context, index) {
              final script = scripts[index];
              return Column(
                key: ValueKey<String>('config-item-${script.name}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTile(context, script, index),
                  if (index < scripts.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 14,
                      endIndent: 8,
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                ],
              );
            },
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildRefreshProgress(context),
            const SizedBox(height: 8),
            _buildFilters(context),
            const SizedBox(height: 8),
            ExpandedOrSizedBox(
              fillHeight: widget.fillHeight,
              child: scripts.isEmpty
                  ? _buildEmptyState(context, hasConfigs: hasConfigs)
                  : listView,
            ),
          ],
        );
      }),
    );
  }

  /// Builds one reorderable config row.
  Widget _buildTile(BuildContext context, ScriptModel script, int index) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ConfigCollectionTile(
        controller: widget.controller,
        script: script,
        dragHandle: Tooltip(
          message: I18n.homeScriptReorder.tr,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: scheme.outline,
              ),
            ),
          ),
        ),
        onTap: () => widget.onActivateScript(script.name),
        onTogglePower: () => widget.onTogglePower(
          script.name,
          script.state.value != ScriptState.running,
        ),
        onRename: () => widget.onRenameScript(script.name),
        onExport: () => widget.onExportScript(script.name),
        onDelete: () => widget.onDeleteScript(script.name),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeader =
            constraints.maxWidth <
            ConfigCollectionPanel._compactHeaderThreshold;
        final title = _HeaderTitle(
          controller: widget.controller,
          centered: compactHeader,
        );
        final actions = _HeaderActions(
          controller: widget.controller,
          refreshingScripts: widget.refreshingScripts,
          loadingAddScript: widget.loadingAddScript,
          onRefreshScriptsTap: widget.onRefreshScriptsTap,
          onAddScriptTap: widget.onAddScriptTap,
          centered: compactHeader,
        );
        if (!compactHeader) {
          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 8),
              actions,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(child: title),
            const SizedBox(height: 6),
            Center(child: actions),
          ],
        );
      },
    );
  }

  /// Shows a slim progress line while the config list is refreshing.
  Widget _buildRefreshProgress(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 2,
      child: widget.refreshingScripts
          ? ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            )
          : null,
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filter = widget.controller.stateFilter.value;
    final isFiltered = filter != HomeScriptStateFilter.all;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactFilters =
            constraints.maxWidth <
            ConfigCollectionPanel._compactFilterThreshold;
        final filterButton = _FilterButton(
          filter: filter,
          isFiltered: isFiltered,
          expandLabel: !compactFilters,
          onSelected: widget.controller.setStateFilterValue,
        );
        if (!compactFilters) {
          _showCompactSearch = false;
          return Row(
            children: [
              Expanded(
                child: _SearchField(
                  controller: _searchController,
                  onChanged: widget.controller.setSearchQuery,
                  onClear: _clearSearch,
                ),
              ),
              const SizedBox(width: 8),
              filterButton,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_showCompactSearch) ...[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: _SearchField(
                    controller: _searchController,
                    onChanged: widget.controller.setSearchQuery,
                    onClear: _clearSearch,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Center(
              child: IntrinsicWidth(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: I18n.homeScriptSearchHint.tr,
                      onPressed: _toggleCompactSearch,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 38,
                        height: 38,
                      ),
                      style: IconButton.styleFrom(
                        foregroundColor: _showCompactSearch
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      icon: Icon(
                        _showCompactSearch
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    filterButton,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Clears both the text search and the state filter.
  void _clearSearch() {
    _searchController.clear();
    widget.controller.setSearchQuery('');
  }

  /// Clears every active collection filter and restores the full list.
  void _clearFilters() {
    _clearSearch();
    widget.controller.setStateFilterValue(HomeScriptStateFilter.all);
  }

  /// Toggles the compact search field shown above the filter buttons.
  void _toggleCompactSearch() {
    if (!mounted) {
      return;
    }
    setState(() {
      _showCompactSearch = !_showCompactSearch;
    });
  }

  Widget _buildEmptyState(BuildContext context, {required bool hasConfigs}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  hasConfigs
                      ? Icons.search_off_rounded
                      : Icons.folder_open_rounded,
                  size: 22,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasConfigs ? I18n.noData.tr : I18n.homeEmptyScriptHint.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (hasConfigs) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: Text(I18n.clear.tr),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle({required this.controller, required this.centered});

  final HomeDashboardController controller;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 2,
      children: [
        Text(
          I18n.scriptList.tr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        _StatusCounts(controller: controller),
      ],
    );
  }
}

/// Compact running / stopped / abnormal counters for the header.
class _StatusCounts extends StatelessWidget {
  const _StatusCounts({required this.controller});

  static const _states = [
    HomeScriptStateFilter.running,
    HomeScriptStateFilter.stopped,
    HomeScriptStateFilter.abnormal,
  ];

  final HomeDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      return Wrap(
        spacing: 9,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: _states.map((state) {
          return Tooltip(
            message: state.filterLabel,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: state.color(context),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${controller.countScriptsByState(state)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions({
    required this.controller,
    required this.refreshingScripts,
    required this.loadingAddScript,
    required this.onRefreshScriptsTap,
    required this.onAddScriptTap,
    required this.centered,
  });

  final HomeDashboardController controller;
  final bool refreshingScripts;
  final bool loadingAddScript;
  final VoidCallback onRefreshScriptsTap;
  final VoidCallback onAddScriptTap;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final scheme = Theme.of(context).colorScheme;
      final linkModeEnabled = controller.isLinkModeEnabled.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: centered
            ? MainAxisAlignment.center
            : MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: I18n.homeConnectionRetryAction.tr,
            onPressed: refreshingScripts ? null : onRefreshScriptsTap,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            style: IconButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
              disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
            ),
            icon: refreshingScripts
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 20),
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: linkModeEnabled
                ? I18n.closeTheLinker.tr
                : I18n.turnOnTheLinker.tr,
            onPressed: controller.toggleLinkMode,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            style: IconButton.styleFrom(
              backgroundColor: linkModeEnabled ? scheme.primaryContainer : null,
              foregroundColor: linkModeEnabled
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            icon: const Icon(Icons.link_rounded, size: 20),
          ),
          const SizedBox(width: 2),
          IconButton.filledTonal(
            tooltip: I18n.configAdd.tr,
            onPressed: loadingAddScript ? null : onAddScriptTap,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            icon: loadingAddScript
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded, size: 20),
          ),
        ],
      );
    });
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderSide = BorderSide(color: scheme.outlineVariant);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        hintText: I18n.homeScriptSearchHint.tr,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 34,
          minHeight: 34,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: I18n.clear.tr,
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close_rounded, size: 16),
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 30,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.filter,
    required this.isFiltered,
    required this.expandLabel,
    required this.onSelected,
  });

  final HomeScriptStateFilter filter;
  final bool isFiltered;
  final bool expandLabel;
  final ValueChanged<HomeScriptStateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showLabel = isFiltered && expandLabel;
    return Tooltip(
      message: filter.filterLabel,
      child: PopupMenuButton<HomeScriptStateFilter>(
        tooltip: '',
        padding: EdgeInsets.zero,
        initialValue: filter,
        onSelected: onSelected,
        itemBuilder: (context) => ConfigCollectionPanel._visibleStateFilters
            .map(
              (value) => oasxCheckedPopupItem<HomeScriptStateFilter>(
                value: value,
                checked: value == filter,
                label: value.filterLabel,
              ),
            )
            .toList(),
        child: Container(
          height: 38,
          constraints: const BoxConstraints(minWidth: 38),
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 11 : 0),
          decoration: BoxDecoration(
            color: isFiltered
                ? scheme.primaryContainer.withValues(alpha: 0.55)
                : null,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isFiltered
                  ? scheme.primary.withValues(alpha: 0.5)
                  : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: isFiltered
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                Text(
                  filter.filterLabel,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandedOrSizedBox extends StatelessWidget {
  const ExpandedOrSizedBox({
    super.key,
    required this.fillHeight,
    required this.child,
  });

  final bool fillHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (fillHeight) {
      return Expanded(child: child);
    }
    return SizedBox(height: 320, child: child);
  }
}
