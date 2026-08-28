import 'src/flutter_activity_kit_platform_interface.dart';
import 'src/models/activity_action.dart';
import 'src/models/activity_alert.dart';
import 'src/models/activity_attributes.dart';
import 'src/models/activity_content_state.dart';
import 'src/models/activity_dismissal_policy.dart';
import 'src/models/activity_events.dart';
import 'src/models/activity_instance.dart';
import 'src/models/activity_session.dart';
import 'src/models/activity_timer.dart';
import 'src/models/android_options.dart';
import 'src/models/ios_options.dart';

export 'src/controllers/activity_controller.dart';
export 'src/models/activity_action.dart';
export 'src/models/activity_alert.dart';
export 'src/models/activity_attributes.dart';
export 'src/models/activity_content_state.dart';
export 'src/models/activity_dismissal_policy.dart';
export 'src/models/activity_events.dart';
export 'src/models/activity_instance.dart';
export 'src/models/activity_session.dart';
export 'src/models/activity_state.dart';
export 'src/models/activity_timer.dart';
export 'src/models/android_options.dart';
export 'src/models/ios_options.dart';
export 'src/preview/dynamic_island_preview.dart';
export 'src/preview/ongoing_notification_preview.dart';
export 'src/widgets/activity_action_listener.dart';
export 'src/widgets/activity_builder.dart';

/// Primary interface for managing iOS Live Activities and Android Ongoing Notifications.
class FlutterActivityKit {
  FlutterActivityKit._();

  static FlutterActivityKitPlatform get _platform =>
      FlutterActivityKitPlatform.instance;

  /// Checks whether Live Activities / Ongoing Notifications are supported on the current device and OS.
  static Future<bool> isSupported() => _platform.isSupported();

  /// Checks whether Live Activities are enabled in system settings by the user.
  static Future<bool> areActivitiesEnabled() =>
      _platform.areActivitiesEnabled();

  /// Requests notification and Live Activity permissions from the user.
  static Future<bool> requestPermissions() =>
      _platform.requestPermissions();

  /// Retrieves the push-to-start token on iOS 17.2+ for triggering Live Activities remotely via APNs.
  static Future<String?> getPushToStartToken({String? activityType}) =>
      _platform.getPushToStartToken(activityType: activityType);

  /// Ultra-concise fluent helper to start a Live Activity or Ongoing Notification in a single call.
  ///
  /// Eliminates nested wrapper classes ([ActivityContent], [MapActivityAttributes], [IOSOptions], [AndroidOptions]).
  static Future<ActivitySession<MapActivityAttributes, MapActivityContentState>> start({
    String activityType = 'GenericActivity',
    String? title,
    String? message,
    String? status,
    double? progress,
    ActivityTimer? timer,
    Duration? countdown,
    Duration? chronometer,
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? data,
    List<ActivityAction>? actions,
    String? channelId,
    String? channelName,
    int androidPriority = 2,
    ActivityAlert? alert,
    DateTime? staleDate,
    double? relevanceScore,
  }) async {
    final stateMap = <String, dynamic>{};
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

    final effectiveAttributes = MapActivityAttributes(
      attributes ?? const {},
      customActivityType: activityType,
    );

    final effectiveContent = ActivityContent(
      state: MapActivityContentState(stateMap),
      timer: resolvedTimer,
      alert: alert,
      staleDate: staleDate,
      relevanceScore: relevanceScore,
    );

    final effectiveIosOptions = IOSOptions(
      activityType: activityType,
      relevanceScore: relevanceScore,
      staleDate: staleDate,
    );

    final effectiveAndroidOptions = AndroidOptions(
      channelId: channelId ?? '${activityType.toLowerCase()}_channel',
      channelName: channelName ?? activityType,
      priority: androidPriority,
      actions: actions ?? const [],
      timer: resolvedTimer,
    );

    return startActivity(
      attributes: effectiveAttributes,
      content: effectiveContent,
      iosOptions: effectiveIosOptions,
      androidOptions: effectiveAndroidOptions,
    );
  }

  /// Starts a new Live Activity or Ongoing Notification, returning a managed [ActivitySession].
  static Future<ActivitySession<A, C>> startActivity<
      A extends ActivityAttributes, C extends ActivityContentState>({
    required A attributes,
    required ActivityContent<C> content,
    IOSOptions? iosOptions,
    AndroidOptions? androidOptions,
  }) async {
    final instance = await _platform.startActivity(
      attributes: attributes,
      content: content,
      iosOptions: iosOptions,
      androidOptions: androidOptions,
    );

    return ActivitySession<A, C>(
      instance: instance,
      initialAttributes: attributes,
    );
  }

  /// Updates an active activity using its unique [activityId].
  static Future<void> updateActivity<C extends ActivityContentState>({
    required String activityId,
    required ActivityContent<C> content,
    ActivityAlert? alert,
  }) {
    return _platform.updateActivity(
      activityId: activityId,
      content: content,
      alert: alert,
    );
  }

  /// Ends an active activity with an optional final content and dismissal policy.
  static Future<void> endActivity({
    required String activityId,
    ActivityContent? finalContent,
    ActivityDismissalPolicy dismissalPolicy = ActivityDismissalPolicy.defaultPolicy,
  }) {
    return _platform.endActivity(
      activityId: activityId,
      finalContent: finalContent,
      dismissalPolicy: dismissalPolicy,
    );
  }

  /// Registers a declarative callback for a specific [actionId] across all activities.
  /// Returns a function to unregister/cancel the listener.
  static void Function() onAction(
    String actionId,
    void Function(ActivityActionEvent event) handler,
  ) {
    final subscription = actionEvents
        .where((event) => event.actionId == actionId)
        .listen(handler);
    return () => subscription.cancel();
  }

  /// Registers a declarative callback for any action button tap across all activities.
  /// Returns a function to unregister/cancel the listener.
  static void Function() onAnyAction(
    void Function(ActivityActionEvent event) handler,
  ) {
    final subscription = actionEvents.listen(handler);
    return () => subscription.cancel();
  }

  /// Registers a declarative callback for APNs push token updates.
  /// Returns a function to unregister/cancel the listener.
  static void Function() onPushToken(
    void Function(String activityId, String token) handler,
  ) {
    final subscription = pushTokenUpdates.listen((event) {
      handler(event.activityId, event.pushToken);
    });
    return () => subscription.cancel();
  }

  /// Retrieves all currently registered activity instances.
  static Future<List<ActivityInstance>> getAllActivities() =>
      _platform.getAllActivities();

  /// Retrieves a specific activity instance by its ID.
  static Future<ActivityInstance?> getActivity(String activityId) =>
      _platform.getActivity(activityId);

  /// Stream of all push token events across all activities.
  static Stream<ActivityPushTokenEvent> get pushTokenUpdates =>
      _platform.pushTokenUpdates;

  /// Stream of all state change events across all activities.
  static Stream<ActivityStateUpdateEvent> get activityStateUpdates =>
      _platform.activityStateUpdates;

  /// Stream of interactive action button clicks.
  static Stream<ActivityActionEvent> get actionEvents =>
      _platform.actionEvents;

  /// Stream of push token events filtered for a specific [activityId].
  static Stream<String> pushTokenUpdatesFor(String activityId) {
    return _platform.pushTokenUpdates
        .where((e) => e.activityId == activityId)
        .map((e) => e.pushToken);
  }

  /// Stream of state update events filtered for a specific [activityId].
  static Stream<ActivityStateUpdateEvent> stateUpdatesFor(String activityId) {
    return _platform.activityStateUpdates
        .where((e) => e.activityId == activityId);
  }

  /// Stream of action button taps filtered for a specific [activityId].
  static Stream<ActivityActionEvent> actionEventsFor(String activityId) {
    return _platform.actionEvents.where((e) => e.activityId == activityId);
  }
}
