import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oasx/api/sse_client.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/controllers/statistics_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/models/taskitem_model.dart';
import 'package:oasx/modules/home/widgets/active_config_panel.dart';
import 'package:oasx/modules/home/widgets/config_collection_panel.dart';
import 'package:oasx/modules/home/widgets/config_workbench.dart';
import 'package:oasx/modules/home/widgets/console_stats_pane.dart';
import 'package:oasx/modules/home/widgets/console_task_pane.dart';
import 'package:oasx/modules/home/widgets/console_task_status_view.dart';
import 'package:oasx/modules/home/widgets/home_console.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/log/log_browser_models.dart';
import 'package:oasx/modules/log/script_log_browser_controller.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/translation/i18n.dart';

class _MemoryStorage implements HomeDashboardStorage {
  final values = <String, dynamic>{};

  @override
  dynamic read(String key) => values[key];

  @override
  void write(String key, dynamic value) {
    values[key] = value;
  }
}

/// Avoids the backend reload performed by the real service during tests.
class _TestScriptService extends ScriptService {
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  Future<void> reloadFromServer() async {}
}

/// Keeps the console stats pane renderable without backend statistics calls.
class _TestStatisticsController extends HomeStatisticsController {
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> syncStatisticsBinding({bool force = false}) async {}
}

String _testNextRun(int dayOffset) {
  final date = DateTime.now().add(Duration(days: dayOffset));
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day 18:00:00';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HomeDashboardController controller;
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('oasx_home_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async {
            if (call.method == 'getApplicationDocumentsDirectory') {
              return storageDir.path;
            }
            return null;
          },
        );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    try {
      await storageDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() {
    Get.reset();
    Get.put<WebSocketService>(WebSocketService());
    final scriptService = Get.put<ScriptService>(_TestScriptService());
    scriptService.scriptModelMap
      ..['alpha'] = (ScriptModel('alpha')
        ..state.value = ScriptState.running
        ..runningTask.value = TaskItemModel('alpha', 'daily quest', '')
        ..pendingTaskList.add(
          TaskItemModel('alpha', 'queued quest', _testNextRun(0)),
        ))
      ..['a-very-long-script-name-that-needs-a-lot-of-space'] =
          (ScriptModel('a-very-long-script-name-that-needs-a-lot-of-space')
            ..state.value = ScriptState.inactive
            ..pendingTaskList.add(
              TaskItemModel('alpha', 'weekly quest', _testNextRun(1)),
            ))
      ..['broken'] = (ScriptModel('broken')..state.value = ScriptState.warning);
    scriptService.scriptOrderList.addAll([
      'alpha',
      'a-very-long-script-name-that-needs-a-lot-of-space',
      'broken',
    ]);
    controller = Get.put(HomeDashboardController(storage: _MemoryStorage()));
    Get.put<HomeStatisticsController>(
      _TestStatisticsController(),
      permanent: true,
    );
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    required double width,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: theme,
        translations: Messages(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: 620,
              child: ConfigCollectionPanel(
                controller: controller,
                fillHeight: true,
                loadingAddScript: false,
                refreshingScripts: false,
                onAddScriptTap: () {},
                onRefreshScriptsTap: () {},
                onActivateScript: (_) async {},
                onTogglePower: (_, __) async {},
                onRenameScript: (_) async {},
                onExportScript: (_) async {},
                onDeleteScript: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final theme in <String, ThemeData>{
    'light': lightTheme,
    'dark': darkTheme,
  }.entries) {
    for (final width in <double>[170, 240, 340, 520]) {
      testWidgets(
        'collection panel renders without overflow (${theme.key}, ${width}px)',
        (tester) async {
          await pumpPanel(tester, width: width, theme: theme.value);
          expect(tester.takeException(), isNull);
          expect(find.text('alpha'), findsOneWidget);
        },
      );
    }
  }

  Future<void> pumpActivePanel(
    WidgetTester tester, {
    required double width,
    required ThemeData theme,
  }) async {
    controller.setActiveScript('alpha');
    await tester.pumpWidget(
      GetMaterialApp(
        theme: theme,
        translations: Messages(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: 620,
              child: ActiveConfigPanel(
                controller: controller,
                layoutMode: HomeWorkbenchLayoutMode.twoPane,
                onChangeTab: (_) async {},
                onOpenTask: (_, __) async {},
                onTogglePower: (_, __) async {},
                onRenameScript: (_) async {},
                onDeleteScript: (_) async {},
                onSetNextRun: (_, __) async {},
                onQuickRun: (_) async {},
                onQuickWait: (_) async {},
                onBulkQuickRun: () async {},
                onBulkQuickWait: () async {},
                onExpandRightSidebar: () {},
                onBackToScripts: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final theme in <String, ThemeData>{
    'light': lightTheme,
    'dark': darkTheme,
  }.entries) {
    for (final width in <double>[320, 760]) {
      testWidgets(
        'active panel renders without overflow (${theme.key}, ${width}px)',
        (tester) async {
          await pumpActivePanel(tester, width: width, theme: theme.value);
          expect(tester.takeException(), isNull);
          expect(find.text('alpha'), findsWidgets);
        },
      );
    }
  }

  testWidgets('filter menu exposes the same script states', (tester) async {
    await pumpPanel(tester, width: 340, theme: lightTheme);
    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Select all'), findsOneWidget);
    expect(
      find.byType(CheckedPopupMenuItem<HomeScriptStateFilter>),
      findsNWidgets(4),
    );
    expect(
      find.descendant(
        of: find.byType(CheckedPopupMenuItem<HomeScriptStateFilter>),
        matching: find.text('Running'),
      ),
      findsOneWidget,
    );
  });

  void registerLogControllers() {
    for (final scriptName in <String>[
      'alpha',
      'broken',
      'a-very-long-script-name-that-needs-a-lot-of-space',
    ]) {
      final logController = Get.put(
        ScriptLogBrowserController(scriptName: scriptName),
        tag: scriptName,
        permanent: true,
      );
      logController.lines.addAll([
        ScriptLogLine(
          fileName: '$scriptName.log',
          lineNo: 1,
          offset: 0,
          byteLength: 64,
          text: '2026-10-22 12:34:56.789 INFO $scriptName ready',
          lineTruncated: false,
        ),
        ScriptLogLine(
          fileName: '$scriptName.log',
          lineNo: 2,
          offset: 64,
          byteLength: 62,
          text: '2026-10-22 12:35:01.201 ERROR $scriptName failure',
          lineTruncated: false,
        ),
      ]);
      logController.streamClient = ApiSseClient(
        url: Uri.parse('http://127.0.0.1'),
        onEvent: (_) {},
        onStateChanged: (_, __) {},
      );
    }
  }

  Future<void> pumpConsole(
    WidgetTester tester, {
    required double width,
    required ThemeData theme,
  }) async {
    controller.setActiveScript('alpha');
    registerLogControllers();
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: theme,
        translations: Messages(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: HomeConsole(
            controller: controller,
            loadingAddScript: false,
            refreshingScripts: false,
            onAddScriptTap: () {},
            onRefreshScriptsTap: () {},
            onSelectScript: (_) async {},
            onTogglePower: (_, __) async {},
            onRenameScript: (_) async {},
            onDeleteScript: (_) async {},
            onExportScript: (_) async {},
            onSetTaskNextRun: (_, __) async {},
            onQuickRunTask: (_) async {},
            onQuickWaitTask: (_) async {},
            onBulkQuickRun: () async {},
            onBulkQuickWait: () async {},
            onOpenTask: (_, __) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final theme in <String, ThemeData>{
    'light': lightTheme,
    'dark': darkTheme,
  }.entries) {
    for (final width in <double>[1080, 1280, 1600]) {
      testWidgets(
        'desktop console renders without overflow (${theme.key}, ${width}px)',
        (tester) async {
          await pumpConsole(tester, width: width, theme: theme.value);
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const ValueKey<String>('home-console-desktop')),
            findsOneWidget,
          );
          expect(find.byType(ConsoleTaskPane), findsOneWidget);
          expect(find.text('alpha'), findsWidgets);
          expect(find.byTooltip('Task Manager'), findsOneWidget);
          expect(controller.isConsoleStatsVisible.value, isFalse);
          expect(find.byType(ConsoleStatsRail), findsOneWidget);
          expect(find.byType(ConsoleStatsPane), findsNothing);
          expect(
            find.byKey(const ValueKey<String>('config-summary')),
            width >= 1600 ? findsOneWidget : findsNothing,
          );

          // The center column is a single card: task pane, log panel and
          // statistics pane, with no standalone running-task card.
          expect(find.byType(HomePaneCard), findsNWidgets(3));
          expect(
            find.descendant(
              of: find.byType(LogCenterPanel),
              matching: find.byKey(kConsoleTaskActionKey),
            ),
            findsOneWidget,
          );
          final taskName = tester.widget<Text>(
            find.byKey(kConsoleTaskStatusNameKey),
          );
          expect(taskName.data, 'daily quest');
          expect(taskName.textAlign, isNot(TextAlign.center));
          expect(taskName.maxLines, 1);
          expect(taskName.style?.fontWeight, FontWeight.w600);
        },
      );
    }
  }

  testWidgets('console task action follows the script state', (tester) async {
    await pumpConsole(tester, width: 1280, theme: lightTheme);
    final script = Get.find<ScriptService>().findScriptModel('alpha')!;
    expect(script.state.value, ScriptState.running);

    IconButton actionButton() {
      return tester.widget<IconButton>(find.byKey(kConsoleTaskActionKey));
    }

    expect(actionButton().tooltip, 'Stopped');

    script.state.value = ScriptState.inactive;
    await tester.pump();
    expect(actionButton().tooltip, 'Running');

    script.state.value = ScriptState.running;
    await tester.pump();
    expect(actionButton().tooltip, 'Stopped');
  });

  testWidgets('console log toggles update without an external rebuild', (
    tester,
  ) async {
    await pumpConsole(tester, width: 1280, theme: lightTheme);
    final logController = Get.find<ScriptLogBrowserController>(tag: 'alpha');

    // Wrap toggle: the icon lives inside a LayoutBuilder, so it must observe
    // the controller through its own Obx instead of the outer toolbar one.
    expect(logController.wrapLines.value, isTrue);
    expect(
      find.descendant(
        of: find.byType(LogCenterPanel),
        matching: find.byIcon(Icons.wrap_text),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Wrap lines'));
    await tester.pump();
    expect(logController.wrapLines.value, isFalse);
    expect(
      find.descendant(
        of: find.byType(LogCenterPanel),
        matching: find.byIcon(Icons.short_text),
      ),
      findsOneWidget,
    );

    // Auto-scroll toggle uses the same reactive path.
    logController.autoScroll.value = true;
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(LogCenterPanel),
        matching: find.byIcon(Icons.flash_on_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Auto-scroll'));
    await tester.pump();
    expect(logController.autoScroll.value, isFalse);
    expect(
      find.descendant(
        of: find.byType(LogCenterPanel),
        matching: find.byIcon(Icons.flash_off_rounded),
      ),
      findsOneWidget,
    );

    // The stream status dot must follow the live connection state.
    logController.streamStatus.value = ScriptLogStreamStatus.connected;
    await tester.pump();
    expect(find.byTooltip('Live log connected'), findsOneWidget);
    logController.streamStatus.value = ScriptLogStreamStatus.error;
    await tester.pump();
    expect(find.byTooltip('Live log disconnected'), findsOneWidget);
  });

  testWidgets('statistics column starts collapsed and binds on expand', (
    tester,
  ) async {
    await pumpConsole(tester, width: 1280, theme: lightTheme);
    expect(controller.isConsoleStatsVisible.value, isFalse);
    expect(find.byType(ConsoleStatsRail), findsOneWidget);
    expect(find.byType(ConsoleStatsPane), findsNothing);

    await tester.tap(find.byTooltip('Stats'));
    await tester.pumpAndSettle();
    expect(controller.isConsoleStatsVisible.value, isTrue);
    expect(find.byType(ConsoleStatsRail), findsNothing);
    expect(find.byType(ConsoleStatsPane), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse stats'));
    await tester.pumpAndSettle();
    expect(controller.isConsoleStatsVisible.value, isFalse);
    expect(find.byType(ConsoleStatsRail), findsOneWidget);
    expect(find.byType(ConsoleStatsPane), findsNothing);
  });

  testWidgets('desktop console maximizes and restores the log column', (
    tester,
  ) async {
    await pumpConsole(tester, width: 1280, theme: lightTheme);
    await tester.tap(find.byTooltip('Stats'));
    await tester.pumpAndSettle();
    expect(controller.isConsoleStatsVisible.value, isTrue);

    await tester.tap(find.byIcon(Icons.fullscreen_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ConsoleTaskPane), findsNothing);
    expect(find.byIcon(Icons.fullscreen_exit_rounded), findsOneWidget);
    expect(controller.isConsoleStatsVisible.value, isFalse);

    await tester.tap(find.byIcon(Icons.fullscreen_exit_rounded));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(ConsoleTaskPane), findsOneWidget);
    expect(controller.isConsoleStatsVisible.value, isTrue);
  });

  testWidgets('top config bar handles many configs without widening the body', (
    tester,
  ) async {
    final scriptService = Get.find<ScriptService>();
    for (var index = 0; index < 8; index++) {
      final name = 'config-$index';
      scriptService.scriptModelMap[name] = (ScriptModel(name)
        ..state.value = ScriptState.inactive);
      scriptService.scriptOrderList.add(name);
    }
    await pumpConsole(tester, width: 1080, theme: lightTheme);

    expect(tester.takeException(), isNull);
    expect(find.byType(ConsoleTaskPane), findsOneWidget);
  });

  testWidgets('switching config updates task and running panels', (
    tester,
  ) async {
    await pumpConsole(tester, width: 1280, theme: lightTheme);
    expect(find.text('daily quest'), findsWidgets);

    controller.setActiveScript('broken');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('daily quest'), findsNothing);
    expect(find.text('Abnormal'), findsWidgets);

    controller.setActiveScript(
      'a-very-long-script-name-that-needs-a-lot-of-space',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Not started'), findsWidgets);
    expect(controller.isConsoleStatsVisible.value, isFalse);

    final taskAction = find.byKey(kConsoleTaskActionKey);
    expect(taskAction, findsOneWidget);
    final startButton = tester.widget<IconButton>(taskAction);
    expect(startButton.iconSize, 20);
    expect(startButton.tooltip, 'Running');
    expect(find.byIcon(Icons.play_circle_fill_rounded), findsNothing);
  });

  testWidgets('console opens the full config management dialog', (
    tester,
  ) async {
    await pumpConsole(tester, width: 1280, theme: lightTheme);

    await tester.tap(find.byTooltip('Manage configs'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(ConfigCollectionPanel), findsOneWidget);
  });

  testWidgets(
    'workbench keeps the existing layout below the console breakpoint',
    (tester) async {
      controller.setActiveScript('alpha');
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        GetMaterialApp(
          theme: lightTheme,
          translations: Messages(),
          locale: const Locale('en', 'US'),
          fallbackLocale: const Locale('en', 'US'),
          home: Scaffold(
            body: ConfigWorkbench(
              controller: controller,
              scriptService: Get.find<ScriptService>(),
              loadingAddScript: false,
              refreshingScripts: false,
              onAddScriptTap: () {},
              onRefreshScriptsTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey<String>('home-workbench-desktop')),
        findsOneWidget,
      );
      expect(find.byType(HomeConsole), findsNothing);
    },
  );

  testWidgets('workbench switches to the console at the breakpoint', (
    tester,
  ) async {
    controller.setActiveScript('alpha');
    registerLogControllers();
    await tester.binding.setSurfaceSize(const Size(1080, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: lightTheme,
        translations: Messages(),
        locale: const Locale('en', 'US'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: ConfigWorkbench(
            controller: controller,
            scriptService: Get.find<ScriptService>(),
            loadingAddScript: false,
            refreshingScripts: false,
            onAddScriptTap: () {},
            onRefreshScriptsTap: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeConsole), findsOneWidget);
  });
}
