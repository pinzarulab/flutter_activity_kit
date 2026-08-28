import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../flutter_activity_kit.dart';

/// A declarative widget that listens to interactive action button taps from
/// Dynamic Island, Lock Screen, and Android Ongoing Notifications.
///
/// Automatically subscribes on [initState] and unsubscribes on [dispose].
class ActivityActionListener extends StatefulWidget {
  /// Callback triggered on ANY action event.
  final ValueChanged<ActivityActionEvent>? onAction;

  /// Map of specific action callbacks keyed by `actionId` (e.g. `'call_driver'`, `'match_stats'`).
  final Map<String, ValueChanged<ActivityActionEvent>>? actions;

  /// Optional activity ID filter.
  final String? activityId;

  /// The child widget.
  final Widget child;

  const ActivityActionListener({
    super.key,
    this.onAction,
    this.actions,
    this.activityId,
    required this.child,
  });

  @override
  State<ActivityActionListener> createState() => _ActivityActionListenerState();
}

class _ActivityActionListenerState extends State<ActivityActionListener> {
  StreamSubscription<ActivityActionEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant ActivityActionListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityId != widget.activityId) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _subscribe() {
    final stream = widget.activityId != null
        ? FlutterActivityKit.actionEventsFor(widget.activityId!)
        : FlutterActivityKit.actionEvents;

    _subscription = stream.listen((event) {
      widget.onAction?.call(event);
      if (widget.actions != null && widget.actions!.containsKey(event.actionId)) {
        widget.actions![event.actionId]!(event);
      }
    });
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
