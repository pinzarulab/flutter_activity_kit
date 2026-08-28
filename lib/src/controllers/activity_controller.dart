import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../flutter_activity_kit.dart';

/// A reactive controller that binds a Flutter state model [T] directly to a Live Activity / Ongoing Notification.
///
/// Whenever [value] is updated (e.g. `controller.value = newState` or `controller.update(newState)`),
/// the Live Activity and Android Notification are automatically synchronized with built-in debouncing
/// to prevent native platform channel throttling and lag.
class ActivityController<T> extends ValueNotifier<T> {
  /// The activity type identifier (e.g. 'Delivery', 'SportsMatch').
  final String activityType;

  /// Custom mapping function that converts state [T] into a JSON-compatible map.
  final Map<String, dynamic> Function(T state)? stateToMap;

  /// Custom mapping function that converts state [T] into a full [ActivityContent].
  final ActivityContent Function(T state)? stateToContent;

  /// Initial static attributes for the activity.
  final Map<String, dynamic> initialAttributes;

  /// Action buttons to display on the activity / notification.
  final List<ActivityAction> actions;

  /// Android notification channel ID.
  final String? channelId;

  /// Android notification channel name.
  final String? channelName;

  /// Android notification priority.
  final int androidPriority;

  /// Debounce interval for platform synchronizations to prevent flooding iOS ActivityKit / Android Notifications.
  /// Defaults to 150 milliseconds.
  final Duration syncDebounce;

  ActivitySession? _session;
  StreamSubscription<ActivityActionEvent>? _actionSub;
  StreamSubscription<String>? _pushTokenSub;
  Timer? _debounceTimer;
  bool _isSyncing = false;
  bool _hasPendingSync = false;

  final List<void Function(ActivityActionEvent)> _actionListeners = [];
  final List<void Function(String token)> _pushTokenListeners = [];

  /// The active [ActivitySession], or null if not currently running.
  ActivitySession? get session => _session;

  /// Whether the Live Activity is currently active.
  bool get isActive => _session != null && _session!.state == ActivityState.active;

  ActivityController({
    required T initialState,
    this.activityType = 'GenericActivity',
    this.stateToMap,
    this.stateToContent,
    this.initialAttributes = const {},
    this.actions = const [],
    this.channelId,
    this.channelName,
    this.androidPriority = 2,
    this.syncDebounce = const Duration(milliseconds: 150),
    bool autoStart = false,
  }) : super(initialState) {
    if (autoStart) {
      unawaited(start());
    }
  }

  /// Starts the Live Activity with the current [value].
  Future<ActivitySession> start() async {
    if (_session != null && isActive) {
      return _session!;
    }

    final content = _resolveContent(value);

    final session = await FlutterActivityKit.startActivity(
      attributes: MapActivityAttributes(
        initialAttributes,
        customActivityType: activityType,
      ),
      content: content,
      iosOptions: IOSOptions(activityType: activityType),
      androidOptions: AndroidOptions(
        channelId: channelId ?? '${activityType.toLowerCase()}_channel',
        channelName: channelName ?? activityType,
        priority: androidPriority,
        actions: actions,
      ),
    );

    _session = session;

    await _actionSub?.cancel();
    _actionSub = session.actionStream.listen((event) {
      for (final listener in _actionListeners) {
        listener(event);
      }
    });

    await _pushTokenSub?.cancel();
    _pushTokenSub = session.pushTokenStream.listen((token) {
      for (final listener in _pushTokenListeners) {
        listener(token);
      }
    });

    return session;
  }

  /// Sets a new state [newValue] and automatically synchronizes the Live Activity.
  @override
  set value(T newValue) {
    super.value = newValue;
    _syncToPlatform();
  }

  /// Updates the state and synchronizes with the Live Activity immediately.
  Future<void> updateState(T newState, {ActivityAlert? alert}) async {
    super.value = newState;
    if (_session != null && isActive) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      final content = _resolveContent(newState);
      await _session!.update(content, alert: alert);
    }
  }

  /// Forces an immediate platform synchronization without waiting for the debounce timer.
  Future<void> syncImmediately() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _executeSync();
  }

  /// Ends the running Live Activity.
  Future<void> end({
    T? finalState,
    ActivityDismissalPolicy dismissalPolicy = ActivityDismissalPolicy.defaultPolicy,
  }) async {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    if (_session == null) return;

    ActivityContent? finalContent;
    if (finalState != null) {
      super.value = finalState;
      finalContent = _resolveContent(finalState);
    }

    await _session!.end(
      finalContent: finalContent,
      dismissalPolicy: dismissalPolicy,
    );
    _session = null;
  }

  /// Registers an action callback on this controller.
  void onAction(void Function(ActivityActionEvent event) listener) {
    _actionListeners.add(listener);
  }

  /// Registers a push token callback on this controller.
  void onPushToken(void Function(String token) listener) {
    _pushTokenListeners.add(listener);
  }

  void _syncToPlatform() {
    if (_session == null || !isActive) return;

    if (syncDebounce == Duration.zero) {
      unawaited(_executeSync());
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(syncDebounce, () {
      unawaited(_executeSync());
    });
  }

  Future<void> _executeSync() async {
    if (_session == null || !isActive) return;

    if (_isSyncing) {
      _hasPendingSync = true;
      return;
    }

    _isSyncing = true;
    _hasPendingSync = false;

    try {
      final content = _resolveContent(value);
      await _session!.update(content);
    } catch (_) {
      // Ignored
    } finally {
      _isSyncing = false;
      if (_hasPendingSync) {
        _hasPendingSync = false;
        unawaited(_executeSync());
      }
    }
  }

  ActivityContent _resolveContent(T state) {
    if (stateToContent != null) {
      return stateToContent!(state);
    }

    if (stateToMap != null) {
      return ActivityContent(
        state: MapActivityContentState(stateToMap!(state)),
      );
    }

    if (state is Map<String, dynamic>) {
      return ActivityContent(
        state: MapActivityContentState(state),
      );
    }

    throw StateError(
      'ActivityController<$T> requires either stateToMap, stateToContent, or state to be a Map<String, dynamic>',
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _actionSub?.cancel();
    _pushTokenSub?.cancel();
    _actionListeners.clear();
    _pushTokenListeners.clear();
    super.dispose();
  }
}
