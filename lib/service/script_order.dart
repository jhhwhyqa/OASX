/// Pure helpers for merging and reordering config collections.
library;

/// Merges a preferred order with the names currently available on the server.
///
/// Names present in [preferredOrder] keep their relative order and are placed
/// first. Names that only exist in [availableNames] are appended in server
/// order. Stale names and duplicates are removed.
List<String> mergeScriptOrder({
  required Iterable<String> preferredOrder,
  required Iterable<String> availableNames,
}) {
  final available = <String>{};
  for (final name in availableNames) {
    final normalized = name.trim();
    if (normalized.isNotEmpty) {
      available.add(normalized);
    }
  }
  final result = <String>[];
  final seen = <String>{};
  for (final name in preferredOrder) {
    final normalized = name.trim();
    if (available.contains(normalized) && seen.add(normalized)) {
      result.add(normalized);
    }
  }
  for (final name in available) {
    if (seen.add(name)) {
      result.add(name);
    }
  }
  return result;
}

/// Applies a reordered visible subset back onto the full config order.
///
/// Hidden names keep their original slots. Returns [fullOrder] unchanged when
/// [visibleOrder] does not contain exactly the visible names from [fullOrder].
List<String> applyVisibleOrderToFullOrder({
  required List<String> fullOrder,
  required List<String> visibleOrder,
}) {
  if (visibleOrder.isEmpty) {
    return List<String>.from(fullOrder);
  }
  final visibleSet = visibleOrder.toSet();
  final result = List<String>.from(fullOrder);
  var cursor = 0;
  for (var index = 0; index < result.length; index++) {
    if (visibleSet.contains(result[index])) {
      result[index] = visibleOrder[cursor++];
    }
  }
  if (cursor != visibleOrder.length) {
    return List<String>.from(fullOrder);
  }
  return result;
}
