import 'package:flutter/widgets.dart';

import '../controllers/activity_controller.dart';

/// A reactive widget that rebuilds whenever the specified [ActivityController] updates its state.
///
/// Provides the current [T] state value and a boolean `isActive` flag to the [builder].
///
/// Example:
/// ```dart
/// ActivityBuilder<OrderState>(
///   controller: myOrderController,
///   builder: (context, state, isActive, child) {
///     return Column(
///       children: [
///         Text('Status: ${state.status}'),
///         Text('Live Activity Active: $isActive'),
///       ],
///     );
///   },
/// );
/// ```
class ActivityBuilder<T> extends StatelessWidget {
  /// The reactive activity controller to listen to.
  final ActivityController<T> controller;

  /// Builder callback that provides the [context], current [state], [isActive] flag, and optional cached [child].
  final Widget Function(
      BuildContext context, T state, bool isActive, Widget? child) builder;

  /// Optional static child widget passed to [builder] to avoid unnecessary subtree rebuilds.
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
