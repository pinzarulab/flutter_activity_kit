import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_flutter_activity_kit.dart';
import 'models/activity_alert.dart';
import 'models/activity_attributes.dart';
import 'models/activity_content_state.dart';
import 'models/activity_dismissal_policy.dart';
import 'models/activity_events.dart';
import 'models/activity_instance.dart';
import 'models/android_options.dart';
import 'models/ios_options.dart';

abstract class FlutterActivityKitPlatform extends PlatformInterface {
  FlutterActivityKitPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterActivityKitPlatform _instance =
      MethodChannelFlutterActivityKit();

  static FlutterActivityKitPlatform get instance => _instance;

  static set instance(FlutterActivityKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks whether Live Activities or Ongoing Notifications are supported on the current device/OS.
  Future<bool> isSupported() {
    throw UnimplementedError('isSupported() has not been implemented.');
  }

  /// Checks whether Live Activities are enabled by the user in system settings.
  Future<bool> areActivitiesEnabled() {
    throw UnimplementedError('areActivitiesEnabled() has not been implemented.');
  }

  /// Request push-to-start token on iOS 17.2+ for initiating remote Live Activities.
  Future<String?> getPushToStartToken({String? activityType}) {
    throw UnimplementedError('getPushToStartToken() has not been implemented.');
  }

  /// Starts a new Live Activity or Ongoing Notification.
  Future<ActivityInstance> startActivity({
    required ActivityAttributes attributes,
    required ActivityContent content,
    IOSOptions? iosOptions,
    AndroidOptions? androidOptions,
  }) {
    throw UnimplementedError('startActivity() has not been implemented.');
  }

  /// Updates an active Live Activity or Ongoing Notification with new dynamic content.
  Future<void> updateActivity({
    required String activityId,
    required ActivityContent content,
    ActivityAlert? alert,
  }) {
    throw UnimplementedError('updateActivity() has not been implemented.');
  }

  /// Ends an active Live Activity or Ongoing Notification.
  Future<void> endActivity({
    required String activityId,
    ActivityContent? finalContent,
    ActivityDismissalPolicy dismissalPolicy = ActivityDismissalPolicy.defaultPolicy,
  }) {
    throw UnimplementedError('endActivity() has not been implemented.');
  }

  /// Retrieves a list of all currently tracked activities.
  Future<List<ActivityInstance>> getAllActivities() {
    throw UnimplementedError('getAllActivities() has not been implemented.');
  }

  /// Retrieves a specific activity by its ID.
  Future<ActivityInstance?> getActivity(String activityId) {
    throw UnimplementedError('getActivity() has not been implemented.');
  }

  /// Stream of push-to-update token events.
  Stream<ActivityPushTokenEvent> get pushTokenUpdates {
    throw UnimplementedError('pushTokenUpdates has not been implemented.');
  }

  /// Stream of activity lifecycle state updates.
  Stream<ActivityStateUpdateEvent> get activityStateUpdates {
    throw UnimplementedError('activityStateUpdates has not been implemented.');
  }

  /// Stream of interactive action button taps.
  Stream<ActivityActionEvent> get actionEvents {
    throw UnimplementedError('actionEvents has not been implemented.');
  }
}
