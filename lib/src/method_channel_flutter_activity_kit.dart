import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_activity_kit_platform_interface.dart';
import 'models/activity_alert.dart';
import 'models/activity_attributes.dart';
import 'models/activity_content_state.dart';
import 'models/activity_dismissal_policy.dart';
import 'models/activity_events.dart';
import 'models/activity_instance.dart';
import 'models/android_options.dart';
import 'models/ios_options.dart';

/// An implementation of [FlutterActivityKitPlatform] that uses method and event channels.
class MethodChannelFlutterActivityKit extends FlutterActivityKitPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_activity_kit/methods');

  @visibleForTesting
  final pushTokenEventChannel =
      const EventChannel('flutter_activity_kit/push_tokens');

  @visibleForTesting
  final stateUpdateEventChannel =
      const EventChannel('flutter_activity_kit/state_updates');

  @visibleForTesting
  final actionEventChannel =
      const EventChannel('flutter_activity_kit/action_events');

  Stream<ActivityPushTokenEvent>? _pushTokenStream;
  Stream<ActivityStateUpdateEvent>? _stateUpdateStream;
  Stream<ActivityActionEvent>? _actionStream;

  @override
  Future<bool> isSupported() async {
    final result = await methodChannel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }

  @override
  Future<bool> areActivitiesEnabled() async {
    final result =
        await methodChannel.invokeMethod<bool>('areActivitiesEnabled');
    return result ?? false;
  }

  @override
  Future<bool> requestPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  @override
  Future<String?> getPushToStartToken({String? activityType}) async {
    return await methodChannel.invokeMethod<String>(
      'getPushToStartToken',
      <String, dynamic>{
        if (activityType != null) 'activityType': activityType,
      },
    );
  }

  @override
  Future<ActivityInstance> startActivity({
    required ActivityAttributes attributes,
    required ActivityContent content,
    IOSOptions? iosOptions,
    AndroidOptions? androidOptions,
  }) async {
    final payload = <String, dynamic>{
      'attributes': attributes.toMap(),
      'activityType': iosOptions?.activityType ?? attributes.activityType,
      'content': content.toMap(),
      if (iosOptions != null) 'iosOptions': iosOptions.toMap(),
      if (androidOptions != null) 'androidOptions': androidOptions.toMap(),
    };

    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'startActivity',
      payload,
    );

    if (result == null) {
      throw PlatformException(
        code: 'ACTIVITY_START_FAILED',
        message: 'Native platform returned null when starting activity.',
      );
    }

    return ActivityInstance.fromMap(result);
  }

  @override
  Future<void> updateActivity({
    required String activityId,
    required ActivityContent content,
    ActivityAlert? alert,
  }) async {
    final payload = <String, dynamic>{
      'activityId': activityId,
      'content': content.toMap(),
      if (alert != null) 'alert': alert.toMap(),
    };

    await methodChannel.invokeMethod<void>('updateActivity', payload);
  }

  @override
  Future<void> endActivity({
    required String activityId,
    ActivityContent? finalContent,
    ActivityDismissalPolicy dismissalPolicy =
        ActivityDismissalPolicy.defaultPolicy,
  }) async {
    final payload = <String, dynamic>{
      'activityId': activityId,
      if (finalContent != null) 'finalContent': finalContent.toMap(),
      'dismissalPolicy': dismissalPolicy.toMap(),
    };

    await methodChannel.invokeMethod<void>('endActivity', payload);
  }

  @override
  Future<List<ActivityInstance>> getAllActivities() async {
    final result = await methodChannel.invokeListMethod<dynamic>(
      'getAllActivities',
    );

    if (result == null) return <ActivityInstance>[];

    return result
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => ActivityInstance.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<ActivityInstance?> getActivity(String activityId) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'getActivity',
      <String, dynamic>{'activityId': activityId},
    );

    if (result == null) return null;
    return ActivityInstance.fromMap(result);
  }

  @override
  Stream<ActivityPushTokenEvent> get pushTokenUpdates {
    _pushTokenStream ??= pushTokenEventChannel
        .receiveBroadcastStream()
        .where((e) => e is Map<dynamic, dynamic>)
        .map((e) => ActivityPushTokenEvent.fromMap(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)));
    return _pushTokenStream!;
  }

  @override
  Stream<ActivityStateUpdateEvent> get activityStateUpdates {
    _stateUpdateStream ??= stateUpdateEventChannel
        .receiveBroadcastStream()
        .where((e) => e is Map<dynamic, dynamic>)
        .map((e) => ActivityStateUpdateEvent.fromMap(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)));
    return _stateUpdateStream!;
  }

  @override
  Stream<ActivityActionEvent> get actionEvents {
    _actionStream ??= actionEventChannel
        .receiveBroadcastStream()
        .where((e) => e is Map<dynamic, dynamic>)
        .map((e) => ActivityActionEvent.fromMap(
            Map<String, dynamic>.from(e as Map<dynamic, dynamic>)));
    return _actionStream!;
  }
}
