/// Represents a native hardware-rendered real-time countdown or chronometer.
///
/// On iOS (Dynamic Island & Lock Screen), timers are rendered by SwiftUI without
/// a Dart polling loop or repeated platform-channel calls.
/// On Android, hardware timers use SystemUI Chronometer in Ongoing Notifications.
class ActivityTimer {
  /// The starting reference date of the timer. Defaults to [DateTime.now()].
  final DateTime? startDate;

  /// The target expiration or end date for a countdown timer.
  final DateTime targetDate;

  /// Whether the timer counts down towards [targetDate] (`true`),
  /// or counts up from [startDate] (`false`). Defaults to `true`.
  final bool countsDown;

  /// Whether the timer is currently paused.
  final bool isPaused;

  /// If paused, the exact time when it was paused.
  final DateTime? pauseTime;

  const ActivityTimer({
    this.startDate,
    required this.targetDate,
    this.countsDown = true,
    this.isPaused = false,
    this.pauseTime,
  });

  /// Factory to create a countdown timer from a remaining [Duration].
  factory ActivityTimer.countdown(Duration duration, {DateTime? start}) {
    final s = start ?? DateTime.now();
    return ActivityTimer(
      startDate: s,
      targetDate: s.add(duration),
      countsDown: true,
    );
  }

  /// Factory to create an elapsed stopwatch/chronometer counting up from [start].
  factory ActivityTimer.chronometer({DateTime? start}) {
    final s = start ?? DateTime.now();
    return ActivityTimer(
      startDate: s,
      targetDate: s,
      countsDown: false,
    );
  }

  /// Converts the timer configuration into a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (startDate != null) 'startDate': startDate!.millisecondsSinceEpoch,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'countsDown': countsDown,
      'isPaused': isPaused,
      if (pauseTime != null) 'pauseTime': pauseTime!.millisecondsSinceEpoch,
    };
  }

  /// Deserializes an [ActivityTimer] from a map.
  factory ActivityTimer.fromMap(Map<String, dynamic> map) {
    return ActivityTimer(
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int)
          : null,
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate'] as int),
      countsDown: map['countsDown'] as bool? ?? true,
      isPaused: map['isPaused'] as bool? ?? false,
      pauseTime: map['pauseTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['pauseTime'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTimer &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          targetDate == other.targetDate &&
          countsDown == other.countsDown &&
          isPaused == other.isPaused &&
          pauseTime == other.pauseTime;

  @override
  int get hashCode => Object.hash(
        startDate,
        targetDate,
        countsDown,
        isPaused,
        pauseTime,
      );
}
