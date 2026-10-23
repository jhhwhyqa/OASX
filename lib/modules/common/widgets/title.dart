import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/server/index.dart';
import 'package:oasx/translation/i18n_content.dart';
import 'package:oasx/utils/platform_utils.dart';

Widget getTitle(BuildContext context, {String? routePath}) {
  final resolvedRoutePath = _resolveRoutePath(context, routePath: routePath);
  return switch (resolvedRoutePath) {
    '/settings' => const SettingTitle(),
    '/server' => const ServerTitle(),
    _ => const HomeTitleBar(),
  };
}

String _resolveRoutePath(BuildContext context, {String? routePath}) {
  final explicitRoute = routePath?.trim() ?? '';
  if (explicitRoute.isNotEmpty) {
    return explicitRoute;
  }

  final routingCurrent = Get.routing.current;
  if (routingCurrent.isNotEmpty) {
    return routingCurrent;
  }

  final routeName = ModalRoute.of(context)?.settings.name;
  if (routeName != null && routeName.isNotEmpty) {
    return routeName;
  }
  return Get.currentRoute;
}

class HomeTitleBar extends StatelessWidget {
  const HomeTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BrandMark(),
          Flexible(child: _TitleLabel(text: 'OASX / ${I18n.home.tr}')),
        ],
      ),
    );
  }
}

class SettingTitle extends StatelessWidget {
  const SettingTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final backButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (backButton) ...[
            BackButton(onPressed: _backHomeOrPop),
            const SizedBox(width: 8),
          ],
          const _BrandMark(),
          Flexible(child: _TitleLabel(text: 'OASX / ${I18n.setting.tr}')),
        ],
      ),
    );
  }

  void _backHomeOrPop() {
    final canPop = Get.key.currentState?.canPop() ?? false;
    if (canPop || Get.previousRoute.isNotEmpty) {
      Get.back();
      return;
    }
    Get.offAllNamed('/home');
  }
}

class ServerTitle extends StatelessWidget {
  const ServerTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final backButton = switch (Theme.of(context).platform) {
      TargetPlatform.android => false,
      TargetPlatform.iOS => false,
      _ => true,
    };
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (backButton &&
                !Get.find<ServerController>().isDeployLoading.value) {
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [BackButton(), SizedBox(width: 8)],
              );
            }
            return const SizedBox.shrink();
          }),
          const _BrandMark(),
          const Flexible(child: _TitleLabel(text: 'OASX / Server')),
        ],
      ),
    );
  }
}

/// App mark shown in the title bar on layouts without the global rail.
///
/// Desktop and web already render the mark at the top of the navigation rail,
/// so the title bar would otherwise show the same icon twice.
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    // Desktop/web layouts with the rail already show the mark there. Narrow
    // web falls back to the bottom bar, so the title bar must carry it.
    final showMark = !PlatformUtils.usesDesktopLayout ||
        (PlatformUtils.isWeb && MediaQuery.sizeOf(context).width < 640);
    if (!showMark) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Image.asset(
        'assets/images/Icon-app.png',
        height: 30,
        width: 30,
      ),
    );
  }
}

class _TitleLabel extends StatelessWidget {
  const _TitleLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}
