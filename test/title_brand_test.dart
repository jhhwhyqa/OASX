import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/common/widgets/title.dart';
import 'package:oasx/translation/i18n.dart';
import 'package:oasx/utils/platform_utils.dart';

void main() {
  testWidgets('brand mark is hidden when the desktop rail shows it', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: Messages(),
        locale: const Locale('zh', 'CN'),
        fallbackLocale: const Locale('en', 'US'),
        home: Builder(
          builder: (context) => Scaffold(
            body: getTitle(context, routePath: '/home'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final expectsMark = !PlatformUtils.usesDesktopLayout;
    expect(
      find.byType(Image),
      expectsMark ? findsOneWidget : findsNothing,
    );
  });
}
