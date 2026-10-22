import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Right console column: independently scrolling statistics and extensions.
class ConsoleStatsPane extends StatelessWidget {
  const ConsoleStatsPane({super.key, required this.scriptName});

  final String scriptName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return HomePaneCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
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
                if (scriptName.trim().isNotEmpty)
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
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          const Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScriptStatisticsPanel(scrollable: false),
                  // Future console modules can be appended here. Each module
                  // should render only values backed by real data sources.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
