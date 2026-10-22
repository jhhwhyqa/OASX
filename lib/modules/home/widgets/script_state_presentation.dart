import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/config/theme.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Shared labels, icons and semantic colors for script collection states.
extension HomeScriptStatePresentation on HomeScriptStateFilter {
  /// Localized label used by the state filter menu.
  String get filterLabel {
    return switch (this) {
      HomeScriptStateFilter.all => I18n.selectAll.tr,
      HomeScriptStateFilter.running => I18n.trayRunningConfigs.tr,
      HomeScriptStateFilter.stopped => I18n.trayStoppedConfigs.tr,
      HomeScriptStateFilter.abnormal => I18n.homeScriptAbnormal.tr,
      HomeScriptStateFilter.offline => I18n.homeScriptOffline.tr,
    };
  }

  /// Short label for a status badge; [all] has no visible badge.
  String? get statusLabel {
    return this == HomeScriptStateFilter.all ? null : filterLabel;
  }

  /// Semantic color that stays legible on light and dark surfaces.
  Color color(BuildContext context) {
    final colors = OasxStateColors.of(context);
    return switch (this) {
      HomeScriptStateFilter.all => Theme.of(context).colorScheme.outline,
      HomeScriptStateFilter.running => colors.running,
      HomeScriptStateFilter.stopped => colors.stopped,
      HomeScriptStateFilter.abnormal => colors.abnormal,
      HomeScriptStateFilter.offline => colors.offline,
    };
  }

  /// Icon used by the compact state indicator.
  IconData get indicatorIcon {
    return switch (this) {
      HomeScriptStateFilter.all => Icons.circle_outlined,
      HomeScriptStateFilter.running => Icons.circle_rounded,
      HomeScriptStateFilter.stopped => Icons.donut_large_rounded,
      HomeScriptStateFilter.abnormal => Icons.warning_amber_rounded,
      HomeScriptStateFilter.offline => Icons.cloud_off_rounded,
    };
  }
}

/// Rounded status label rendered next to a script name.
class ScriptStateBadge extends StatelessWidget {
  const ScriptStateBadge({super.key, required this.state});

  final HomeScriptStateFilter state;

  @override
  Widget build(BuildContext context) {
    final label = state.statusLabel;
    if (label == null) {
      return const SizedBox.shrink();
    }
    final color = state.color(context);
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
