part of 'dashboard_controller.dart';

extension HomeDashboardLayoutX on HomeDashboardController {
  /// Returns the persisted collection width after sanitizing the stored value.
  void _loadWorkbenchCollectionWidth() {
    final storedWidth = _storage.read(
      StorageKey.homeWorkbenchCollectionWidth.name,
    );
    workbenchCollectionWidth.value = sanitizeHomeWorkbenchCollectionWidth(
      storedWidth,
    );
  }

  /// Persists the latest valid collection width.
  void setWorkbenchCollectionWidth(double value) {
    final normalized = sanitizeHomeWorkbenchCollectionWidth(value);
    if ((workbenchCollectionWidth.value - normalized).abs() < 0.0001) {
      return;
    }
    workbenchCollectionWidth.value = normalized;
    _storage.write(StorageKey.homeWorkbenchCollectionWidth.name, normalized);
  }

  /// Returns the persisted split ratio after sanitizing the stored value.
  void _loadWorkbenchSplitRatio() {
    final storedRatio = _storage.read(StorageKey.homeWorkbenchSplitRatio.name);
    workbenchSplitRatio.value = sanitizeHomeWorkbenchSplitRatio(storedRatio);
  }

  /// Persists the latest valid three-pane split ratio.
  void setWorkbenchSplitRatio(double value) {
    final normalized = sanitizeHomeWorkbenchSplitRatio(value);
    if ((workbenchSplitRatio.value - normalized).abs() < 0.0001) {
      return;
    }
    workbenchSplitRatio.value = normalized;
    _storage.write(StorageKey.homeWorkbenchSplitRatio.name, normalized);
  }

  /// Loads the independent three-column console ratios.
  void _loadHomeConsoleLayout() {
    homeConsoleLeftRatio.value = sanitizeHomeConsoleLeftRatio(
      _storage.read(StorageKey.homeConsoleLeftRatio.name),
    );
    homeConsoleRightRatio.value = sanitizeHomeConsoleRightRatio(
      _storage.read(StorageKey.homeConsoleRightRatio.name),
    );
  }

  /// Persists the latest valid task-column ratio.
  void setHomeConsoleLeftRatio(double value) {
    final normalized = sanitizeHomeConsoleLeftRatio(value);
    if ((homeConsoleLeftRatio.value - normalized).abs() < 0.0001) {
      return;
    }
    homeConsoleLeftRatio.value = normalized;
    _storage.write(StorageKey.homeConsoleLeftRatio.name, normalized);
  }

  /// Persists the latest valid statistics-column ratio.
  void setHomeConsoleRightRatio(double value) {
    final normalized = sanitizeHomeConsoleRightRatio(value);
    if ((homeConsoleRightRatio.value - normalized).abs() < 0.0001) {
      return;
    }
    homeConsoleRightRatio.value = normalized;
    _storage.write(StorageKey.homeConsoleRightRatio.name, normalized);
  }

  /// Marks whether the desktop console is the active home layout.
  void setConsoleLayoutActive(bool value) {
    if (isConsoleLayoutActive.value == value) {
      return;
    }
    isConsoleLayoutActive.value = value;
  }

  /// Marks whether the desktop console currently renders the statistics pane.
  void setConsoleStatsVisible(bool value) {
    if (isConsoleStatsVisible.value == value) {
      return;
    }
    isConsoleStatsVisible.value = value;
  }
}
