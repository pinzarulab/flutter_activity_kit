/// Alert configuration displayed when an activity starts or updates.
///
/// Triggers a banner alert and sound/haptic feedback on the Lock Screen or Apple Watch.
///
/// Example:
/// ```dart
/// const ActivityAlert(
///   title: '⚽ GOAL!',
///   body: 'Real Madrid scores in the 82nd minute!',
///   sound: 'default',
/// )
/// ```
class ActivityAlert {
  /// The title of the alert banner / notification popup.
  final String title;

  /// The body message text.
  final String body;

  /// Optional custom sound resource name (or `'default'` for standard system sound).
  final String? sound;

  const ActivityAlert({
    required this.title,
    required this.body,
    this.sound,
  });

  /// Converts this alert configuration into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'body': body,
      if (sound != null) 'sound': sound,
    };
  }

  /// Creates an [ActivityAlert] from a serialized map.
  factory ActivityAlert.fromMap(Map<String, dynamic> map) {
    return ActivityAlert(
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      sound: map['sound'] as String?,
    );
  }
}
