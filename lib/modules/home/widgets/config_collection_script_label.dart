import 'package:flutter/material.dart';
import 'package:oasx/modules/home/models/config_model.dart';

/// Shows the config name for one collection tile.
class ConfigCollectionScriptLabel extends StatelessWidget {
  /// Creates the primary script label.
  const ConfigCollectionScriptLabel({
    super.key,
    required this.script,
    required this.centered,
    this.selected = false,
  });

  /// Script displayed by the collection tile.
  final ScriptModel script;

  /// Whether the label should center its contents.
  final bool centered;

  /// Whether this script is the active workbench config.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      script.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: selected ? theme.colorScheme.primary : null,
      ),
    );
  }
}
