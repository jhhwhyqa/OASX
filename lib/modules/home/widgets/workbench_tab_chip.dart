import 'package:flutter/material.dart';

/// Compact tab chip shared by the workbench pane and right sidebar.
class WorkbenchTabChip extends StatelessWidget {
  const WorkbenchTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ChoiceChip(
      label: Text(label),
      showCheckmark: false,
      selected: selected,
      onSelected: (_) => onSelected(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      selectedColor: scheme.secondaryContainer,
      side: BorderSide(
        color: selected
            ? scheme.secondary.withValues(alpha: 0.35)
            : scheme.outlineVariant.withValues(alpha: 0.7),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }
}
