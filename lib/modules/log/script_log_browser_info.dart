part of 'script_log_browser_controller.dart';

/// Backoff used when the first latest-window request fails after mounting.
///
/// The backend can still be starting up after an auto deploy, so a single
/// failure should not require the user to refresh the panel manually.
const List<Duration> _infoLoadRetryDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
];

extension ScriptLogBrowserInfoX on ScriptLogBrowserController {
  /// Loads latest log window and starts live stream.
  Future<void> refreshLatest() async {
    _cancelInfoRetry();
    _infoRetryAttempt = 0;
    await _refreshLatestAttempt();
  }

  /// Runs one latest-window load attempt.
  Future<void> _refreshLatestAttempt() async {
    final requestId = ++revision;
    _infoLoadRequestId = requestId;
    infoLoading.value = true;
    infoError.value = '';
    await stopStream();
    try {
      final window = await ApiClient().getScriptLogWindow(
        scriptName,
        limitLines: kAutoScrollLogWindowLineLimit,
      );
      if (!isInfoLoadActive(requestId)) {
        return;
      }
      applyFreshWindow(window);
      _shouldRefreshLatestOnInfoResume = false;
      syncWindowLimitForMode();
      infoLoading.value = false;
      _infoRetryAttempt = 0;
      unawaited(startStream(requestId));
      syncBottomAfterFrame();
    } catch (error) {
      if (!isInfoLoadActive(requestId)) {
        return;
      }
      infoLoading.value = false;
      infoError.value = error.toString();
      streamStatus.value = ScriptLogStreamStatus.error;
      _scheduleInfoRetry();
    } finally {
      if (_infoLoadRequestId == requestId) {
        _infoLoadRequestId = 0;
      }
    }
  }

  /// Retries a failed latest-window load while the panel stays mounted.
  void _scheduleInfoRetry() {
    if (isClosed || viewportOwner == null) {
      return;
    }
    if (_infoRetryAttempt >= _infoLoadRetryDelays.length) {
      return;
    }
    final delay = _infoLoadRetryDelays[_infoRetryAttempt++];
    _cancelInfoRetry();
    _infoRetryTimer = Timer(delay, () {
      _infoRetryTimer = null;
      if (isClosed || viewportOwner == null || lines.isNotEmpty) {
        return;
      }
      unawaited(_refreshLatestAttempt());
    });
  }

  /// Cancels a pending latest-window retry.
  void _cancelInfoRetry() {
    _infoRetryTimer?.cancel();
    _infoRetryTimer = null;
  }

  /// Loads older lines before the current first line.
  Future<void> prefetchOlder() async {
    final cursor = olderCursor;
    if (cursor == null || cursor.isEmpty || reachedStart) {
      return;
    }
    if (olderLoading.value || infoLoading.value) {
      return;
    }
    final requestId = revision;
    _olderLoadRequestId = requestId;
    olderLoading.value = true;
    try {
      final window = await ApiClient().getScriptLogWindow(
        scriptName,
        cursor: cursor,
        limitLines: kAutoScrollLogWindowLineLimit,
      );
      if (isOlderLoadActive(requestId)) {
        prependOlderWindow(window);
        syncWindowLimitForMode();
        trimToLiveWindow();
      }
    } catch (error) {
      if (isOlderLoadActive(requestId)) {
        infoError.value = error.toString();
      }
    } finally {
      if (isOlderLoadActive(requestId)) {
        olderLoading.value = false;
      }
      if (_olderLoadRequestId == requestId) {
        _olderLoadRequestId = 0;
      }
    }
  }

  /// Copies info lines to clipboard.
  void copyInfoLogs() {
    copyText(infoLogText);
  }

  /// Starts the live stream without replacing the current visible window.
  Future<void> resumeLiveStream() async {
    final requestId = ++revision;
    await stopStream();
    unawaited(startStream(requestId));
  }

  /// Restores the saved manual position.
  void restoreManualPosition() {
    if (savedScrollOffset <= 0) {
      return;
    }
    restoreScrollOffset?.call(savedScrollOffset);
  }

  /// Schedules a bottom follow after the current frame.
  void syncBottomAfterFrame() {
    if (_bottomSyncQueued) {
      return;
    }
    _bottomSyncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bottomSyncQueued = false;
      scrollToBottom?.call();
    });
  }
}
