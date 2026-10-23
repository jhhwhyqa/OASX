import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design_system.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/common/widgets/oasx_backdrop.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
import 'package:oasx/modules/settings/oas_card.dart';
import 'package:oasx/modules/settings/settings_leave_handler.dart';
import 'package:oasx/modules/settings/system_card.dart';
import 'package:oasx/modules/settings/user_card.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
    this.standalone = true,
  });

  final bool standalone;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static const double _layoutSpacing = 12.0;
  static const double _wideLayoutBreakpoint = 1000.0;
  static const double _navWidth = 228.0;
  static const double _topAlignmentTolerance = 12.0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  late final List<_SettingsSection> _sections = [
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => I18n.userSetting.tr,
      icon: Icons.person_outline_rounded,
      cardBuilder: () => const UserSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => 'OAS${I18n.setting.tr}',
      icon: Icons.hub_outlined,
      cardBuilder: () => const OasSettingsCard(),
    ),
    _SettingsSection(
      key: GlobalKey(),
      navTitleBuilder: () => I18n.systemSetting.tr,
      icon: Icons.tune_rounded,
      cardBuilder: () => const SystemSettingsCard(),
    ),
  ];

  int? _selectedSectionIndex;
  bool _isAutoScrolling = false;
  bool _lockSelectionToClickedNav = false;
  bool _hasHandledLeave = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncSelectedSectionByViewport();
    });
  }

  @override
  void dispose() {
    _handleLeaveSettings();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final body = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideLayoutBreakpoint;
          final settingList = _buildSettingList(keyboardInset);

          if (!isWide) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                OasxSpace.lg,
                OasxSpace.lg,
                OasxSpace.lg,
                0,
              ),
              child: Column(
                children: [
                  _buildSectionTabs(),
                  const SizedBox(height: _layoutSpacing),
                  Expanded(child: settingList),
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPrimaryNav(),
              const SizedBox(width: _layoutSpacing),
              Expanded(child: settingList),
            ],
          ).paddingOnly(
            left: OasxSpace.lg,
            right: OasxSpace.lg,
            top: OasxSpace.lg,
          );
        },
      ),
    );
    if (!widget.standalone) {
      return body;
    }
    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/settings'),
      body: OasxBackdrop(child: body),
    );
  }

  void _handleLeaveSettings() {
    if (_hasHandledLeave) {
      return;
    }
    _hasHandledLeave = true;
    unawaited(handleSettingsLeaveEffect());
  }

  void _handleScroll() {
    if (_isAutoScrolling || _lockSelectionToClickedNav || !mounted) {
      return;
    }
    _syncSelectedSectionByViewport();
  }

  void _syncSelectedSectionByViewport() {
    final sectionIndex = _findCurrentSectionIndex();
    if (sectionIndex == _selectedSectionIndex) {
      return;
    }
    setState(() => _selectedSectionIndex = sectionIndex);
  }

  int? _findCurrentSectionIndex() {
    final viewportContext = _scrollViewKey.currentContext;
    if (viewportContext == null) {
      return _selectedSectionIndex;
    }

    final viewportRenderObject = viewportContext.findRenderObject();
    if (viewportRenderObject is! RenderBox || !viewportRenderObject.hasSize) {
      return _selectedSectionIndex;
    }

    final viewportTop = viewportRenderObject.localToGlobal(Offset.zero).dy;
    int? passedTopSectionIndex;
    int? upcomingSectionIndex;
    var nearestUpcomingTop = double.infinity;

    for (var index = 0; index < _sections.length; index++) {
      final sectionContext = _sections[index].key.currentContext;
      if (sectionContext == null) {
        continue;
      }
      final sectionRenderObject = sectionContext.findRenderObject();
      if (sectionRenderObject is! RenderBox || !sectionRenderObject.hasSize) {
        continue;
      }

      final sectionTop =
          sectionRenderObject.localToGlobal(Offset.zero).dy - viewportTop;
      if (sectionTop <= _topAlignmentTolerance) {
        passedTopSectionIndex = index;
        continue;
      }
      if (sectionTop < nearestUpcomingTop) {
        nearestUpcomingTop = sectionTop;
        upcomingSectionIndex = index;
      }
    }

    return passedTopSectionIndex ??
        upcomingSectionIndex ??
        _selectedSectionIndex;
  }

  Future<void> _scrollToSection(int index) async {
    if (index < 0 || index >= _sections.length) {
      return;
    }

    final targetContext = _sections[index].key.currentContext;
    if (targetContext == null) {
      return;
    }

    setState(() {
      _selectedSectionIndex = index;
      _lockSelectionToClickedNav = true;
    });

    _isAutoScrolling = true;
    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutCubic,
      alignment: 0,
    );
    _isAutoScrolling = false;
  }

  Widget _buildSettingList(double keyboardInset) {
    return Scrollbar(
      controller: _scrollController,
      child: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (_isAutoScrolling || !mounted) {
            return false;
          }
          if (notification.direction != ScrollDirection.idle &&
              _lockSelectionToClickedNav) {
            setState(() => _lockSelectionToClickedNav = false);
          }
          return false;
        },
        child: SingleChildScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          keyboardDismissBehavior: PlatformUtils.isWeb
              ? ScrollViewKeyboardDismissBehavior.manual
              : ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: keyboardInset > 0 ? keyboardInset + 24 : 0,
          ),
          child: Column(
            children: _sections
                .map(
                  (section) => Container(
                    key: section.key,
                    margin: const EdgeInsets.only(bottom: _layoutSpacing),
                    child: section.cardBuilder(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  /// Horizontal section switch used below the vertical-nav breakpoint.
  Widget _buildSectionTabs() {
    final colors = OasxColors.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _sections.length; index++)
            Expanded(child: _buildSectionTab(index)),
        ],
      ),
    );
  }

  Widget _buildSectionTab(int index) {
    final colors = OasxColors.of(context);
    final section = _sections[index];
    final isSelected = index == _selectedSectionIndex;
    return Semantics(
      button: true,
      selected: isSelected,
      label: section.navTitleBuilder(),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isSelected ? colors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(OasxRadius.xs),
          border: Border.all(
            color: isSelected
                ? colors.accent.withValues(alpha: 0.30)
                : Colors.transparent,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(OasxRadius.xs),
            onTap: () => _scrollToSection(index),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  section.icon,
                  size: 15,
                  color: isSelected ? colors.accent : colors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    section.navTitleBuilder(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? colors.accent
                          : colors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryNav() {
    final colors = OasxColors.of(context);
    return SizedBox(
      width: _navWidth,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(OasxRadius.md),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.all(OasxSpace.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                OasxSpace.sm,
                OasxSpace.xs,
                OasxSpace.sm,
                OasxSpace.sm + 2,
              ),
              child: OasxMicroLabel(I18n.setting.tr),
            ),
            for (var index = 0; index < _sections.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: OasxSpace.xxs),
                child: _buildNavItem(index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final colors = OasxColors.of(context);
    final section = _sections[index];
    final isSelected = index == _selectedSectionIndex;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(OasxRadius.sm),
        hoverColor: colors.surfaceRaised,
        onTap: () => _scrollToSection(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: OasxSpace.sm + 2,
            vertical: OasxSpace.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OasxRadius.sm),
            color: isSelected ? colors.accentSoft : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? colors.accent.withValues(alpha: 0.30)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 17,
                color: isSelected ? colors.accent : colors.textSecondary,
              ),
              const SizedBox(width: OasxSpace.sm + 2),
              Expanded(
                child: Text(
                  section.navTitleBuilder(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? colors.accent
                        : colors.textSecondary,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(OasxRadius.pill),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection {
  _SettingsSection({
    required this.key,
    required this.navTitleBuilder,
    required this.icon,
    required this.cardBuilder,
  });

  final GlobalKey key;
  final String Function() navTitleBuilder;
  final IconData icon;
  final Widget Function() cardBuilder;
}
