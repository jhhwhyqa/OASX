import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';

void main() {
  late ArgsController controller;

  setUp(() {
    Get.testMode = true;
    controller = Get.put<ArgsController>(ArgsController());
    controller.groupsName.value = <String>['group_a', 'group_b'];
    controller.groupsData.value = <String, GroupsModel>{
      'group_a': _group('group_a', 'field_a'),
      'group_b': _group('group_b', 'field_b'),
    };
    controller.selectedGroup.value = 'group_a';
  });

  tearDown(() {
    Get.reset();
  });

  test('selectGroup only accepts loaded groups', () {
    controller.selectGroup('group_b');
    expect(controller.selectedGroup.value, 'group_b');

    controller.selectGroup('missing');
    expect(controller.selectedGroup.value, 'group_b');
  });

  test('jumpToFirstErrorGroup selects the first invalid group', () {
    controller.fieldErrors['group_b::field_b'] = 'invalid';

    controller.jumpToFirstErrorGroup();

    expect(controller.selectedGroup.value, 'group_b');
  });

  test('group markers reflect dirty and error keys', () {
    controller.dirtyFieldKeys.add('group_a::field_a');
    expect(controller.groupHasDirty('group_a'), isTrue);
    expect(controller.groupHasError('group_a'), isFalse);

    controller.fieldErrors['group_a::field_a'] = 'invalid';
    expect(controller.groupHasError('group_a'), isTrue);
    expect(controller.groupHasError('group_b'), isFalse);
  });

  testWidgets('pager renders only the selected group and switches chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildArgs());

    expect(find.text('field_a'), findsOneWidget);
    expect(find.text('field_b'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'group_b'));
    await tester.pump();

    expect(find.text('field_a'), findsNothing);
    expect(find.text('field_b'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'group_b'))
          .selected,
      isTrue,
    );
  });

  testWidgets('pager shows dirty and error markers on group chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildArgs());

    controller.dirtyFieldKeys.add('group_b::field_b');
    await tester.pump();
    expect(find.text('group_b ●'), findsOneWidget);

    controller.fieldErrors['group_b::field_b'] = 'invalid';
    await tester.pump();
    expect(find.text('group_b ⚠'), findsOneWidget);
    expect(find.text('group_b ●'), findsNothing);
  });

  testWidgets('non-pager mode does not render group chips', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildArgs(groupPager: false));

    expect(find.byType(ChoiceChip), findsNothing);
  });
}

Widget _buildArgs({bool groupPager = true}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 600,
        child: Args(
          scriptName: 'script',
          taskName: 'task',
          groupPager: groupPager,
          groupDraggable: false,
        ),
      ),
    ),
  );
}

GroupsModel _group(String groupName, String fieldName) {
  return GroupsModel(
    groupName: groupName,
    members: <dynamic>[
      ArgumentModel(
        const <String>[],
        null,
        null,
        null,
        null,
        title: fieldName,
        value: 'value',
        type: 'string',
      ),
    ],
  );
}
