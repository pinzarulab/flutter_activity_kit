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

/// A high-level handle for managing a running Live Activity or Ongoing Notification.
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

  /// The unique identifier of this activity.
  String get id => _instance.id;

  /// The current state of this activity.
  ActivityState get state => _instance.state;

  /// The hex-encoded APNs push token, if available.
  String? get pushToken => _instance.pushToken;

  /// The activity instance snapshot.
  ActivityInstance get instance => _instance;

  /// Updates this activity with new dynamic content.
  Future<void> update(
    ActivityContent<C> content, {
    ActivityAlert? alert,
  }) async {
    await FlutterActivityKitPlatform.instance.updateActivity(
      activityId: id,
      content: content,
      alert: alert,
    );
  }

  /// Quick helper to update the activity with simple properties without manual [ActivityContent] wrapping.
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
  }

  /// Ends this activity with an optional final content and dismissal policy.
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
  }

  /// Quick helper to end the activity with optional final message or status.
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
  }

  /// Stream of push tokens specific to this activity.
  Stream<String> get pushTokenStream {
    return FlutterActivityKitPlatform.instance.pushTokenUpdates
        .where((event) => event.activityId == id)
        .map((event) {
      _instance = ActivityInstance(
        id: _instance.id,
        activityType: _instance.activityType,
        state: _instance.state,
        attributes: _instance.attributes,
        contentState: _instance.contentState,
        pushToken: event.pushToken,
      );
      return event.pushToken;
    });
  }

  /// Stream of state updates specific to this activity.
  Stream<ActivityStateUpdateEvent> get stateStream {
    return FlutterActivityKitPlatform.instance.activityStateUpdates
        .where((event) => event.activityId == id)
        .map((event) {
      _instance = ActivityInstance(
        id: _instance.id,
        activityType: _instance.activityType,
        state: event.state,
        attributes: _instance.attributes,
        contentState: _instance.contentState,
        pushToken: _instance.pushToken,
      );
      return event;
    });
  }

  /// Stream of action button taps for this activity.
  Stream<ActivityActionEvent> get actionStream {
    return FlutterActivityKitPlatform.instance.actionEvents
        .where((event) => event.activityId == id);
  }
}
