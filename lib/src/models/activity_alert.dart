/// Haptic feedback styles triggered when a Live Activity milestone occurs.
enum ActivityHapticFeedback {
  none,
  success,
  warning,
  error,
  impactLight,
  impactMedium,
  impactHeavy,
  selection,
}

/// Alert configuration displayed when an activity starts or updates.
///
/// Triggers a visual banner alert, Dynamic Island bounce animation, system sound,
/// and haptic feedback on iOS and Android.
///
/// Example:
/// ```dart
/// const ActivityAlert(
///   title: '⚽ GOAL!',
///   body: 'Real Madrid scores in the 82nd minute!',
///   sound: 'default',
///   haptic: ActivityHapticFeedback.success,
/// )
/// ```
class ActivityAlert {
  /// The title of the alert banner / notification popup.
  final String title;

  /// The body message text.
  final String body;

  /// Optional custom sound resource name (or `'default'` for standard system sound).
  final String? sound;

  /// Optional haptic feedback triggered during this milestone update.
  final ActivityHapticFeedback haptic;

  const ActivityAlert({
    required this.title,
    required this.body,
    this.sound,
    this.haptic = ActivityHapticFeedback.none,
  });

  /// Converts this alert configuration into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'body': body,
      if (sound != null) 'sound': sound,
      'haptic': haptic.name,
    };
  }

  /// Creates an [ActivityAlert] from a serialized map.
  factory ActivityAlert.fromMap(Map<String, dynamic> map) {
    return ActivityAlert(
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      sound: map['sound'] as String?,
      haptic: ActivityHapticFeedback.values.firstWhere(
        (e) => e.name == map['haptic'],
        orElse: () => ActivityHapticFeedback.none,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityAlert &&
        other.title == title &&
        other.body == body &&
        other.sound == sound &&
        other.haptic == haptic;
  }

  @override
  int get hashCode => Object.hash(title, body, sound, haptic);
}

/// Type alias for [ActivityAlert], aligning with Apple ActivityKit AlertConfiguration.
typedef AlertConfiguration = ActivityAlert;
