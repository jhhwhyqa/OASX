import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Right console column: independently scrolling statistics and extensions.
class ConsoleStatsPane extends StatelessWidget {
  const ConsoleStatsPane({
    super.key,
    required this.scriptName,
    this.onCollapse,
  });

  final String scriptName;

  /// Folds the statistics column back into its rail.
  final VoidCallback? onCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasScript = scriptName.trim().isNotEmpty;
    return HomePaneCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onCollapse,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 5, 6, 5),
                child: Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      I18n.homeStatsTab.tr,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasScript)
                      Expanded(
                        child: Text(
                          scriptName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (onCollapse != null)
                      IconButton(
                        tooltip: I18n.homeConsoleCollapseStats.tr,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onCollapse,
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          Expanded(
            child: hasScript
                ? const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ScriptStatisticsPanel(scrollable: false),
                        // Future console modules can be appended here. Each
                        // module should render only values backed by real data
                        // sources.
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      I18n.homeNoScriptSelected.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Collapsed statistics column that expands on click.
///
/// The pane stays folded by default so no statistics transport is opened
/// until the user explicitly asks for it.
class ConsoleStatsRail extends StatelessWidget {
  const ConsoleStatsRail({super.key, required this.onExpand});

  /// Expands the statistics column and starts its binding.
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: I18n.homeStatsTab.tr,
      child: Semantics(
        button: true,
        label: I18n.homeStatsTab.tr,
        child: HomePaneCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onExpand,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
