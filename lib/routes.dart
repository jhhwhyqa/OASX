import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/modules/common/widgets/desktop_navigation_shell.dart';
import 'package:oasx/modules/common/widgets/primary_navigation_shell.dart';
import 'package:oasx/modules/home/home_binding.dart';
import 'package:oasx/modules/server/index.dart';
import 'package:oasx/utils/platform_utils.dart';

class Routes {
  static const initial = '/home';

  static final routes = [
    GetPage(
      name: '/home',
      page: () => _buildPrimaryPage('/home'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/settings',
      page: () => _buildPrimaryPage('/settings'),
      binding: HomeBinding(),
    ),
    GetPage(
      name: '/server',
      page: () => _buildPrimaryPage('/server'),
      binding: BindingsBuilder(() {
        Get.put<ServerController>(ServerController());
      }),
    ),
  ];

  static Widget _buildPrimaryPage(String routePath) {
    if (PlatformUtils.usesDesktopLayout) {
      return DesktopNavigationShell(initialRoutePath: routePath);
    }
    return switch (routePath) {
      '/server' => const ServerView(),
      _ => PrimaryNavigationShell(initialRoutePath: routePath),
    };
  }
}
