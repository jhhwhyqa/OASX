import 'package:flutter/material.dart';

/// Compact icon action for bulk quick scheduling.
class BulkQuickScheduleButton extends StatelessWidget {
  const BulkQuickScheduleButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.loading,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      padding: EdgeInsets.zero,
      iconSize: 19,
      style: IconButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
      ),
      icon: loading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            )
          : Icon(icon),
    );
  }
}
