import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/api/sse_client.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/common/widgets/desktop_navigation_shell.dart';
import 'package:oasx/modules/common/widgets/oasx_backdrop.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/controllers/statistics_controller.dart';
import 'package:oasx/modules/home/models/config_model.dart';
import 'package:oasx/modules/home/models/taskitem_model.dart';
import 'package:oasx/modules/home/widgets/home_console.dart';
import 'package:oasx/modules/log/log_browser_models.dart';
import 'package:oasx/modules/log/script_log_browser_controller.dart';
import 'package:oasx/modules/server/controllers/server_controller.dart';
import 'package:oasx/modules/server/server_view.dart';
import 'package:oasx/modules/settings/widgets/setting_card.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/service/websocket_service.dart';
import 'package:oasx/translation/i18n.dart';

/// Visual fixtures for the redesigned console.
///
/// Run with `flutter test test/ui_preview_golden_test.dart --update-goldens`
/// to refresh `test/preview/*.png`.
class _MemoryStorage implements HomeDashboardStorage {
  final values = <String, dynamic>{};

  @override
  dynamic read(String key) => values[key];

  @override
  void write(String key, dynamic value) {
    values[key] = value;
  }
}

class _TestScriptService extends ScriptService {
  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  Future<void> reloadFromServer() async {}
}

class _TestStatisticsController extends HomeStatisticsController {
  @override
  Future<void> syncStatisticsBinding({bool force = false}) async {}
}

class _TestServerController extends ServerController {
  @override
  // ignore: must_call_super
  void onInit() {
    rootPathServer.value = r'D:\OAS\oas-server';
    rootPathAuthenticated.value = true;
    deployContent.value = 'python:\n  version: "3.12"\n';
    logs.addAll([
      'INFO: Checking toolkit/python.exe',
      'INFO: Checking toolkit/Git/mingw64/bin/git.exe',
      'INFO: Reading config/deploy.yaml',
      'INFO: Deploy workspace is ready',
    ]);
  }
}

String _nextRun(int dayOffset, {int hour = 18}) {
  final date = DateTime.now().add(Duration(days: dayOffset));
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hourText = hour.toString().padLeft(2, '0');
  return '${date.year}-$month-$day $hourText:00:00';
}

/// Uses the CJK face as the primary text family so the fixture renders every
/// glyph deterministically across test hosts.
ThemeData _previewTheme(ThemeData theme) {
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamily: 'Microsoft YaHei'),
    primaryTextTheme: theme.primaryTextTheme.apply(
      fontFamily: 'Microsoft YaHei',
    ),
  );
}

const String _cjkFontPath = r'C:\Windows\Fonts\simhei.ttf';
const String _monoFontPath = r'C:\Windows\Fonts\consola.ttf';

String? _resolveMaterialIconsPath() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = <String>[
    if (flutterRoot != null)
      '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    'build/flutter_assets/fonts/MaterialIcons-Regular.otf',
  ];
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  return null;
}

/// Warms the brand image cache so the first fixture shows the app mark.
Future<void> _warmBrandImage(WidgetTester tester) async {
  await tester.runAsync(() async {
    final context = tester.element(find.byType(Scaffold));
    await precacheImage(const AssetImage('assets/images/Icon-app.png'), context);
  });
}

Future<void> _loadFont(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final data = ByteData.view(
    bytes.buffer,
    bytes.offsetInBytes,
    bytes.lengthInBytes,
  );
  final loader = FontLoader(family)..addFont(Future<ByteData>.value(data));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final materialIconsPath = _resolveMaterialIconsPath();
  final skipGolden =
      !Platform.isWindows ||
      !File(_cjkFontPath).existsSync() ||
      !File(_monoFontPath).existsSync() ||
      materialIconsPath == null;

  late HomeDashboardController controller;
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('oasx_preview');
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
    if (!skipGolden) {
      // The fixture pins a full CJK face as the UI family so component themes
      // render every glyph; mono stays monospace for log alignment.
      await _loadFont('Microsoft YaHei', _cjkFontPath);
      await _loadFont('LatoLato', _cjkFontPath);
      await _loadFont('MaterialIcons', materialIconsPath);
      for (final family in <String>[
        'Cascadia Mono',
        'Cascadia Code',
        'Consolas',
      ]) {
        await _loadFont(family, _monoFontPath);
      }
    }
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
      ..['主账号'] = (ScriptModel('主账号')
        ..state.value = ScriptState.running
        ..runningTask.value = TaskItemModel('主账号', '日常任务', '')
        ..pendingTaskList.addAll([
          TaskItemModel('主账号', '活动副本', _nextRun(0, hour: 20)),
          TaskItemModel('主账号', '每周任务', _nextRun(1)),
          TaskItemModel('主账号', '邮件领取', _nextRun(2)),
          TaskItemModel('主账号', '好友赠送', _nextRun(3)),
        ]))
      ..['小号-活动'] = (ScriptModel('小号-活动')
        ..state.value = ScriptState.warning
        ..pendingTaskList.add(
          TaskItemModel('小号-活动', '限时活动', _nextRun(0, hour: 21)),
        ))
      ..['a-very-long-script-name-that-needs-a-lot-of-space'] =
          (ScriptModel('a-very-long-script-name-that-needs-a-lot-of-space')
            ..state.value = ScriptState.inactive
            ..pendingTaskList.add(
              TaskItemModel('a-very-long-script-name-that-needs-a-lot-of-space', '周末副本', _nextRun(4)),
            ));
    scriptService.scriptOrderList.addAll([
      '主账号',
      '小号-活动',
      'a-very-long-script-name-that-needs-a-lot-of-space',
    ]);
    controller = Get.put(HomeDashboardController(storage: _MemoryStorage()));
    Get.put<HomeStatisticsController>(
      _TestStatisticsController(),
      permanent: true,
    );
  });

  tearDown(Get.reset);

  void registerLogs() {
    for (final scriptName in <String>[
      '主账号',
      '小号-活动',
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
          text:
              '2026-10-23 12:34:56.789 INFO Connected to OAS service; loading script configuration',
          lineTruncated: false,
        ),
        ScriptLogLine(
          fileName: '$scriptName.log',
          lineNo: 2,
          offset: 64,
          byteLength: 64,
          text:
              '2026-10-23 12:34:57.102 INFO Daily task started; queue holds 3 tasks',
          lineTruncated: false,
        ),
        ScriptLogLine(
          fileName: '$scriptName.log',
          lineNo: 3,
          offset: 128,
          byteLength: 64,
          text:
              '2026-10-23 12:35:01.201 WARNING Network jitter detected; retrying attempt 1',
          lineTruncated: false,
        ),
        ScriptLogLine(
          fileName: '$scriptName.log',
          lineNo: 4,
          offset: 192,
          byteLength: 64,
          text:
              "2026-10-23 12:35:02.447 INFO Task 'Event Dungeon' entered battle (00:01:24); 12 materials dropped",
          lineTruncated: false,
        ),
        ScriptLogLine(
          fileName: '$scriptName.log',
          lineNo: 5,
          offset: 256,
          byteLength: 64,
          text:
              '2026-10-23 12:35:03.500 ERROR Target window not found; waiting for the next retry',
          lineTruncated: false,
        ),
        ScriptLogLine(
          fileName: '$scriptName.log',
          lineNo: 6,
          offset: 320,
          byteLength: 64,
          text:
              '2026-10-23 12:35:04.118 INFO Long-line fixture: task parameters, window handles and retry policy all come from remote configuration; nothing is cached in plaintext locally',
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
    required double height,
    required ThemeData theme,
    double textScale = 1,
    bool includeRail = true,
  }) async {
    controller.setActiveScript('主账号');
    registerLogs();
    final console = Padding(
      padding: const EdgeInsets.all(OasxSpace.lg),
      child: HomeConsole(
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
    );
    await tester.binding.setSurfaceSize(Size(width, height));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: _previewTheme(theme),
        translations: Messages(),
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          );
        },
        home: Scaffold(
          body: OasxBackdrop(
            child: includeRail
                ? Row(
                    children: [
                      OasxDesktopNavigationRail(
                        showFooter: false,
                        destinations: _previewDestinations(),
                        selectedIndex: 0,
                        onSelected: (_) {},
                      ),
                      Expanded(child: console),
                    ],
                  )
                : console,
          ),
        ),
      ),
    );
    await _warmBrandImage(tester);
    await tester.pumpAndSettle();
  }

  testWidgets('home console dark', skip: skipGolden, (tester) async {
    await pumpConsole(
      tester,
      width: 1440,
      height: 900,
      theme: darkTheme,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/home_console_dark.png'),
    );
  });

  testWidgets('home console light', skip: skipGolden, (tester) async {
    await pumpConsole(
      tester,
      width: 1440,
      height: 900,
      theme: lightTheme,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/home_console_light.png'),
    );
  });

  testWidgets('home console compact dark', skip: skipGolden, (tester) async {
    await pumpConsole(
      tester,
      width: 390,
      height: 844,
      theme: darkTheme,
      includeRail: false,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/home_console_compact_dark.png'),
    );
  });

  testWidgets('home console compact text 200', skip: skipGolden, (
    tester,
  ) async {
    await pumpConsole(
      tester,
      width: 390,
      height: 844,
      theme: darkTheme,
      textScale: 2,
      includeRail: false,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/home_console_compact_text_200.png'),
    );
  });

  testWidgets('home console dark large text', skip: skipGolden, (tester) async {
    await pumpConsole(
      tester,
      width: 1080,
      height: 760,
      theme: darkTheme,
      textScale: 1.3,
    );
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/home_console_dark_text_130.png'),
    );
  });

  testWidgets('server deploy dark', skip: skipGolden, (tester) async {
    Get.put<ServerController>(_TestServerController());
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: _previewTheme(darkTheme),
        translations: Messages(),
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: OasxBackdrop(
            child: Row(
              children: [
                OasxDesktopNavigationRail(
                  showFooter: false,
                  destinations: _previewDestinations(),
                  selectedIndex: 1,
                  onSelected: (_) {},
                ),
                const Expanded(child: ServerView(standalone: false)),
              ],
            ),
          ),
        ),
      ),
    );
    await _warmBrandImage(tester);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/server_deploy_dark.png'),
    );
  });

  testWidgets('settings medium dark', skip: skipGolden, (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: _previewTheme(darkTheme),
        translations: Messages(),
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: OasxBackdrop(
            child: Row(
              children: [
                OasxDesktopNavigationRail(
                  showFooter: false,
                  destinations: _previewDestinations(),
                  selectedIndex: 2,
                  onSelected: (_) {},
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(OasxSpace.lg),
                    child: Column(
                      children: [
                        const _SettingsTabsPreview(),
                        const SizedBox(height: OasxSpace.md),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                _userCard(),
                                const SizedBox(height: OasxSpace.md),
                                _oasCard(),
                                const SizedBox(height: OasxSpace.md),
                                _systemCard(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await _warmBrandImage(tester);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/settings_medium_dark.png'),
    );
  });

  testWidgets('settings cards dark', skip: skipGolden, (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: _previewTheme(darkTheme),
        translations: Messages(),
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        home: Scaffold(
          body: OasxBackdrop(
            child: Padding(
              padding: const EdgeInsets.all(OasxSpace.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OasxDesktopNavigationRail(
                    showFooter: false,
                    destinations: _previewDestinations(),
                    selectedIndex: 2,
                    onSelected: (_) {},
                  ),
                  const SizedBox(width: OasxSpace.md),
                  _SettingsNavPreview(),
                  const SizedBox(width: OasxSpace.md),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _userCard(),
                          const SizedBox(height: OasxSpace.md),
                          _oasCard(),
                          const SizedBox(height: OasxSpace.md),
                          _systemCard(),
                        ],
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
    await _warmBrandImage(tester);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('preview/settings_dark.png'),
    );
  });
}

List<OasxShellDestination> _previewDestinations() {
  return const [
    OasxShellDestination(
      routePath: '/home',
      label: '工作台',
      icon: Icons.dashboard_customize_outlined,
      selectedIcon: Icons.dashboard_customize_rounded,
    ),
    OasxShellDestination(
      routePath: '/server',
      label: '部署',
      icon: Icons.dns_outlined,
      selectedIcon: Icons.dns_rounded,
    ),
    OasxShellDestination(
      routePath: '/settings',
      label: '设置',
      icon: Icons.tune_outlined,
      selectedIcon: Icons.tune_rounded,
    ),
  ];
}

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(hintText: hint);
}

Widget _inputValue(String value) {
  return SizedBox(
    width: 220,
    child: TextField(
      controller: TextEditingController(text: value),
      decoration: _fieldDecoration(value),
    ),
  );
}

Widget _userCard() {
  return SettingCard(
    title: '用户设置',
    icon: Icons.person_outline_rounded,
    items: [
      SettingItem(
        left: const Text('登录地址'),
        right: _inputValue('http://127.0.0.1:8000'),
      ),
      SettingItem(left: const Text('用户名'), right: _inputValue('admin')),
      SettingItem(
        left: const Text('密码'),
        right: SizedBox(
          width: 220,
          child: TextField(
            obscureText: true,
            controller: TextEditingController(text: 'password'),
          ),
        ),
      ),
    ],
  );
}

Widget _oasCard() {
  return SettingCard(
    title: 'OAS设置',
    icon: Icons.hub_outlined,
    items: [
      SettingItem(
        left: const Text('部署OAS'),
        right: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: () {},
      ),
      SettingItem(
        left: const Text('自动部署OAS'),
        right: Switch(value: true, onChanged: (_) {}),
      ),
      SettingItem(
        left: const Text('部署后自动登录'),
        right: Switch(value: false, onChanged: (_) {}),
      ),
      SettingItem(
        left: const Text('关闭 OASX 时同时关闭 OAS'),
        right: Switch(value: true, onChanged: (_) {}),
      ),
    ],
  );
}

Widget _systemCard() {
  return SettingCard(
    title: '系统设置',
    icon: Icons.tune_rounded,
    items: [
      SettingItem(
        left: const Text('切换主题'),
        right: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.light_mode_outlined),
        ),
      ),
      SettingItem(
        left: const Text('切换语言'),
        right: ToggleButtons(
          isSelected: const [true, false],
          onPressed: (_) {},
          borderRadius: BorderRadius.circular(8),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('简体中文'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('English'),
            ),
          ],
        ),
      ),
      SettingItem(
        left: const Text('开机自启'),
        right: Switch(value: true, onChanged: (_) {}),
      ),
      SettingItem(
        left: const Text('当前版本: 0.3.1'),
        right: OutlinedButton(
          onPressed: () {},
          child: const Text('检查更新'),
        ),
      ),
    ],
  );
}

class _SettingsTabsPreview extends StatelessWidget {
  const _SettingsTabsPreview();

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    const items = <(String, IconData)>[
      ('用户设置', Icons.person_outline_rounded),
      ('OAS设置', Icons.hub_outlined),
      ('系统设置', Icons.tune_rounded),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: index == 0 ? colors.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(OasxRadius.xs),
                  border: Border.all(
                    color: index == 0
                        ? colors.accent.withValues(alpha: 0.30)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[index].$2,
                      size: 15,
                      color: index == 0
                          ? colors.accent
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        items[index].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: index == 0
                                  ? colors.accent
                                  : colors.textSecondary,
                              fontWeight: index == 0
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsNavPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return SizedBox(
      width: 228,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(OasxRadius.md),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(OasxSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                OasxSpace.sm,
                OasxSpace.xs,
                OasxSpace.sm,
                OasxSpace.sm + 2,
              ),
              child: OasxMicroLabel('设置'),
            ),
            _navItem(context, '用户设置', Icons.person_outline_rounded, true),
            _navItem(context, 'OAS设置', Icons.hub_outlined, false),
            _navItem(context, '系统设置', Icons.tune_rounded, false),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String label,
    IconData icon,
    bool selected,
  ) {
    final colors = OasxColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: OasxSpace.xxs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: OasxSpace.sm + 2,
          vertical: OasxSpace.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(OasxRadius.sm),
          border: Border.all(
            color: selected
                ? colors.accent.withValues(alpha: 0.30)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? colors.accent : colors.textSecondary,
            ),
            const SizedBox(width: OasxSpace.sm + 2),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? colors.accent : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
