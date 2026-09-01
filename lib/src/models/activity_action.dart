/// Controls how an Android notification action is delivered.
enum ActivityActionBehavior {
  /// Deliver through a broadcast without opening the application UI.
  background,

  /// Open the application and deliver the action to Dart.
  opensApp,

  /// Open [ActivityAction.uri] through the platform intent resolver.
  deepLink;

  String get value => name;

  static ActivityActionBehavior fromString(String? value) {
    return ActivityActionBehavior.values.firstWhere(
      (behavior) => behavior.value == value,
      orElse: () => ActivityActionBehavior.opensApp,
    );
  }
}

/// Represents an interactive action button on an Android Ongoing Notification.
///
/// iOS Live Activity UI belongs to the app's Widget Extension. Define iOS
/// buttons there and route foreground actions through deep links.
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

  /// Semantic marker retained in serialization. Android SystemUI does not
  /// expose destructive notification-button styling.
  final bool isDestructive;

  /// Whether tapping this action requires app-mediated authentication.
  /// Android forces such actions to [ActivityActionBehavior.opensApp].
  final bool authenticationRequired;

  /// How Android delivers this action.
  final ActivityActionBehavior behavior;

  /// URI opened when [behavior] is [ActivityActionBehavior.deepLink].
  final String? uri;

  /// Optional JSON-compatible data delivered with the action event.
  final Map<String, dynamic>? payload;

  const ActivityAction({
    required this.id,
    required this.title,
    this.icon,
    this.isDestructive = false,
    this.authenticationRequired = false,
    this.behavior = ActivityActionBehavior.opensApp,
    this.uri,
    this.payload,
  });

  /// Converts this action configuration into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      if (icon != null) 'icon': icon,
      'isDestructive': isDestructive,
      'authenticationRequired': authenticationRequired,
      'behavior': behavior.value,
      if (uri != null) 'uri': uri,
      if (payload != null) 'payload': payload,
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
      behavior: ActivityActionBehavior.fromString(map['behavior'] as String?),
      uri: map['uri'] as String?,
      payload: map['payload'] == null
          ? null
          : Map<String, dynamic>.from(map['payload'] as Map),
    );
  }
}
