import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/api/api_client.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/log_line_presentation.dart';
import 'package:oasx/modules/log/log_browser_models.dart';
import 'package:oasx/modules/log/script_log_browser_controller.dart';
import 'package:oasx/translation/i18n_content.dart';

part 'log_center_copy_dialog.dart';
part 'log_center_error_view.dart';
part 'log_center_error_detail_view.dart';
part 'log_center_error_log_section.dart';
part 'log_center_error_image_card.dart';
part 'log_center_info_view.dart';
part 'log_center_log_text.dart';
part 'log_center_log_text_span_builder.dart';
part 'log_center_toolbar.dart';
part 'log_center_panel_scroll.dart';

/// Enables direct drag selection and the native copy menu for log text on
/// desktop platforms.
///
/// Mobile keeps the existing long-press copy dialog, which already provides a
/// selectable surface and avoids competing with the selection gesture.
Widget _wrapLogSelection(BuildContext context, Widget child) {
  final platform = Theme.of(context).platform;
  final supportsDesktopSelection =
      platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux ||
      platform == TargetPlatform.macOS;
  if (!supportsDesktopSelection) {
    return child;
  }
  return SelectionArea(child: child);
}

/// Script log center backed by the `/logs` browser API.
class LogCenterPanel extends StatefulWidget {
  /// Creates one script log center.
  const LogCenterPanel({
    super.key,
    required this.scriptName,
    this.showTitle = false,
    this.isMaximized = false,
    this.onToggleMaximize,
    this.headerStatus,
    this.headerAction,
  });

  /// Active script name.
  final String scriptName;

  /// Whether the toolbar renders the console-specific module title.
  final bool showTitle;

  /// Console-only running-task status rendered in the toolbar header.
  ///
  /// Kept as a widget slot so the log panel stays independent from the
  /// dashboard controller.
  final Widget? headerStatus;

  /// Console-only primary action rendered in the toolbar action group.
  final Widget? headerAction;

  /// Whether the panel currently fills the console workspace.
  final bool isMaximized;

  /// Toggles the console log maximization state.
  final VoidCallback? onToggleMaximize;

  @override
  State<LogCenterPanel> createState() => _LogCenterPanelState();
}

class _LogCenterPanelState extends State<LogCenterPanel> {
  static const double _bottomThreshold = 80;
  static const int _prefetchRemainingLines = 50;
  static const double _estimatedLineExtent = 22;

  final Object _viewportOwner = Object();
  final TextEditingController _logSearchController = TextEditingController();
  ScriptLogBrowserController? _controller;
  ScrollController? _scrollController;
  ScrollController? _horizontalScrollController;
  ScrollController? _errorListScrollController;
  ScrollController? _errorDetailScrollController;
  ScrollController? _errorDetailHorizontalScrollController;
  String _logQuery = '';
  ScriptLogLevelFilter _levelFilter = ScriptLogLevelFilter.all;
  bool _suppressScrollHandling = false;
  int _bottomScrollToken = 0;
  int _scrollSuppressionToken = 0;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _errorListScrollController = ScrollController();
    _errorDetailScrollController = ScrollController();
    _errorDetailHorizontalScrollController = ScrollController();
    _bindController(widget.scriptName);
  }

  @override
  void didUpdateWidget(covariant LogCenterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scriptName == widget.scriptName) {
      return;
    }
    _saveLogCenterViewport(this);
    _releaseLogCenterController(this, suspend: true);
    _resetLogFilters();
    _bindController(widget.scriptName);
  }

  bool get _hasLogFilter {
    return _logQuery.isNotEmpty || _levelFilter != ScriptLogLevelFilter.all;
  }

  /// Clears the local search and level filter.
  void _resetLogFilters() {
    _logSearchController.clear();
    _logQuery = '';
    _levelFilter = ScriptLogLevelFilter.all;
  }

  /// Returns the currently visible info log rows after local filtering.
  List<ScriptLogDisplayLine> _visibleInfoLines() {
    final controller = _controller;
    if (controller == null) {
      return const [];
    }
    final visible = <ScriptLogDisplayLine>[];
    for (final line in controller.lines) {
      final display = parseScriptLogDisplayLine(line.text);
      if (!scriptLogLineMatchesQuery(display, _logQuery) ||
          !scriptLogLineMatchesLevel(display, _levelFilter)) {
        continue;
      }
      visible.add(display);
    }
    return visible;
  }

  /// Returns the raw text copied by the toolbar for the current view.
  String get _visibleInfoText {
    return _visibleInfoLines().map((line) => line.raw).join('\n');
  }

  /// Copies the currently visible info logs or delegates the error view.
  void _copyCurrentView() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (controller.activeTab.value == ScriptLogBrowserTab.info) {
      final text = _visibleInfoText;
      if (text.isNotEmpty) {
        controller.copyText(text);
      }
      return;
    }
    controller.copyCurrentView();
  }

  @override
  void deactivate() {
    _saveLogCenterViewport(this);
    super.deactivate();
  }

  @override
  void dispose() {
    _saveLogCenterViewport(this);
    _releaseLogCenterController(this, suspend: true);
    _logSearchController.dispose();
    _scrollController?.dispose();
    _horizontalScrollController?.dispose();
    _errorListScrollController?.dispose();
    _errorDetailScrollController?.dispose();
    _errorDetailHorizontalScrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scriptName.trim().isEmpty) {
      return HomePaneCard(
        padding: const EdgeInsets.all(12),
        child: Center(child: Text(I18n.homeNoScriptSelected.tr)),
      );
    }
    final controller = _controller;
    if (controller == null) {
      return HomePaneCard(
        padding: const EdgeInsets.all(12),
        child: Center(child: Text(I18n.homeNoLog.tr)),
      );
    }
    final colors = OasxColors.of(context);
    return HomePaneCard(
      padding: const EdgeInsets.all(OasxSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogCenterToolbar(
            controller: controller,
            onToggleLineWrap: () => _handleLogCenterLineWrapToggle(this),
            title: widget.showTitle ? I18n.homeConsoleRunningLog.tr : null,
            searchController: _logSearchController,
            query: _logQuery,
            onQueryChanged: _handleLogQueryChanged,
            levelFilter: _levelFilter,
            onLevelFilterChanged: _handleLevelFilterChanged,
            onCopyCurrent: _copyCurrentView,
            isMaximized: widget.isMaximized,
            onToggleMaximize: widget.onToggleMaximize,
            headerStatus: widget.headerStatus,
            headerAction: widget.headerAction,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.logBackground,
                borderRadius: BorderRadius.circular(OasxRadius.sm),
                border: Border.all(color: colors.border),
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.fromLTRB(
                OasxSpace.sm,
                OasxSpace.xs,
                OasxSpace.xs,
                OasxSpace.xs,
              ),
              child: Obx(
                () => controller.activeTab.value == ScriptLogBrowserTab.info
                    ? LogCenterInfoView(
                        controller: controller,
                        scrollController: _scrollController!,
                        horizontalScrollController:
                            _horizontalScrollController!,
                        onScrollNotification: _handleScrollNotification,
                        query: _logQuery,
                        levelFilter: _levelFilter,
                      )
                    : LogCenterErrorView(
                        controller: controller,
                        listScrollController: _errorListScrollController!,
                        detailScrollController: _errorDetailScrollController!,
                        detailHorizontalScrollController:
                            _errorDetailHorizontalScrollController!,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogQueryChanged(String value) {
    setState(() {
      _logQuery = value.trim().toLowerCase();
    });
    _scrollInfoLogToTopAfterFrame();
  }

  void _handleLevelFilterChanged(ScriptLogLevelFilter value) {
    if (_levelFilter == value) {
      return;
    }
    setState(() {
      _levelFilter = value;
    });
    _scrollInfoLogToTopAfterFrame();
  }

  /// Returns the filtered view to its first matching record.
  void _scrollInfoLogToTopAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollController = _scrollController;
      if (!mounted ||
          scrollController == null ||
          !scrollController.hasClients) {
        return;
      }
      scrollController.jumpTo(0);
    });
  }

  void _bindController(String scriptName) {
    final normalized = scriptName.trim();
    final previousScrollController = _scrollController;
    if (normalized.isEmpty) {
      _controller = null;
      _scrollController = ScrollController();
      previousScrollController?.dispose();
      return;
    }
    _controller = _resolveController(normalized);
    _scrollController = ScrollController(
      initialScrollOffset: _controller!.savedScrollOffset,
    );
    final controller = _controller!;
    controller.viewportOwner = _viewportOwner;
    controller.scrollToBottom = () => _scrollLogCenterToBottom(this);
    controller.restoreScrollOffset = (offset) {
      _restoreLogCenterScrollOffset(this, offset);
    };
    controller.preserveViewportAfterPrepend = (insertedCount) {
      _preserveLogCenterViewportAfterPrepend(this, insertedCount);
    };
    controller.resetErrorDetailViewport = () {
      _resetErrorDetailViewport(this);
    };
    previousScrollController?.dispose();
    _activateLogCenterControllerAfterFrame(this, controller);
  }

  ScriptLogBrowserController _resolveController(String scriptName) {
    if (Get.isRegistered<ScriptLogBrowserController>(tag: scriptName)) {
      return Get.find<ScriptLogBrowserController>(tag: scriptName);
    }
    return Get.put(
      ScriptLogBrowserController(scriptName: scriptName),
      tag: scriptName,
      permanent: true,
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (_suppressScrollHandling) {
      return false;
    }
    if (notification is UserScrollNotification ||
        notification is ScrollUpdateNotification) {
      _handleLogCenterScrollPosition(this);
    }
    return false;
  }
}
