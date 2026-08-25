/// Alert configuration displayed when an activity starts or updates.
class ActivityAlert {
  /// The title of the alert banner / notification.
  final String title;

  /// The body message text.
  final String body;

  /// Optional custom sound name (or 'default' for standard sound).
  final String? sound;

  const ActivityAlert({
    required this.title,
    required this.body,
    this.sound,
  });

  /// Converts this alert configuration to a map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'body': body,
      if (sound != null) 'sound': sound,
    };
  }

  /// Creates an alert from a serialized map.
  factory ActivityAlert.fromMap(Map<String, dynamic> map) {
    return ActivityAlert(
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      sound: map['sound'] as String?,
    );
  }
}
