import 'activity_state.dart';

/// Represents an active or historical Live Activity instance.
class ActivityInstance {
  /// Unique system identifier for this activity instance.
  final String id;

  /// The activity type identifier matching the Swift struct / notification channel.
  final String activityType;

  /// Current lifecycle state of the activity.
  final ActivityState state;

  /// Static attributes initialized when the activity was created.
  final Map<String, dynamic> attributes;

  /// Current dynamic state properties of the activity.
  final Map<String, dynamic> contentState;

  /// APNs push-to-update device token (hex-encoded), if requested and available.
  final String? pushToken;

  const ActivityInstance({
    required this.id,
    required this.activityType,
    required this.state,
    required this.attributes,
    required this.contentState,
    this.pushToken,
  });

  /// Creates an [ActivityInstance] from a platform channel map.
  factory ActivityInstance.fromMap(Map<String, dynamic> map) {
    return ActivityInstance(
      id: map['id'] as String? ?? '',
      activityType: map['activityType'] as String? ?? '',
      state: ActivityState.fromString(map['state'] as String?),
      attributes: map['attributes'] != null
          ? Map<String, dynamic>.from(map['attributes'] as Map)
          : const <String, dynamic>{},
      contentState: map['contentState'] != null
          ? Map<String, dynamic>.from(map['contentState'] as Map)
          : const <String, dynamic>{},
      pushToken: map['pushToken'] as String?,
    );
  }

  /// Converts this instance to a map representation.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'activityType': activityType,
      'state': state.toValue(),
      'attributes': attributes,
      'contentState': contentState,
      if (pushToken != null) 'pushToken': pushToken,
    };
  }

  ActivityInstance copyWith({
    ActivityState? state,
    Map<String, dynamic>? contentState,
    String? pushToken,
  }) {
    return ActivityInstance(
      id: id,
      activityType: activityType,
      state: state ?? this.state,
      attributes: attributes,
      contentState: contentState ?? this.contentState,
      pushToken: pushToken ?? this.pushToken,
    );
  }

  @override
  String toString() =>
      'ActivityInstance(id: $id, type: $activityType, state: $state, pushToken: $pushToken)';
}
