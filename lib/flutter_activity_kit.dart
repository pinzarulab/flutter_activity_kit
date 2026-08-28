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

/// Primary entrypoint and interface for managing iOS Live Activities (Dynamic Island & Lock Screen)
/// and Android Ongoing Notifications in Flutter.
///
/// Use [FlutterActivityKit.start] for ultra-concise 1-line creation, or [FlutterActivityKit.startActivity]
/// for custom typed models.
///
/// Example:
/// ```dart
/// // Start a live delivery activity:
/// final session = await FlutterActivityKit.start(
///   activityType: 'Delivery',
///   title: 'Order Confirmed',
///   message: 'Bella Pizza is preparing your order',
///   status: 'Preparing 🍕',
///   progress: 0.15,
///   countdown: const Duration(minutes: 25),
///   actions: const [
///     ActivityAction(id: 'call_driver', title: 'Call Driver'),
///   ],
/// );
///
/// // Update directly on session:
/// await session.quickUpdate(
///   status: 'On the Way 🛵',
///   progress: 0.85,
/// );
///
/// // End activity:
/// await session.quickEnd(status: 'Delivered 🎉');
/// ```
class FlutterActivityKit {
  FlutterActivityKit._();

  static FlutterActivityKitPlatform get _platform =>
      FlutterActivityKitPlatform.instance;

  /// Checks whether Live Activities (iOS 16.1+) and Ongoing Notifications (Android 7.0+)
  /// are supported on the current device and operating system version.
  ///
  /// Returns `true` if the OS supports live activity display; otherwise `false`.
  static Future<bool> isSupported() => _platform.isSupported();

  /// Checks whether Live Activities are enabled in system settings by the user.
  ///
  /// On iOS, users can globally or per-app disable Live Activities in Settings.
  /// On Android, this checks if notification channels are enabled.
  ///
  /// Returns `true` if enabled and permitted; otherwise `false`.
  static Future<bool> areActivitiesEnabled() =>
      _platform.areActivitiesEnabled();

  /// Requests notification and Live Activity permissions from the user.
  ///
  /// On Android 13+ (API 33+), this presents the native runtime `POST_NOTIFICATIONS` permission prompt.
  /// On iOS, this ensures notification authorization is granted.
  ///
  /// Returns `true` if granted by the user; otherwise `false`.
  static Future<bool> requestPermissions() =>
      _platform.requestPermissions();

  /// Retrieves the Push-to-Start token on iOS 17.2+ for triggering Live Activities remotely via APNs.
  ///
  /// Pass an optional [activityType] to retrieve the token for a specific ActivityAttributes type.
  /// Returns a hexadecimal token string, or `null` if unsupported or disabled.
  static Future<String?> getPushToStartToken({String? activityType}) =>
      _platform.getPushToStartToken(activityType: activityType);

  /// Ultra-concise fluent helper to start a Live Activity or Ongoing Notification in a single readable call.
  ///
  /// Eliminates the need to construct nested wrapper classes ([ActivityContent], [MapActivityAttributes], [IOSOptions], [AndroidOptions]).
  ///
  /// Parameters:
  /// - [activityType]: The custom Swift ActivityAttributes type name (e.g. `'DeliveryAttributes'`).
  /// - [title]: Main headline text displayed on Lock Screen and notifications.
  /// - [message]: Secondary descriptive text or status update.
  /// - [status]: Short badge or state text (e.g. `'Baking 🍕'`, `'Live 74\''`).
  /// - [progress]: Optional progress value from `0.0` to `1.0`.
  /// - [timer]: An [ActivityTimer] instance for 60 FPS hardware chronometers or countdowns.
  /// - [countdown]: Shorthand [Duration] to create an automatic hardware countdown timer.
  /// - [chronometer]: Shorthand to create an elapsed stop-clock timer.
  /// - [attributes]: Immutable static attributes passed to iOS/Android upon creation.
  /// - [data]: Additional custom key-value pairs stored in the activity dynamic content state.
  /// - [actions]: Interactive action buttons for Lock Screen, Dynamic Island, and Android notifications.
  /// - [channelId]: Android notification channel identifier (defaults to `'[activityType]_channel'`).
  /// - [channelName]: Android notification channel user-facing title.
  /// - [androidPriority]: Android notification priority (defaults to `2` for high).
  /// - [alert]: Optional sound/vibration alert popup triggered on the lock screen.
  /// - [staleDate]: Date after which iOS marks this activity as outdated if no updates arrive.
  /// - [relevanceScore]: Float score determining priority when multiple activities compete on Lock Screen.
  ///
  /// Returns an [ActivitySession] instance with quick update methods.
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

  /// Starts a new Live Activity or Ongoing Notification using custom typed models [A] and [C].
  ///
  /// Returns a managed [ActivitySession] representing the live running instance.
  ///
  /// Example:
  /// ```dart
  /// final session = await FlutterActivityKit.startActivity(
  ///   attributes: MyCustomAttributes(orderId: '123'),
  ///   content: ActivityContent(state: MyCustomState(status: 'On the way')),
  ///   iosOptions: IOSOptions(activityType: 'OrderAttributes'),
  /// );
  /// ```
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
  ///
  /// Pass updated [content] and an optional [alert] to notify the user.
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

  /// Ends an active activity with an optional [finalContent] and [dismissalPolicy].
  ///
  /// Use [ActivityDismissalPolicy.immediate] to dismiss the Dynamic Island / notification instantly,
  /// or [ActivityDismissalPolicy.defaultPolicy] to allow the system to keep it visible briefly.
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
  ///
  /// Returns a parameterless cancel function to unregister the listener cleanly.
  ///
  /// Example:
  /// ```dart
  /// final unregister = FlutterActivityKit.onAction('call_driver', (event) {
  ///   launchUrl(Uri.parse('tel:+15550199'));
  /// });
  ///
  /// // Later in dispose():
  /// unregister();
  /// ```
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
  ///
  /// Returns a parameterless cancel function to unregister the listener cleanly.
  static void Function() onAnyAction(
    void Function(ActivityActionEvent event) handler,
  ) {
    final subscription = actionEvents.listen(handler);
    return () => subscription.cancel();
  }

  /// Registers a declarative callback for APNs push token updates.
  ///
  /// Automatically invoked whenever Apple APNs generates or rotates a push-to-update token for an activity.
  /// Returns a parameterless cancel function to unregister the listener cleanly.
  ///
  /// Example:
  /// ```dart
  /// FlutterActivityKit.onPushToken((activityId, token) {
  ///   apiService.syncPushToken(activityId, token);
  /// });
  /// ```
  static void Function() onPushToken(
    void Function(String activityId, String token) handler,
  ) {
    final subscription = pushTokenUpdates.listen((event) {
      handler(event.activityId, event.pushToken);
    });
    return () => subscription.cancel();
  }

  /// Retrieves a list of all currently active or pending [ActivityInstance] objects across iOS and Android.
  static Future<List<ActivityInstance>> getAllActivities() =>
      _platform.getAllActivities();

  /// Retrieves a specific [ActivityInstance] by its unique [activityId], or `null` if not found.
  static Future<ActivityInstance?> getActivity(String activityId) =>
      _platform.getActivity(activityId);

  /// Global stream of all push token events across all activities.
  static Stream<ActivityPushTokenEvent> get pushTokenUpdates =>
      _platform.pushTokenUpdates;

  /// Global stream of all state change events (active, stale, ended, dismissed) across all activities.
  static Stream<ActivityStateUpdateEvent> get activityStateUpdates =>
      _platform.activityStateUpdates;

  /// Global stream of interactive action button clicks dispatched from Lock Screen, Dynamic Island, and Android notifications.
  static Stream<ActivityActionEvent> get actionEvents =>
      _platform.actionEvents;

  /// Stream of push token updates filtered specifically for [activityId].
  static Stream<String> pushTokenUpdatesFor(String activityId) {
    return _platform.pushTokenUpdates
        .where((e) => e.activityId == activityId)
        .map((e) => e.pushToken);
  }

  /// Stream of state lifecycle update events filtered specifically for [activityId].
  static Stream<ActivityStateUpdateEvent> stateUpdatesFor(String activityId) {
    return _platform.activityStateUpdates
        .where((e) => e.activityId == activityId);
  }

  /// Stream of action button click events filtered specifically for [activityId].
  static Stream<ActivityActionEvent> actionEventsFor(String activityId) {
    return _platform.actionEvents.where((e) => e.activityId == activityId);
  }
}
