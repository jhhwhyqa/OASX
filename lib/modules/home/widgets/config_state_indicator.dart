import 'package:flutter/material.dart';
import 'package:oasx/modules/home/controllers/dashboard_controller.dart';
import 'package:oasx/modules/home/widgets/script_state_presentation.dart';

class ConfigStateIndicator extends StatelessWidget {
  const ConfigStateIndicator({super.key, required this.state, this.size = 18});

  final HomeScriptStateFilter state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = state.color(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: size + 12,
        height: size + 12,
        child: Icon(state.indicatorIcon, size: size, color: color),
      ),
    );
  }
}
