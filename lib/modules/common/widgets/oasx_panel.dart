import 'package:flutter/material.dart';

import 'package:oasx/config/design_system.dart';

/// Flat console surface: one hairline, one radius, no elevation.
///
/// Use it for modules that need a boundary (log, tasks, statistics, deploy
/// sections). Plain content groups should use spacing and dividers instead of
/// wrapping everything in another panel.
class OasxPanel extends StatelessWidget {
  const OasxPanel({
    super.key,
    required this.child,
    this.title,
    this.header,
    this.titleTrailing,
    this.padding = const EdgeInsets.all(OasxSpace.md),
    this.contentPadding = EdgeInsets.zero,
    this.active = false,
    this.dense = false,
    this.fill = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;

  /// Optional micro header rendered above a hairline divider.
  final String? title;

  /// Optional custom header widget, used for larger section titles.
  final Widget? header;

  /// Optional trailing widget for the header row.
  final Widget? titleTrailing;

  /// Outer padding around header and content.
  final EdgeInsetsGeometry padding;

  /// Padding applied inside the content area.
  final EdgeInsetsGeometry contentPadding;

  /// Draws an accent border and left indicator for the focused module.
  final bool active;

  /// Tightens the header for rails and small modules.
  final bool dense;

  /// Whether content fills the remaining height.
  ///
  /// Keep this true inside a bounded column (console panes). Set it false when
  /// the panel should size itself to its content.
  final bool fill;

  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    final title = this.title;
    final header = this.header;
    final content = Padding(padding: contentPadding, child: child);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(OasxRadius.md),
        border: Border.all(
          color: active ? colors.accent.withValues(alpha: 0.55) : colors.border,
        ),
      ),
      clipBehavior: clipBehavior,
      // A transparent Material above the colored container keeps ink splashes
      // and ListTile backgrounds visible inside the panel.
      child: Material(
        type: MaterialType.transparency,
        child: title == null && header == null
            ? Padding(padding: padding, child: content)
            : Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        OasxSpace.md,
                        dense ? OasxSpace.xs + 2 : OasxSpace.sm,
                        OasxSpace.xs,
                        dense ? OasxSpace.xs + 2 : OasxSpace.sm,
                      ),
                      child: Row(
                        children: [
                          if (active) ...[
                            Container(
                              width: 3,
                              height: 11,
                              decoration: BoxDecoration(
                                color: colors.accent,
                                borderRadius: BorderRadius.circular(
                                  OasxRadius.pill,
                                ),
                              ),
                            ),
                            const SizedBox(width: OasxSpace.sm),
                          ],
                          Expanded(
                            child:
                                header ??
                                Text(
                                  title!.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: OasxText.micro(context),
                                ),
                          ),
                          if (titleTrailing != null) titleTrailing!,
                        ],
                      ),
                    ),
                    Divider(height: 1, color: colors.border),
                    if (fill) Expanded(child: content) else content,
                  ],
                ),
              ),
      ),
    );
  }
}

/// Small uppercase label for section headers and metadata.
class OasxMicroLabel extends StatelessWidget {
  const OasxMicroLabel(this.text, {super.key, this.color, this.trailing});

  final String text;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: OasxText.micro(context, color: color),
    );
    if (trailing == null) {
      return label;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        label,
        const SizedBox(width: OasxSpace.sm),
        trailing!,
      ],
    );
  }
}

/// Compact status badge: dot, optional icon and one short label.
class OasxStatusPill extends StatelessWidget {
  const OasxStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(OasxRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 10 : 12, color: color),
            const SizedBox(width: 4),
          ] else ...[
            Container(
              width: dense ? 5 : 6,
              height: dense ? 5 : 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Menu entry with an explicit check column.
///
/// Used instead of [CheckedPopupMenuItem], whose [ListTile] cannot sit under a
/// colored wrapper without losing its ink feedback.
PopupMenuItem<T> oasxCheckedPopupItem<T>({
  required T value,
  required bool checked,
  required String label,
}) {
  return PopupMenuItem<T>(
    value: value,
    child: Builder(
      builder: (context) {
        final colors = OasxColors.of(context);
        return Semantics(
          selected: checked,
          label: label,
          excludeSemantics: true,
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: checked
                    ? Icon(Icons.check_rounded, size: 16, color: colors.accent)
                    : null,
              ),
              const SizedBox(width: OasxSpace.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: checked ? colors.accent : colors.textPrimary,
                    fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Square icon container used in empty states and module headers.
class OasxIconTile extends StatelessWidget {
  const OasxIconTile({
    super.key,
    required this.icon,
    this.color,
    this.size = 34,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    final resolved = color ?? colors.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        border: Border.all(color: resolved.withValues(alpha: 0.24)),
      ),
      child: Icon(icon, size: size * 0.5, color: resolved),
    );
  }
}

/// Consistent empty/failure state with one primary recovery action.
class OasxEmptyState extends StatelessWidget {
  const OasxEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.title,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    final title = this.title;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: EdgeInsets.all(compact ? OasxSpace.md : OasxSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OasxIconTile(
                icon: icon,
                size: compact ? 32 : 40,
                color: colors.textTertiary,
              ),
              if (title != null) ...[
                const SizedBox(height: OasxSpace.md),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
              const SizedBox(height: OasxSpace.xs + 2),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: OasxSpace.md),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
