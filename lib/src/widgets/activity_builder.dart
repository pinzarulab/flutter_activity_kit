import 'package:flutter/widgets.dart';

import '../controllers/activity_controller.dart';

/// A widget that rebuilds whenever the specified [ActivityController] changes its state.
class ActivityBuilder<T> extends StatelessWidget {
  /// The reactive activity controller to listen to.
  final ActivityController<T> controller;

  /// Builder callback with the current state and active status.
  final Widget Function(BuildContext context, T state, bool isActive, Widget? child) builder;

  /// Optional static child widget passed to [builder] for performance optimization.
  final Widget? child;

  const ActivityBuilder({
    super.key,
    required this.controller,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: controller,
      builder: (context, state, child) {
        return builder(context, state, controller.isActive, child);
      },
      child: child,
    );
  }
}
