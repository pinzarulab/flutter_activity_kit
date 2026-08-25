import 'dart:async';

import '../flutter_activity_kit_platform_interface.dart';
import 'activity_alert.dart';
import 'activity_attributes.dart';
import 'activity_content_state.dart';
import 'activity_dismissal_policy.dart';
import 'activity_events.dart';
import 'activity_instance.dart';
import 'activity_state.dart';

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
