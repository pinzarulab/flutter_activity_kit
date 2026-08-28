/// Represents an interactive action button on an iOS Live Activity or Android Ongoing Notification.
///
/// On iOS 17+, action buttons trigger AppIntents in the background without opening the app,
/// or launch the application via deep link intents.
/// On Android, action buttons dispatch directly to the foreground activity or broadcast receiver.
///
/// Example:
/// ```dart
/// const ActivityAction(
///   id: 'call_driver',
///   title: 'Call Driver',
///   icon: 'ic_menu_call',
///   isDestructive: false,
/// )
/// ```
class ActivityAction {
  /// Unique identifier for the action (e.g. `'cancel_order'`, `'call_driver'`, `'pause_timer'`).
  final String id;

  /// User-visible label text for the action button.
  final String title;

  /// Optional icon name (Android drawable resource or iOS SF Symbol).
  final String? icon;

  /// Whether this action represents a destructive operation (e.g. Cancel order).
  /// Rendered in red on supported platforms.
  final bool isDestructive;

  /// Whether tapping this action requires unlocking the device first.
  final bool authenticationRequired;

  const ActivityAction({
    required this.id,
    required this.title,
    this.icon,
    this.isDestructive = false,
    this.authenticationRequired = false,
  });

  /// Converts this action configuration into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (icon != null) 'icon': icon,
      'isDestructive': isDestructive,
      'authenticationRequired': authenticationRequired,
    };
  }

  /// Creates an [ActivityAction] from a serialized map.
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
