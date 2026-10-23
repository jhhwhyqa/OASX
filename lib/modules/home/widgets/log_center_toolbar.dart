part of 'log_center_panel.dart';

/// Header controls for the log center.
class LogCenterToolbar extends StatelessWidget {
  /// Creates toolbar controls.
  const LogCenterToolbar({
    super.key,
    required this.controller,
    required this.onToggleLineWrap,
    this.title,
    this.searchController,
    this.query = '',
    this.onQueryChanged,
    this.levelFilter = ScriptLogLevelFilter.all,
    this.onLevelFilterChanged,
    this.onCopyCurrent,
    this.isMaximized = false,
    this.onToggleMaximize,
    this.headerStatus,
    this.headerAction,
  });

  /// Log browser controller.
  final ScriptLogBrowserController controller;

  /// Toggles wrapping with panel-level scroll handling.
  final VoidCallback onToggleLineWrap;

  /// Optional console module title.
  final String? title;

  /// Optional console-only running-task status.
  ///
  /// When set, the header switches to the console layout: a single row that
  /// keeps the status on the left and the actions on the right.
  final Widget? headerStatus;

  /// Optional console-only primary action (power or reconnect).
  final Widget? headerAction;

  /// Minimum header width that still shows the module title.
  ///
  /// Below this width the title yields space to the running-task status.
  static const double _headerTitleMinWidth = 640;

  /// Search field controller owned by the panel.
  final TextEditingController? searchController;

  /// Current local search text.
  final String query;

  /// Updates the local search text.
  final ValueChanged<String>? onQueryChanged;

  /// Current local level filter.
  final ScriptLogLevelFilter levelFilter;

  /// Updates the local level filter.
  final ValueChanged<ScriptLogLevelFilter>? onLevelFilterChanged;

  /// Copies the currently visible log page.
  final VoidCallback? onCopyCurrent;

  /// Whether the log panel is maximized.
  final bool isMaximized;

  /// Toggles the maximized log layout.
  final VoidCallback? onToggleMaximize;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isInfo = controller.activeTab.value == ScriptLogBrowserTab.info;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderRow(context, isInfo),
          if (_usesConsoleLayout) ...[
            const SizedBox(height: 6),
            Center(child: _LogTabSwitch(controller: controller)),
          ],
          if (isInfo) ...[
            const SizedBox(height: 8),
            _buildInfoFilters(context),
          ],
        ],
      );
    });
  }

  /// Builds the header row for the current caller.
  ///
  /// Callers without console slots keep the legacy wrapping layout. The
  /// console uses a single stable row so the task name can truncate instead of
  /// wrapping into a second header line.
  Widget _buildHeaderRow(BuildContext context, bool isInfo) {
    if (!_usesConsoleLayout) {
      return _buildStandardHeaderRow(context, isInfo);
    }
    return _buildConsoleHeaderRow(context, isInfo);
  }

  /// Whether this toolbar renders the console-specific header.
  bool get _usesConsoleLayout {
    return headerStatus != null || headerAction != null;
  }

  Widget _buildStandardHeaderRow(BuildContext context, bool isInfo) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              _LogTabSwitch(controller: controller),
              if (isInfo) _streamStatus(context),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _trailingControls(context),
      ],
    );
  }

  Widget _buildConsoleHeaderRow(BuildContext context, bool isInfo) {
    final scheme = Theme.of(context).colorScheme;
    final status = headerStatus;
    final action = headerAction;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showTitle =
            title != null && constraints.maxWidth >= _headerTitleMinWidth;
        return Row(
          children: [
            if (showTitle) ...[
              Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 14,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: status ?? const SizedBox.shrink(),
              ),
            ),
            if (isInfo) ...[
              const SizedBox(width: 8),
              // LayoutBuilder runs during layout, after GetX's Obx tracking has
              // stopped, so reactive reads must happen inside their own Obx.
              Obx(() => _streamStatus(context)),
            ],
            if (action != null) ...[const SizedBox(width: 6), action],
            Obx(() => _trailingControls(context)),
          ],
        );
      },
    );
  }

  /// Builds the action buttons aligned to the right.
  Widget _trailingControls(BuildContext context) {
    if (!_shouldShowLogActions()) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_shouldShowWrapAction()) _wrapButton(context),
        if (controller.activeTab.value == ScriptLogBrowserTab.info)
          _autoScrollButton(context),
        _copyButton(context),
        _clearButton(context),
        if (onToggleMaximize != null) _maximizeButton(context),
      ],
    );
  }

  /// Returns whether the current view owns log text actions.
  bool _shouldShowLogActions() {
    if (controller.activeTab.value == ScriptLogBrowserTab.info) {
      return true;
    }
    return controller.errorDetailVisible.value;
  }

  /// Returns whether wrapping can affect the current log text.
  bool _shouldShowWrapAction() {
    if (controller.activeTab.value == ScriptLogBrowserTab.info) {
      return true;
    }
    return controller.errorDetailVisible.value;
  }

  /// Builds the live stream state dot.
  Widget _streamStatus(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = OasxStateColors.of(context);
    final status = controller.streamStatus.value;
    final color = switch (status) {
      ScriptLogStreamStatus.connected => colors.running,
      ScriptLogStreamStatus.connecting ||
      ScriptLogStreamStatus.reconnecting => colors.abnormal,
      ScriptLogStreamStatus.error => scheme.error,
      ScriptLogStreamStatus.idle => scheme.outline,
    };
    final label = switch (status) {
      ScriptLogStreamStatus.connected => I18n.homeConsoleLogConnected.tr,
      ScriptLogStreamStatus.connecting ||
      ScriptLogStreamStatus.reconnecting => I18n.homeConsoleLogConnecting.tr,
      ScriptLogStreamStatus.error => I18n.homeConsoleLogDisconnected.tr,
      ScriptLogStreamStatus.idle => I18n.homeConsoleLogDisconnected.tr,
    };
    return Tooltip(
      message: label,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }

  /// Builds the search field and level filter row.
  Widget _buildInfoFilters(BuildContext context) {
    final searchController = this.searchController;
    if (searchController == null) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final borderSide = BorderSide(color: scheme.outlineVariant);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              hintText: I18n.homeConsoleLogSearch.tr,
              hintStyle: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 17,
                color: scheme.onSurfaceVariant,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: I18n.clear.tr,
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged?.call('');
                      },
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 9,
              ),
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
          ),
        ),
        const SizedBox(width: 8),
        _levelFilterButton(context),
      ],
    );
  }

  Widget _levelFilterButton(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFiltered = levelFilter != ScriptLogLevelFilter.all;
    return Tooltip(
      message: I18n.homeConsoleLogLevel.tr,
      child: PopupMenuButton<ScriptLogLevelFilter>(
        tooltip: '',
        padding: EdgeInsets.zero,
        initialValue: levelFilter,
        onSelected: onLevelFilterChanged,
        itemBuilder: (context) => ScriptLogLevelFilter.values
            .map(
              (value) => CheckedPopupMenuItem<ScriptLogLevelFilter>(
                value: value,
                checked: value == levelFilter,
                child: Text(_levelLabel(value)),
              ),
            )
            .toList(),
        child: Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 38),
          padding: EdgeInsets.symmetric(horizontal: isFiltered ? 9 : 0),
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
              if (isFiltered) ...[
                const SizedBox(width: 4),
                Text(
                  _levelLabel(levelFilter),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  String _levelLabel(ScriptLogLevelFilter value) {
    return switch (value) {
      ScriptLogLevelFilter.all => I18n.homeConsoleAllLevels.tr,
      ScriptLogLevelFilter.info => 'INFO',
      ScriptLogLevelFilter.warning => 'WARNING',
      ScriptLogLevelFilter.error => 'ERROR',
    };
  }

  Widget _autoScrollButton(BuildContext context) {
    final enabled = controller.autoScroll.value;
    return IconButton(
      tooltip: I18n.homeLogAutoScroll.tr,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(fixedSize: const Size(36, 36)),
      padding: EdgeInsets.zero,
      onPressed: controller.toggleAutoScroll,
      icon: Icon(
        enabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
        size: 20,
      ),
    );
  }

  /// Builds the long-line wrapping action.
  Widget _wrapButton(BuildContext context) {
    final enabled = controller.wrapLines.value;
    return IconButton(
      tooltip: I18n.homeLogWrapLines.tr,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(fixedSize: const Size(36, 36)),
      padding: EdgeInsets.zero,
      onPressed: onToggleLineWrap,
      icon: Icon(enabled ? Icons.wrap_text : Icons.short_text, size: 20),
    );
  }

  /// Builds the copy action.
  Widget _copyButton(BuildContext context) {
    return IconButton(
      tooltip: I18n.copy.tr,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(fixedSize: const Size(36, 36)),
      padding: EdgeInsets.zero,
      onPressed: onCopyCurrent ?? controller.copyCurrentView,
      icon: const Icon(Icons.content_copy_rounded, size: 19),
    );
  }

  /// Builds the clear action.
  Widget _clearButton(BuildContext context) {
    return IconButton(
      tooltip: I18n.clearLog.tr,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(fixedSize: const Size(36, 36)),
      padding: EdgeInsets.zero,
      onPressed: controller.clearCurrentView,
      icon: const Icon(Icons.delete_outlined, size: 19),
    );
  }

  Widget _maximizeButton(BuildContext context) {
    return IconButton(
      tooltip: isMaximized
          ? I18n.homeConsoleRestoreLayout.tr
          : I18n.homeConsoleMaximizeLog.tr,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      style: IconButton.styleFrom(fixedSize: const Size(36, 36)),
      padding: EdgeInsets.zero,
      onPressed: onToggleMaximize,
      icon: Icon(
        isMaximized ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
        size: 20,
      ),
    );
  }
}

/// Info/error selector rendered as a pill slider.
///
/// The selected pill slides between two equal-width tabs instead of swapping
/// backgrounds, which keeps the switch stable when the console header resizes.
class _LogTabSwitch extends StatelessWidget {
  const _LogTabSwitch({required this.controller});

  final ScriptLogBrowserController controller;

  static const double _tabWidth = 68;
  static const double _tabHeight = 28;
  static const Duration _duration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInfo = controller.activeTab.value == ScriptLogBrowserTab.info;
    final trackColor = isDark
        ? scheme.surfaceContainerLowest.withValues(alpha: 0.85)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);
    final pillColor = isDark ? scheme.surfaceContainerHigh : scheme.surface;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.7),
        ),
      ),
      child: SizedBox(
        width: _tabWidth * 2,
        height: _tabHeight,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: _duration,
              curve: Curves.easeOutCubic,
              alignment: isInfo ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                width: _tabWidth,
                height: _tabHeight,
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(
                      alpha: isDark ? 0.45 : 0.6,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(
                        alpha: isDark ? 0.18 : 0.1,
                      ),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                _buildTab(
                  context,
                  ScriptLogBrowserTab.info,
                  I18n.homeLogInfoTab.tr,
                  selected: isInfo,
                ),
                _buildTab(
                  context,
                  ScriptLogBrowserTab.error,
                  I18n.homeLogErrorTab.tr,
                  selected: !isInfo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    ScriptLogBrowserTab tab,
    String label, {
    required bool selected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: _tabWidth,
        height: _tabHeight,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            mouseCursor: SystemMouseCursors.click,
            hoverColor: scheme.onSurface.withValues(alpha: 0.04),
            onTap: selected ? null : () => controller.selectTab(tab),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: _duration,
                curve: Curves.easeOut,
                style: textStyle ?? const TextStyle(),
                child: Text(label, maxLines: 1, softWrap: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
