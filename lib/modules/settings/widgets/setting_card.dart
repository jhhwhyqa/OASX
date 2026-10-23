import 'package:flutter/material.dart';

import 'package:oasx/config/design_system.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
import 'package:oasx/modules/settings/widgets/setting_item.dart';

class SettingCard extends StatelessWidget {
  final String title;
  final List<SettingItem> items;
  final IconData icon;

  const SettingCard({
    super.key,
    required this.title,
    required this.items,
    this.icon = Icons.tune_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return OasxPanel(
      fill: false,
      padding: EdgeInsets.zero,
      header: Row(
        children: [
          OasxIconTile(icon: icon, size: 30),
          const SizedBox(width: OasxSpace.sm + 2),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        OasxSpace.sm,
        OasxSpace.xs,
        OasxSpace.sm,
        OasxSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                indent: OasxSpace.sm,
                endIndent: OasxSpace.sm,
                color: colors.border.withValues(alpha: 0.7),
              ),
            items[index],
          ],
        ],
      ),
    );
  }
}
