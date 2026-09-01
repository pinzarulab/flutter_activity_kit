import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../flutter_activity_kit.dart';

/// A reactive controller that binds a Flutter state model [T] directly to an iOS Live Activity and Android Ongoing Notification.
///
/// Whenever [value] is updated (e.g. `controller.value = newState` or `controller.updateState(newState)`),
/// the Live Activity and Android Notification are automatically synchronized with built-in debouncing
/// to prevent native platform channel throttling and lag.
///
/// Example:
/// ```dart
/// // 1. Define reactive controller
/// final controller = ActivityController<OrderState>(
///   initialState: OrderState(status: 'Preparing', progress: 0.1),
///   activityType: 'DeliveryAttributes',
///   stateToMap: (state) => {
///     'status': state.status,
///     'progress': state.progress,
///   },
///   autoStart: true,
/// );
///
/// // 2. Mutate state anywhere in your app:
/// controller.value = OrderState(status: 'Out for Delivery', progress: 0.8);
///
/// // 3. Bind to UI:
/// ActivityBuilder<OrderState>(
///   controller: controller,
///   builder: (context, state, isActive, child) {
///     return Text(state.status);
///   },
/// );
/// ```
class ActivityController<T> extends ValueNotifier<T> {
  /// The activity type identifier matching your Swift `ActivityAttributes` struct (e.g. `'DeliveryAttributes'`).
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

  /// Android notification priority (defaults to 2 for high priority).
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
  Completer<void>? _syncCompleter;
  final StreamController<Object> _syncErrors = StreamController.broadcast();
  Object? _lastSyncError;

  final List<void Function(ActivityActionEvent)> _actionListeners = [];
  final List<void Function(String token)> _pushTokenListeners = [];

  /// The active [ActivitySession], or null if not currently running.
  ActivitySession? get session => _session;

  /// Whether the Live Activity is currently active on the device.
  bool get isActive =>
      _session != null && _session!.state == ActivityState.active;

  /// Most recent automatic synchronization error, if any.
  Object? get lastSyncError => _lastSyncError;

  /// Errors produced by automatic/debounced synchronization.
  Stream<Object> get syncErrors => _syncErrors.stream;

  /// Creates an [ActivityController] with an [initialState].
  ///
  /// Set [autoStart] to `true` to immediately start the Live Activity upon creation.
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
      unawaited(() async {
        try {
          await start();
        } catch (error, stackTrace) {
          _reportSyncError(error, stackTrace);
        }
      }());
    }
  }

  /// Starts the Live Activity with the current [value].
  ///
  /// Returns the created [ActivitySession].
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
  ///
  /// Updates are debounced according to [syncDebounce] to prevent platform channel congestion.
  @override
  set value(T newValue) {
    super.value = newValue;
    _syncToPlatform();
  }

  /// Updates the state and synchronizes with the Live Activity immediately.
  ///
  /// Pass an optional [alert] to trigger a banner/sound on the Lock Screen.
  Future<void> updateState(T newState, {ActivityAlert? alert}) async {
    super.value = newState;
    if (_session != null && isActive) {
      await _waitForSyncs();
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
    await _waitForSyncs();
    await _executeSync(rethrowError: true);
  }

  /// Ends the running Live Activity and releases the session.
  ///
  /// Pass [finalState] to display a completion message on the lock screen.
  Future<void> end({
    T? finalState,
    ActivityDismissalPolicy dismissalPolicy =
        ActivityDismissalPolicy.defaultPolicy,
  }) async {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    await _waitForSyncs();

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

  /// Registers an action button callback on this controller.
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

  Future<void> _executeSync({bool rethrowError = false}) async {
    if (_session == null || !isActive) return;

    if (_isSyncing) {
      _hasPendingSync = true;
      return;
    }

    _isSyncing = true;
    _hasPendingSync = false;
    final completer = Completer<void>();
    _syncCompleter = completer;

    try {
      final content = _resolveContent(value);
      await _session!.update(content);
    } catch (error, stackTrace) {
      _reportSyncError(
        error,
        stackTrace,
        reportToFlutter: !rethrowError,
      );
      if (rethrowError) rethrow;
    } finally {
      _isSyncing = false;
      completer.complete();
      if (identical(_syncCompleter, completer)) {
        _syncCompleter = null;
      }
      if (_hasPendingSync) {
        _hasPendingSync = false;
        unawaited(_executeSync());
      }
    }
  }

  void _reportSyncError(
    Object error,
    StackTrace stackTrace, {
    bool reportToFlutter = true,
  }) {
    _lastSyncError = error;
    if (!_syncErrors.isClosed) {
      _syncErrors.add(error);
    }
    if (reportToFlutter) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'flutter_activity_kit',
          context: ErrorDescription('while synchronizing an activity'),
        ),
      );
    }
  }

  Future<void> _waitForSyncs() async {
    while (_syncCompleter != null) {
      await _syncCompleter!.future;
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
    unawaited(_syncErrors.close());
    super.dispose();
  }
}
