import 'package:flutter_test/flutter_test.dart';
import 'package:oasx/service/script_order.dart';

void main() {
  group('mergeScriptOrder', () {
    test('keeps the preferred order and appends new names', () {
      expect(
        mergeScriptOrder(
          preferredOrder: ['b', 'a'],
          availableNames: ['a', 'b', 'c'],
        ),
        ['b', 'a', 'c'],
      );
    });

    test('drops names that no longer exist', () {
      expect(
        mergeScriptOrder(
          preferredOrder: ['b', 'removed', 'a'],
          availableNames: ['a', 'b'],
        ),
        ['b', 'a'],
      );
    });

    test('deduplicates names', () {
      expect(
        mergeScriptOrder(
          preferredOrder: ['a', 'a', 'b'],
          availableNames: ['a', 'b', 'b'],
        ),
        ['a', 'b'],
      );
    });
  });

  group('applyVisibleOrderToFullOrder', () {
    test('reorders visible items while keeping hidden slots', () {
      expect(
        applyVisibleOrderToFullOrder(
          fullOrder: ['a', 'hidden1', 'b', 'hidden2', 'c'],
          visibleOrder: ['c', 'a', 'b'],
        ),
        ['c', 'hidden1', 'a', 'hidden2', 'b'],
      );
    });

    test('returns the original order when visible names do not match', () {
      final fullOrder = ['a', 'b'];
      expect(
        applyVisibleOrderToFullOrder(
          fullOrder: fullOrder,
          visibleOrder: ['c'],
        ),
        fullOrder,
      );
    });
  });
}
