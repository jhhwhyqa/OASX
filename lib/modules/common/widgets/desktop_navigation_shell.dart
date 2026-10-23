import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design_system.dart';
import 'package:oasx/config/global.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/common/widgets/oasx_backdrop.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/home_binding.dart';
import 'package:oasx/modules/home/index.dart';
import 'package:oasx/modules/server/controllers/server_controller.dart';
import 'package:oasx/modules/server/server_view.dart';
import 'package:oasx/modules/settings/index.dart';
import 'package:oasx/service/theme_service.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

/// Desktop shell with a persistent left navigation rail.
///
/// Pages are kept alive in an [IndexedStack] so switching destinations keeps
/// scroll positions, log viewports and form focus intact.
class DesktopNavigationShell extends StatefulWidget {
  const DesktopNavigationShell({
    super.key,
    required this.initialRoutePath,
  });

  final String initialRoutePath;

  @override
  State<DesktopNavigationShell> createState() => _DesktopNavigationShellState();
}

class _DesktopNavigationShellState extends State<DesktopNavigationShell> {
  late String _routePath;
  late final Set<int> _builtIndexes;

  List<OasxShellDestination> get _destinations {
    return [
      OasxShellDestination(
        routePath: '/home',
        label: I18n.home.tr,
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
      ),
      if (!PlatformUtils.isWeb)
        OasxShellDestination(
          routePath: '/server',
          label: I18n.setupDeploy.tr,
          icon: Icons.dns_outlined,
          selectedIcon: Icons.dns_rounded,
        ),
      OasxShellDestination(
        routePath: '/settings',
        label: I18n.setting.tr,
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune_rounded,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _routePath = _normalizeRoutePath(widget.initialRoutePath);
    _builtIndexes = <int>{_indexForRoute(_routePath)};
    _ensureBindings(_indexForRoute(_routePath));
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations;
    final selectedIndex = _indexForRoute(_routePath).clamp(
      0,
      destinations.length - 1,
    );
    final content = OasxBackdrop(
      child: IndexedStack(
        index: selectedIndex,
        children: List<Widget>.generate(destinations.length, (index) {
          if (!_builtIndexes.contains(index)) {
            return const SizedBox.shrink();
          }
          return _pageFor(destinations[index].routePath);
        }),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final useBottomNavigation = PlatformUtils.isWeb && width < 640;
        final compactRail = PlatformUtils.isWeb
            ? width < 900
            : width < 760;
        return Scaffold(
          appBar: buildPlatformAppBar(context, routePath: _routePath),
          body: useBottomNavigation
              ? content
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OasxDesktopNavigationRail(
                      destinations: destinations,
                      selectedIndex: selectedIndex,
                      onSelected: _handleDestinationSelected,
                      compact: compactRail,
                    ),
                    Expanded(child: content),
                  ],
                ),
          bottomNavigationBar: useBottomNavigation
              ? NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: _handleDestinationSelected,
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                )
              : null,
        );
      },
    );
  }

  Widget _pageFor(String routePath) {
    return switch (routePath) {
      '/settings' => const SettingsView(standalone: false),
      '/server' => const ServerView(standalone: false),
      _ => const HomeView(standalone: false),
    };
  }

  String _normalizeRoutePath(String value) {
    return switch (value) {
      '/settings' => '/settings',
      '/server' => '/server',
      _ => '/home',
    };
  }

  int _indexForRoute(String value) {
    final index = _destinations.indexWhere(
      (destination) => destination.routePath == _normalizeRoutePath(value),
    );
    return index < 0 ? 0 : index;
  }

  void _handleDestinationSelected(int index) {
    final destinations = _destinations;
    if (index < 0 || index >= destinations.length) {
      return;
    }
    final nextRoutePath = destinations[index].routePath;
    if (nextRoutePath == _routePath) {
      return;
    }
    final previousRoutePath = _routePath;
    _ensureBindings(index);
    setState(() {
      _routePath = nextRoutePath;
      _builtIndexes.add(index);
    });
    if (previousRoutePath == '/settings' && nextRoutePath != '/settings') {
      handleSettingsLeaveEffect();
    }
  }

  void _ensureBindings(int index) {
    final routePath = _destinations[index].routePath;
    if (routePath == '/home' && !Get.isRegistered<HomeDashboardController>()) {
      HomeBinding().dependencies();
    }
    if (routePath == '/server' && !Get.isRegistered<ServerController>()) {
      Get.put<ServerController>(ServerController());
    }
  }
}

class OasxShellDestination {
  const OasxShellDestination({
    required this.routePath,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String routePath;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class OasxDesktopNavigationRail extends StatelessWidget {
  const OasxDesktopNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.showFooter = true,
    this.compact = false,
  });

  final List<OasxShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Shows the theme toggle and version at the bottom.
  final bool showFooter;

  /// Icons-only rail used when the window is too narrow for labels.
  final bool compact;

  static const double width = 76;
  static const double compactWidth = 56;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return Container(
      width: compact ? compactWidth : width,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(right: BorderSide(color: colors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: OasxSpace.sm),
          _buildBrand(context),
          const SizedBox(height: OasxSpace.md),
          for (var index = 0; index < destinations.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: OasxSpace.xxs),
              child: _RailItem(
                destination: destinations[index],
                selected: index == selectedIndex,
                compact: compact,
                onTap: () => onSelected(index),
              ),
            ),
          const Spacer(),
          if (showFooter) ...[
            _buildThemeToggle(context),
            const SizedBox(height: OasxSpace.xs),
            if (!compact && GlobalVar.version.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: OasxSpace.sm),
                child: Text(
                  'v${GlobalVar.version}',
                  style: OasxText.mono(
                    context,
                    size: 9.5,
                    color: colors.textTertiary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBrand(BuildContext context) {
    final colors = OasxColors.of(context);
    final size = compact ? 32.0 : 40.0;
    return Tooltip(
      message: 'OASX',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(OasxRadius.md),
          border: Border.all(color: colors.borderStrong),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/Icon-app.png',
          fit: BoxFit.cover,
          semanticLabel: 'OASX',
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final themeService = Get.find<ThemeService>();
    return Obx(() {
      final isDark = themeService.isDarkMode;
      return Tooltip(
        message: I18n.changeTheme.tr,
        child: IconButton(
          onPressed: themeService.switchTheme,
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 19,
          ),
        ),
      );
    });
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final OasxShellDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    final foreground = selected ? colors.accent : colors.textSecondary;
    return Tooltip(
      message: destination.label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        selected: selected,
        label: destination.label,
        excludeSemantics: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: OasxSpace.sm),
          decoration: BoxDecoration(
            color: selected ? colors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(OasxRadius.sm),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.32)
                  : Colors.transparent,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(OasxRadius.sm),
              hoverColor: colors.surfaceRaised,
              focusColor: colors.accentSoft,
              mouseCursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: OasxSpace.sm),
                child: Column(
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 21,
                      color: foreground,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: OasxSpace.xs),
                      Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          letterSpacing: 0.2,
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
