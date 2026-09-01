import 'dart:async';

import '../flutter_activity_kit_platform_interface.dart';
import 'activity_alert.dart';
import 'activity_attributes.dart';
import 'activity_content_state.dart';
import 'activity_dismissal_policy.dart';
import 'activity_events.dart';
import 'activity_instance.dart';
import 'activity_state.dart';
import 'activity_timer.dart';

/// A high-level handle for managing a running iOS Live Activity or Android Ongoing Notification.
///
/// An [ActivitySession] is returned when starting an activity via [FlutterActivityKit.start] or
/// [FlutterActivityKit.startActivity]. It provides methods to update the activity, end it, and listen
/// to push tokens or action events specifically belonging to this session.
///
/// Example:
/// ```dart
/// final session = await FlutterActivityKit.start(
///   activityType: 'Delivery',
///   title: 'Order Placed',
/// );
///
/// // Update:
/// await session.quickUpdate(status: 'Baking 🔥', progress: 0.5);
///
/// // Listen to APNs push token:
/// session.pushTokenStream.listen((token) {
///   backendApi.saveToken(token);
/// });
///
/// // End:
/// await session.quickEnd(status: 'Delivered 🎉');
/// ```
class ActivitySession<A extends ActivityAttributes,
    C extends ActivityContentState> {
  /// The underlying platform activity instance metadata.
  ActivityInstance _instance;

  /// The immutable initial attributes this activity was started with.
  final A initialAttributes;

  ActivitySession({
    required ActivityInstance instance,
    required this.initialAttributes,
  }) : _instance = instance;

  /// The unique identifier of this activity assigned by the operating system.
  String get id => _instance.id;

  /// The current lifecycle state of this activity (e.g. [ActivityState.active], [ActivityState.ended]).
  ActivityState get state => _instance.state;

  /// The hex-encoded APNs push token for server-side push-to-update, if available.
  String? get pushToken => _instance.pushToken;

  /// The raw activity instance snapshot.
  ActivityInstance get instance => _instance;

  /// Updates this activity with new typed dynamic [content] and an optional [alert].
  Future<void> update(
    ActivityContent<C> content, {
    ActivityAlert? alert,
  }) async {
    await FlutterActivityKitPlatform.instance.updateActivity(
      activityId: id,
      content: content,
      alert: alert,
    );
    _instance = _instance.copyWith(contentState: content.state.toMap());
  }

  /// Quick helper to update the activity with simple properties without manual [ActivityContent] wrapping.
  ///
  /// Parameters:
  /// - [title]: Updated headline text.
  /// - [message]: Updated body or status message.
  /// - [status]: Short badge or state text.
  /// - [progress]: Progress indicator value between 0.0 and 1.0.
  /// - [timer]: Updated OS-rendered [ActivityTimer].
  /// - [countdown]: Shorthand [Duration] to set a countdown clock.
  /// - [chronometer]: Shorthand to start an elapsed chronometer.
  /// - [data]: Additional custom key-value pairs stored in state.
  /// - [alert]: Optional sound/vibration alert.
  /// - [staleDate]: Date when iOS should mark this activity as stale if no further updates arrive.
  /// - [relevanceScore]: Score for Lock Screen sorting priority.
  Future<void> quickUpdate({
    String? title,
    String? message,
    String? status,
    double? progress,
    ActivityTimer? timer,
    Duration? countdown,
    Duration? chronometer,
    Map<String, dynamic>? data,
    ActivityAlert? alert,
    DateTime? staleDate,
    double? relevanceScore,
  }) async {
    final stateMap = Map<String, dynamic>.from(_instance.contentState);
    if (title != null) stateMap['title'] = title;
    if (message != null) stateMap['message'] = message;
    if (status != null) stateMap['status'] = status;
    if (progress != null) stateMap['progress'] = progress;
    if (data != null) stateMap.addAll(data);

    ActivityTimer? resolvedTimer = timer;
    if (resolvedTimer == null) {
      if (countdown != null) {
        resolvedTimer = ActivityTimer.countdown(countdown);
      } else if (chronometer != null) {
        resolvedTimer = ActivityTimer.chronometer();
      }
    }
    if (resolvedTimer != null) {
      stateMap['timer'] = resolvedTimer.toMap();
    }

    await FlutterActivityKitPlatform.instance.updateActivity(
      activityId: id,
      content: ActivityContent(
        state: MapActivityContentState(stateMap),
        timer: resolvedTimer,
        staleDate: staleDate,
        relevanceScore: relevanceScore,
      ),
      alert: alert,
    );
    _instance = _instance.copyWith(contentState: stateMap);
  }

  /// Ends this activity with an optional [finalContent] and [dismissalPolicy].
  Future<void> end({
    ActivityContent<C>? finalContent,
    ActivityDismissalPolicy dismissalPolicy =
        ActivityDismissalPolicy.defaultPolicy,
  }) async {
    await FlutterActivityKitPlatform.instance.endActivity(
      activityId: id,
      finalContent: finalContent,
      dismissalPolicy: dismissalPolicy,
    );
    _instance = _instance.copyWith(
      state: ActivityState.ended,
      contentState: finalContent?.state.toMap(),
    );
  }

  /// Quick helper to end the activity with an optional final message, status, or dismissal policy.
  Future<void> quickEnd({
    String? title,
    String? message,
    String? status,
    double? progress,
    Map<String, dynamic>? data,
    ActivityDismissalPolicy dismissalPolicy =
        ActivityDismissalPolicy.defaultPolicy,
  }) async {
    ActivityContent? finalContent;
    if (title != null ||
        message != null ||
        status != null ||
        progress != null ||
        data != null) {
      final stateMap = Map<String, dynamic>.from(_instance.contentState);
      if (title != null) stateMap['title'] = title;
      if (message != null) stateMap['message'] = message;
      if (status != null) stateMap['status'] = status;
      if (progress != null) stateMap['progress'] = progress;
      if (data != null) stateMap.addAll(data);

      finalContent = ActivityContent(
        state: MapActivityContentState(stateMap),
      );
    }

    await FlutterActivityKitPlatform.instance.endActivity(
      activityId: id,
      finalContent: finalContent,
      dismissalPolicy: dismissalPolicy,
    );
    _instance = _instance.copyWith(
      state: ActivityState.ended,
      contentState: finalContent?.state.toMap(),
    );
  }

  /// Stream of APNs push tokens generated for this specific activity.
  Stream<String> get pushTokenStream {
    return FlutterActivityKitPlatform.instance.pushTokenUpdates
        .where((event) => event.activityId == id)
        .map((event) {
      _instance = _instance.copyWith(pushToken: event.pushToken);
      return event.pushToken;
    });
  }

  /// Stream of lifecycle state updates specific to this activity.
  Stream<ActivityStateUpdateEvent> get stateStream {
    return FlutterActivityKitPlatform.instance.activityStateUpdates
        .where((event) => event.activityId == id)
        .map((event) {
      _instance = _instance.copyWith(state: event.state);
      return event;
    });
  }

  /// Stream of interactive action button taps dispatched from this activity's UI.
  Stream<ActivityActionEvent> get actionStream {
    return FlutterActivityKitPlatform.instance.actionEvents
        .where((event) => event.activityId == id);
  }
}
