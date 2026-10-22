import 'package:flutter/material.dart';

/// Lightweight card shell shared by the home workbench panes.
///
/// Keeps the console look consistent: flat surface, thin outline and a single
/// consistent corner radius instead of stacked shadows.
class HomePaneCard extends StatelessWidget {
  const HomePaneCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
