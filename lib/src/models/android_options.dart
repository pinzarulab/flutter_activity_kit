import 'activity_action.dart';
import 'activity_timer.dart';

/// Android-specific configuration options for Ongoing Notifications.
class AndroidOptions {
  /// The notification channel ID.
  final String channelId;

  /// The human-readable notification channel name.
  final String channelName;

  /// Optional notification channel description.
  final String? channelDescription;

  /// The small icon resource name in Android `drawable` (e.g. 'ic_stat_delivery').
  final String? smallIcon;

  /// Optional large icon drawable or bitmap name.
  final String? largeIcon;

  /// Accent color ARGB integer (e.g. `0xFF1E88E5`).
  final int? color;

  /// Optional progress value between 0.0 and 1.0.
  final double? progress;

  /// Whether the progress bar is indeterminate.
  final bool isIndeterminate;

  /// Whether to show a chronometer count up or countdown timer.
  final bool isChronometer;

  /// Base timestamp for the chronometer.
  final DateTime? chronometerBase;

  /// Whether the chronometer counts down instead of up.
  final bool chronometerCountDown;

  /// Secondary sub-text displayed in the notification header.
  final String? subText;

  /// Whether to display a timestamp on the notification.
  final bool showWhen;

  /// Notification category (e.g. 'status', 'progress', 'navigation', 'service').
  final String category;

  /// Priority: `0` low, `1` default, `2` high.
  final int priority;

  /// Interactive action buttons displayed in the notification.
  final List<ActivityAction> actions;

  /// Whether the notification should be ongoing (un-dismissible by swipe).
  final bool ongoing;

  /// Optional hardware countdown timer or chronometer.
  final ActivityTimer? timer;

  /// Optional sound resource or null for silent updates.
  final String? sound;

  const AndroidOptions({
    this.channelId = 'flutter_activity_kit_channel',
    this.channelName = 'Live Activities',
    this.channelDescription = 'Ongoing notifications and live activity updates',
    this.smallIcon,
    this.largeIcon,
    this.color,
    this.progress,
    this.isIndeterminate = false,
    this.isChronometer = false,
    this.chronometerBase,
    this.chronometerCountDown = false,
    this.subText,
    this.showWhen = true,
    this.category = 'status',
    this.priority = 1,
    this.actions = const [],
    this.ongoing = true,
    this.timer,
    this.sound,
  });

  /// Converts this configuration to a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'channelId': channelId,
      'channelName': channelName,
      if (channelDescription != null) 'channelDescription': channelDescription,
      if (smallIcon != null) 'smallIcon': smallIcon,
      if (largeIcon != null) 'largeIcon': largeIcon,
      if (color != null) 'color': color,
      if (progress != null) 'progress': progress,
      'isIndeterminate': isIndeterminate,
      'isChronometer': isChronometer,
      if (chronometerBase != null)
        'chronometerBase': chronometerBase!.millisecondsSinceEpoch,
      'chronometerCountDown': chronometerCountDown,
      if (subText != null) 'subText': subText,
      'showWhen': showWhen,
      'category': category,
      'priority': priority,
      'actions': actions.map((a) => a.toMap()).toList(),
      'ongoing': ongoing,
      if (timer != null) 'timer': timer!.toMap(),
      if (sound != null) 'sound': sound,
    };
  }

  /// Creates options from a serialized map.
  factory AndroidOptions.fromMap(Map<String, dynamic> map) {
    return AndroidOptions(
      channelId: map['channelId'] as String? ?? 'flutter_activity_kit_channel',
      channelName: map['channelName'] as String? ?? 'Live Activities',
      channelDescription: map['channelDescription'] as String?,
      smallIcon: map['smallIcon'] as String?,
      largeIcon: map['largeIcon'] as String?,
      color: map['color'] as int?,
      progress: (map['progress'] as num?)?.toDouble(),
      isIndeterminate: map['isIndeterminate'] as bool? ?? false,
      isChronometer: map['isChronometer'] as bool? ?? false,
      chronometerBase: map['chronometerBase'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['chronometerBase'] as int)
          : null,
      chronometerCountDown: map['chronometerCountDown'] as bool? ?? false,
      subText: map['subText'] as String?,
      showWhen: map['showWhen'] as bool? ?? true,
      category: map['category'] as String? ?? 'status',
      priority: map['priority'] as int? ?? 1,
      actions: (map['actions'] as List<dynamic>?)
              ?.map((e) => ActivityAction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      ongoing: map['ongoing'] as bool? ?? true,
      timer: map['timer'] == null
          ? null
          : ActivityTimer.fromMap(
              Map<String, dynamic>.from(map['timer'] as Map),
            ),
      sound: map['sound'] as String?,
    );
  }
}
