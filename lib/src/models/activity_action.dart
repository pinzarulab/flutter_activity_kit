/// Represents an interactive action button on the notification or Live Activity.
class ActivityAction {
  /// Unique identifier for the action (e.g. 'cancel_order', 'call_courier').
  final String id;

  /// User-visible title for the action button.
  final String title;

  /// Optional icon name (Android drawable resource or iOS SF Symbol).
  final String? icon;

  /// Whether this action is destructive (colored red on supported platforms).
  final bool isDestructive;

  /// Whether tapping this action requires unlocking the device.
  final bool authenticationRequired;

  const ActivityAction({
    required this.id,
    required this.title,
    this.icon,
    this.isDestructive = false,
    this.authenticationRequired = false,
  });

  /// Converts this action to a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (icon != null) 'icon': icon,
      'isDestructive': isDestructive,
      'authenticationRequired': authenticationRequired,
    };
  }

  /// Creates an action from a serialized map.
  factory ActivityAction.fromMap(Map<String, dynamic> map) {
    return ActivityAction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      icon: map['icon'] as String?,
      isDestructive: map['isDestructive'] as bool? ?? false,
      authenticationRequired: map['authenticationRequired'] as bool? ?? false,
    );
  }
}
