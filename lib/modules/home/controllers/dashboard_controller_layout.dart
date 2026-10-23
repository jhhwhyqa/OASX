part of 'dashboard_controller.dart';

extension HomeDashboardLayoutX on HomeDashboardController {
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
