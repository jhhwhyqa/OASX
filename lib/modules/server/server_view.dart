import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:oasx/config/design_system.dart';
import 'package:oasx/modules/common/widgets/appbar.dart';
import 'package:oasx/modules/common/widgets/oasx_backdrop.dart';
import 'package:oasx/modules/common/widgets/oasx_panel.dart';
import 'package:oasx/modules/log/log_widget.dart';
import 'package:oasx/modules/server/controllers/server_controller.dart';
import 'package:oasx/modules/server/widgets/deploy_section_panel.dart';
import 'package:oasx/translation/i18n_content.dart';

class ServerView extends StatelessWidget {
  const ServerView({super.key, this.standalone = true});

  /// Whether this view owns its scaffold and platform app bar.
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final serverController = Get.find<ServerController>();
          final wide = constraints.maxWidth >= 1100;
          final logWidget = LogWidget(
            key: ValueKey(serverController.hashCode),
            controller: serverController,
            title: I18n.setupLog.tr,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              OasxSpace.lg,
              OasxSpace.lg,
              OasxSpace.lg,
              OasxSpace.lg,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _DeployHeader(),
                    const SizedBox(height: OasxSpace.md),
                    Expanded(
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  width: 460,
                                  child: SingleChildScrollView(
                                    child: DeploySectionPanel(
                                      maxHeight: math.max(
                                        220.0,
                                        constraints.maxHeight - 260,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: OasxSpace.md),
                                Expanded(child: logWidget),
                              ],
                            )
                          : _buildStacked(constraints, logWidget),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!standalone) {
      return body;
    }
    return Scaffold(
      appBar: buildPlatformAppBar(context, routePath: '/server'),
      body: OasxBackdrop(child: body),
    );
  }

  /// Stacked deploy workspace used below the two-column breakpoint.
  Widget _buildStacked(BoxConstraints constraints, Widget logWidget) {
    final logHeight = math.max(
      260.0,
      math.min(520.0, constraints.maxHeight * 0.45),
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeploySectionPanel(
            maxHeight: math.max(220.0, constraints.maxHeight - 300),
          ),
          const SizedBox(height: OasxSpace.md),
          SizedBox(height: logHeight, child: logWidget),
        ],
      ),
    );
  }
}

/// Status strip for the local deploy entry: path health, path picker and the
/// single primary progression action (run deploy).
class _DeployHeader extends StatelessWidget {
  const _DeployHeader();

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return GetX<ServerController>(
      builder: (controller) {
        final authenticated = controller.rootPathAuthenticated.value;
        final statusColor = authenticated ? colors.accent : colors.danger;
        final path = controller.rootPathServer.value;
        return OasxPanel(
          padding: const EdgeInsets.fromLTRB(
            OasxSpace.lg,
            OasxSpace.md,
            OasxSpace.lg,
            OasxSpace.md,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 720;
              final status = _StatusSummary(
                authenticated: authenticated,
                path: path,
                statusColor: statusColor,
              );
              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickRootPath(controller),
                    icon: const Icon(Icons.folder_open_outlined, size: 17),
                    label: Text(I18n.selectRootPathServer.tr),
                  ),
                  const SizedBox(width: OasxSpace.sm),
                  _DeployActionButton(controller: controller),
                ],
              );
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    status,
                    const SizedBox(height: OasxSpace.md),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: status),
                  const SizedBox(width: OasxSpace.lg),
                  actions,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickRootPath(ServerController controller) async {
    final selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null || selectedDirectory.trim().isEmpty) {
      return;
    }
    controller.updateRootPathServer(selectedDirectory);
  }
}

class _StatusSummary extends StatelessWidget {
  const _StatusSummary({
    required this.authenticated,
    required this.path,
    required this.statusColor,
  });

  final bool authenticated;
  final String path;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            OasxMicroLabel(I18n.setupDeploy.tr),
            const SizedBox(width: OasxSpace.sm),
            OasxStatusPill(
              label: authenticated
                  ? I18n.rootPathCorrect.tr
                  : I18n.rootPathIncorrect.tr,
              color: statusColor,
              dense: true,
            ),
          ],
        ),
        const SizedBox(height: OasxSpace.sm),
        Tooltip(
          message: path,
          child: Text(
            path,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OasxText.mono(
              context,
              size: 12.5,
              color: authenticated ? colors.textPrimary : colors.danger,
            ),
          ),
        ),
        if (!authenticated) ...[
          const SizedBox(height: OasxSpace.xs),
          Text(
            I18n.rootPathServerHelp.tr,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _DeployActionButton extends StatelessWidget {
  const _DeployActionButton({required this.controller});

  final ServerController controller;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return Obx(() {
      final loading = controller.isDeployLoading.value;
      final enabled = controller.rootPathAuthenticated.value && !loading;
      return FilledButton.icon(
        onPressed: enabled ? controller.run : null,
        icon: loading
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.accentInk,
                ),
              )
            : const Icon(Icons.play_arrow_rounded, size: 18),
        label: Text(loading ? I18n.homeLoadingAutoDeploying.tr : I18n.run.tr),
      );
    });
  }
}
