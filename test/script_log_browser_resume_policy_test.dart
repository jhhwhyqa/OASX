import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/modules/log/script_log_browser_controller.dart';

void main() {
  test('log browser wraps lines by default', () {
    final controller = ScriptLogBrowserController(scriptName: 'demo');

    expect(controller.wrapLines.value, isTrue);
  });

  test('auto-scroll info view marks latest refresh on hide', () {
    final controller = ScriptLogBrowserController(scriptName: 'demo');

    controller.handleInfoViewHidden();

    expect(controller.shouldRefreshLatestOnInfoResume, isTrue);
  });

  test('manual info view keeps current restore policy on hide', () {
    final controller = ScriptLogBrowserController(scriptName: 'demo');
    controller.autoScroll.value = false;

    controller.handleInfoViewHidden();

    expect(controller.shouldRefreshLatestOnInfoResume, isFalse);
  });

  test('switching from info to error preserves latest refresh intent', () {
    final controller = ScriptLogBrowserController(scriptName: 'demo');
    addTearDown(controller.onClose);

    // Exercise the state transition without activating the error page; the
    // page activation starts background refresh and network work that is
    // outside this unit test's scope.
    controller.handleInfoViewHidden();
    controller.activeTab.value = ScriptLogBrowserTab.error;

    expect(controller.shouldRefreshLatestOnInfoResume, isTrue);
  });
}
