import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oasx/modules/args/index.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/config_actions.dart';
import 'package:oasx/modules/home/widgets/home_console.dart';
import 'package:oasx/service/script_service.dart';
import 'package:oasx/translation/i18n_content.dart';

class ConfigWorkbench extends StatelessWidget {
  const ConfigWorkbench({
    super.key,
    required this.controller,
    required this.scriptService,
    required this.loadingAddScript,
    required this.refreshingScripts,
    required this.onAddScriptTap,
    required this.onRefreshScriptsTap,
  });

  final HomeDashboardController controller;
  final ScriptService scriptService;
  final bool loadingAddScript;
  final bool refreshingScripts;
  final VoidCallback onAddScriptTap;
  final VoidCallback onRefreshScriptsTap;

  @override
  Widget build(BuildContext context) {
    return HomeConsole(
      controller: controller,
      loadingAddScript: loadingAddScript,
      refreshingScripts: refreshingScripts,
      onAddScriptTap: onAddScriptTap,
      onRefreshScriptsTap: onRefreshScriptsTap,
      onSelectScript: (scriptName) => _activateScript(context, scriptName),
      onTogglePower: (scriptName, enable) =>
          controller.applySelectionPowerToggle(
            sourceScript: scriptName,
            enable: enable,
          ),
      onRenameScript: (scriptName) => _renameScript(context, scriptName),
      onDeleteScript: (scriptName) => _deleteScript(context, scriptName),
      onExportScript: _exportScript,
      onSetTaskNextRun: _setTaskNextRun,
      onQuickRunTask: (taskName) => _quickSchedule(taskName, true),
      onQuickWaitTask: (taskName) => _quickSchedule(taskName, false),
      onBulkQuickRun: () => _bulkQuickSchedule(true),
      onBulkQuickWait: () => _bulkQuickSchedule(false),
      onOpenTask: (taskName, source) =>
          _openTaskFromSource(context, taskName, source),
    );
  }

  Future<void> _activateScript(
    BuildContext context,
    String scriptName,
  ) async {
    final argsController = Get.find<ArgsController>();
    if (!argsController.isDraftMode.value || !argsController.hasDraftChanges) {
      controller.setActiveScript(scriptName);
      return;
    }
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    controller.setActiveScript(scriptName);
  }

  Future<void> _openTaskFromSource(
    BuildContext context,
    String taskName,
    HomeTaskParameterEntrySource source,
  ) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    controller.openTaskParameters(taskName, source: source);
  }

  Future<void> _quickSchedule(String taskName, bool runNow) async {
    final scriptName = controller.activeScriptName.value.trim();
    if (scriptName.isEmpty) {
      return;
    }
    final ret = await controller.quickScheduleTask(
      scriptName: scriptName,
      taskName: taskName,
      runNow: runNow,
    );
    if (ret) {
      Get.snackbar(I18n.success.tr, taskName.tr);
    }
  }

  Future<void> _bulkQuickSchedule(bool runNow) async {
    final scriptName = controller.activeScriptName.value.trim();
    if (scriptName.isEmpty) {
      return;
    }
    final result = await controller.bulkQuickScheduleTasks(
      scriptName: scriptName,
      runNow: runNow,
    );
    final label = _bulkQuickScheduleLabel(runNow);
    switch (result) {
      case HomeBulkQuickScheduleResult.completed:
        Get.snackbar(I18n.success.tr, label);
        break;
      case HomeBulkQuickScheduleResult.failed:
        Get.snackbar(I18n.error.tr, label);
        break;
      case HomeBulkQuickScheduleResult.timedOut:
        Get.snackbar(I18n.tip.tr, I18n.homeBulkQuickScheduleTimedOut.tr);
        break;
      case HomeBulkQuickScheduleResult.skipped:
        break;
    }
  }

  String _bulkQuickScheduleLabel(bool runNow) {
    return runNow ? I18n.homeQuickRunAll.tr : I18n.homeQuickWaitAll.tr;
  }

  Future<void> _setTaskNextRun(String taskName, String nextRun) async {
    final scriptName = controller.activeScriptName.value.trim();
    if (scriptName.isEmpty) {
      return;
    }
    final ret = await controller.updateTaskNextRun(
      scriptName: scriptName,
      taskName: taskName,
      nextRun: nextRun,
    );
    if (ret) {
      Get.snackbar(I18n.success.tr, taskName.tr);
    }
  }

  Future<void> _renameScript(BuildContext context, String scriptName) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    final renamedScript = await ConfigActions.showRenameDialog(
      scriptService: scriptService,
      oldName: scriptName,
    );
    if (renamedScript != null &&
        controller.activeScriptName.value.trim() == scriptName.trim()) {
      controller.setActiveScript(renamedScript);
    }
    controller.syncWorkspaceState();
  }

  Future<void> _deleteScript(BuildContext context, String scriptName) async {
    if (!await _confirmDiscardDraft(context)) {
      return;
    }
    await ConfigActions.showDeleteDialog(
      scriptService: scriptService,
      name: scriptName,
    );
    controller.syncWorkspaceState();
  }

  Future<void> _exportScript(String scriptName) async {
    await ConfigActions.exportScript(name: scriptName);
  }

  Future<bool> _confirmDiscardDraft(BuildContext context) async {
    final argsController = Get.find<ArgsController>();
    if (!argsController.isDraftMode.value || !argsController.hasDraftChanges) {
      return true;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(I18n.argsDiscardChanges.tr),
        content: Text(I18n.argsUnsavedPrompt.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(I18n.cancel.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(I18n.confirm.tr),
          ),
        ],
      ),
    );
    if (result != true) {
      return false;
    }
    await argsController.discardDraftChanges();
    return true;
  }
}
