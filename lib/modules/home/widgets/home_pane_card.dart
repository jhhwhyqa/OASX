import 'package:flutter/material.dart';

import 'package:oasx/modules/common/widgets/oasx_panel.dart';

/// Lightweight panel shell shared by the home workbench panes.
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
    return OasxPanel(padding: padding, child: child);
  }
}
