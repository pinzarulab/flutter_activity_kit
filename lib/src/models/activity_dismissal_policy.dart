/// Defines the dismissal behavior when ending a Live Activity or Ongoing Notification.
class ActivityDismissalPolicy {
  /// The type of dismissal.
  final String type;

  /// Optional date at which the activity should automatically be dismissed from the Lock Screen.
  final DateTime? afterDate;

  const ActivityDismissalPolicy._(this.type, [this.afterDate]);

  /// Activity is removed immediately from the lock screen / Dynamic Island / notification center.
  static const ActivityDismissalPolicy immediate =
      ActivityDismissalPolicy._('immediate');

  /// Activity is dismissed according to system default (e.g. up to 4 hours on iOS).
  static const ActivityDismissalPolicy defaultPolicy =
      ActivityDismissalPolicy._('default');

  /// Activity stays on the Lock Screen until the specified [date], or until dismissed by user.
  factory ActivityDismissalPolicy.after(DateTime date) {
    return ActivityDismissalPolicy._('after', date);
  }

  /// Converts this policy to a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type,
      if (afterDate != null) 'afterDate': afterDate!.millisecondsSinceEpoch,
    };
  }

  /// Creates a dismissal policy from a map.
  factory ActivityDismissalPolicy.fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String? ?? 'default';
    if (type == 'immediate') {
      return ActivityDismissalPolicy.immediate;
    } else if (type == 'after' && map['afterDate'] != null) {
      final ms = map['afterDate'] as int;
      return ActivityDismissalPolicy.after(
        DateTime.fromMillisecondsSinceEpoch(ms),
      );
    }
    return ActivityDismissalPolicy.defaultPolicy;
  }
}
