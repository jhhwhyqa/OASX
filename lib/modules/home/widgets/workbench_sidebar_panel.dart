import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/models/home_workbench_layout.dart';
import 'package:oasx/modules/home/widgets/home_pane_card.dart';
import 'package:oasx/modules/home/widgets/log_center_panel.dart';
import 'package:oasx/modules/home/widgets/statistics_panel.dart';
import 'package:oasx/modules/home/widgets/workbench_tab_chip.dart';
import 'package:oasx/translation/i18n_content.dart';

/// Hosts the desktop right sidebar for statistics and logs.
class WorkbenchSidebarPanel extends StatelessWidget {
  /// Creates the right workbench sidebar.
  const WorkbenchSidebarPanel({
    super.key,
    required this.controller,
    required this.scriptName,
  });

  /// Dashboard controller that owns sidebar tab state.
  final HomeDashboardController controller;

  /// Active script rendered by the sidebar.
  final String scriptName;

  @override
  Widget build(BuildContext context) {
    return HomePaneCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Obx(() {
        final tabs = controller.workbenchSidebarTabsFor(
          HomeWorkbenchLayoutMode.threePane,
        );
        final currentTab = controller.displayedWorkbenchSidebarTabFor(
          HomeWorkbenchLayoutMode.threePane,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: tabs
                  .map(
                    (tab) => WorkbenchTabChip(
                      label: _tabLabel(tab),
                      selected: currentTab == tab,
                      onSelected: () =>
                          controller.setActiveWorkbenchSidebarTabValue(tab),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (currentTab) {
                HomeWorkbenchTab.stats => const ScriptStatisticsPanel(),
                HomeWorkbenchTab.logs => LogCenterPanel(scriptName: scriptName),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        );
      }),
    );
  }

  /// Resolves a localized label for one sidebar tab.
  String _tabLabel(HomeWorkbenchTab value) {
    return switch (value) {
      HomeWorkbenchTab.stats => I18n.homeStatsTab.tr,
      HomeWorkbenchTab.logs => I18n.log.tr,
      _ => '',
    };
  }
}
