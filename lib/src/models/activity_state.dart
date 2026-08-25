/// Represents the lifecycle state of a Live Activity or Ongoing Notification.
enum ActivityState {
  /// The activity is actively running and visible.
  active,

  /// The activity data is outdated or stale.
  stale,

  /// The activity has concluded its lifecycle.
  ended,

  /// The activity was dismissed by the system or user.
  dismissed,

  /// Unknown or unsupported state.
  unknown;

  /// Creates an [ActivityState] from a serialized string.
  static ActivityState fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'active':
        return ActivityState.active;
      case 'stale':
        return ActivityState.stale;
      case 'ended':
        return ActivityState.ended;
      case 'dismissed':
        return ActivityState.dismissed;
      default:
        return ActivityState.unknown;
    }
  }

  /// Serializes the state to a string.
  String toValue() => name;
}
