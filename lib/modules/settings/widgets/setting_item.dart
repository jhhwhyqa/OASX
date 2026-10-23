import 'package:flutter/material.dart';

import 'package:oasx/config/design_system.dart';

class SettingItem extends StatelessWidget {
  final Widget left;
  final Widget right;
  final VoidCallback? onTap;

  const SettingItem({
    super.key,
    required this.left,
    required this.right,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OasxSpace.sm,
        vertical: OasxSpace.xs + 3,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: colors.textPrimary,
                ),
                child: left,
              ),
            ),
            const SizedBox(width: OasxSpace.md),
            right,
          ],
        ),
      ),
    );
    if (onTap == null) {
      return row;
    }
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OasxRadius.xs),
        hoverColor: colors.surfaceRaised,
        child: row,
      ),
    );
  }
}
