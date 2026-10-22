part of 'log_center_panel.dart';

/// Info log list with history prefetch.
class LogCenterInfoView extends StatelessWidget {
  /// Creates the info log view.
  const LogCenterInfoView({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.horizontalScrollController,
    required this.onScrollNotification,
    this.query = '',
    this.levelFilter = ScriptLogLevelFilter.all,
  });

  /// Log browser controller.
  final ScriptLogBrowserController controller;

  /// Scroll controller owned by panel state.
  final ScrollController scrollController;

  /// Horizontal scroll controller used when wrapping is disabled.
  final ScrollController horizontalScrollController;

  /// Scroll notification handler.
  final bool Function(ScrollNotification notification) onScrollNotification;

  /// Local text filter.
  final String query;

  /// Local level filter.
  final ScriptLogLevelFilter levelFilter;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.infoLoading.value && controller.lines.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.infoError.value.isNotEmpty && controller.lines.isEmpty) {
        return _buildMessage(context, controller.infoError.value);
      }
      if (controller.lines.isEmpty) {
        return _buildMessage(context, I18n.homeNoLog.tr);
      }
      final visibleLines = _buildVisibleLines();
      if (visibleLines.isEmpty) {
        return _buildMessage(context, I18n.homeLogEmptyFiltered.tr);
      }
      return Column(
        children: [
          if (controller.olderLoading.value)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _buildList(
              context,
              controller.wrapLines.value,
              visibleLines,
            ),
          ),
        ],
      );
    });
  }

  /// Returns the current window filtered by text and level.
  List<ScriptLogLine> _buildVisibleLines() {
    final visible = <ScriptLogLine>[];
    for (final line in controller.lines) {
      final display = parseScriptLogDisplayLine(line.text);
      if (!scriptLogLineMatchesQuery(display, query) ||
          !scriptLogLineMatchesLevel(display, levelFilter)) {
        continue;
      }
      visible.add(line);
    }
    return visible;
  }

  Widget _buildList(
    BuildContext context,
    bool wrapLines,
    List<ScriptLogLine> lines,
  ) {
    return Scrollbar(
      controller: scrollController,
      interactive: true,
      thumbVisibility: true,
      notificationPredicate: (notification) {
        return notification.metrics.axis == Axis.vertical;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ClipRect(child: _buildScrollableArea(context, wrapLines, lines)),
      ),
    );
  }

  Widget _buildScrollableArea(
    BuildContext context,
    bool wrapLines,
    List<ScriptLogLine> lines,
  ) {
    if (wrapLines) {
      return _buildVerticalList(context, wrapLines: true, lines: lines);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = _resolveContentWidth(context, constraints.maxWidth);
        return Scrollbar(
          controller: horizontalScrollController,
          interactive: true,
          thumbVisibility: width > constraints.maxWidth,
          notificationPredicate: (notification) {
            return notification.metrics.axis == Axis.horizontal;
          },
          child: SingleChildScrollView(
            controller: horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: _buildVerticalList(
                context,
                wrapLines: false,
                lines: lines,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerticalList(
    BuildContext context, {
    required bool wrapLines,
    required List<ScriptLogLine> lines,
  }) {
    final list = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _openCopyDialog(context, lines),
      child: NotificationListener<ScrollNotification>(
        onNotification: onScrollNotification,
        child: ListView.builder(
          key: ValueKey<String>('log-info-${controller.scriptName}'),
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final line = lines[index];
            return LogCenterLogText(
              key: ValueKey<String>(line.key),
              line: line.text,
              maxLines: wrapLines ? null : 1,
              overflow: wrapLines ? TextOverflow.clip : TextOverflow.visible,
              softWrap: wrapLines,
            );
          },
        ),
      ),
    );
    return _wrapLogSelection(context, list);
  }

  double _resolveContentWidth(BuildContext context, double viewportWidth) {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14;
    final longest = controller.maxLineWidthScore;
    final estimatedWidth = longest * fontSize * 0.64 + 48;
    return estimatedWidth < viewportWidth ? viewportWidth : estimatedWidth;
  }

  Widget _buildMessage(BuildContext context, String message) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  /// Opens the dedicated copy dialog with the current visible log body.
  void _openCopyDialog(BuildContext context, List<ScriptLogLine> lines) {
    showLogCenterCopyDialog(
      context,
      text: lines.map((line) => line.text).join('\n'),
      onCopy: controller.copyText,
    );
  }
}
