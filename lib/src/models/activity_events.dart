import 'activity_state.dart';

/// Event fired when an activity's push-to-update token is generated or updated.
class ActivityPushTokenEvent {
  /// The activity instance identifier.
  final String activityId;

  /// The hex-encoded APNs push token string.
  final String pushToken;

  const ActivityPushTokenEvent({
    required this.activityId,
    required this.pushToken,
  });

  factory ActivityPushTokenEvent.fromMap(Map<String, dynamic> map) {
    return ActivityPushTokenEvent(
      activityId: map['activityId'] as String? ?? '',
      pushToken: map['pushToken'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'ActivityPushTokenEvent(activityId: $activityId, pushToken: $pushToken)';
}

/// Event fired when an activity's lifecycle state changes.
class ActivityStateUpdateEvent {
  /// The activity instance identifier.
  final String activityId;

  /// The new state of the activity.
  final ActivityState state;

  /// Dismissal date if state is dismissed.
  final DateTime? dismissalDate;

  const ActivityStateUpdateEvent({
    required this.activityId,
    required this.state,
    this.dismissalDate,
  });

  factory ActivityStateUpdateEvent.fromMap(Map<String, dynamic> map) {
    return ActivityStateUpdateEvent(
      activityId: map['activityId'] as String? ?? '',
      state: ActivityState.fromString(map['state'] as String?),
      dismissalDate: map['dismissalDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dismissalDate'] as int)
          : null,
    );
  }

  @override
  String toString() =>
      'ActivityStateUpdateEvent(activityId: $activityId, state: $state)';
}

/// Event fired when a user taps an action button on an Ongoing Notification or Live Activity.
class ActivityActionEvent {
  /// The activity instance identifier.
  final String activityId;

  /// The action identifier that was tapped (e.g. 'cancel_order').
  final String actionId;

  /// Optional payload or input text associated with the action.
  final Map<String, dynamic>? payload;

  const ActivityActionEvent({
    required this.activityId,
    required this.actionId,
    this.payload,
  });

  factory ActivityActionEvent.fromMap(Map<String, dynamic> map) {
    return ActivityActionEvent(
      activityId: map['activityId'] as String? ?? '',
      actionId: map['actionId'] as String? ?? '',
      payload: map['payload'] != null
          ? Map<String, dynamic>.from(map['payload'] as Map)
          : null,
    );
  }

  @override
  String toString() =>
      'ActivityActionEvent(activityId: $activityId, actionId: $actionId, payload: $payload)';
}
