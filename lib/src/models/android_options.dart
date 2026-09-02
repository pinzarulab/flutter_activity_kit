import 'activity_action.dart';
import 'activity_timer.dart';

/// Android 16+ Rich Ongoing Notification configuration (Status Bar Chips).
///
/// Unlocks glanceable status bar chips (Android's official equivalent to Dynamic Island)
/// on Android 15 QPR and Android 16+, with graceful fallback on earlier Android versions.
class AndroidRichOngoingOptions {
  /// Short compact status text displayed inside the status bar chip (e.g. `"6m"`, `"ETA 12:45"`, `"1-0"`).
  final String? statusChipText;

  /// Custom monochrome icon identifier for the status bar chip.
  final String? statusChipIcon;

  /// Accent color ARGB integer for the status bar chip background pill.
  final int? statusChipColor;

  /// Whether this chip should be prominently expanded in the status bar.
  final bool isProminentChip;

  const AndroidRichOngoingOptions({
    this.statusChipText,
    this.statusChipIcon,
    this.statusChipColor,
    this.isProminentChip = true,
  });

  /// Converts this configuration to a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (statusChipText != null) 'statusChipText': statusChipText,
      if (statusChipIcon != null) 'statusChipIcon': statusChipIcon,
      if (statusChipColor != null) 'statusChipColor': statusChipColor,
      'isProminentChip': isProminentChip,
    };
  }

  /// Creates an [AndroidRichOngoingOptions] from a serialized map.
  factory AndroidRichOngoingOptions.fromMap(Map<String, dynamic> map) {
    return AndroidRichOngoingOptions(
      statusChipText: map['statusChipText'] as String?,
      statusChipIcon: map['statusChipIcon'] as String?,
      statusChipColor: map['statusChipColor'] as int?,
      isProminentChip: map['isProminentChip'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AndroidRichOngoingOptions &&
        other.statusChipText == statusChipText &&
        other.statusChipIcon == statusChipIcon &&
        other.statusChipColor == statusChipColor &&
        other.isProminentChip == isProminentChip;
  }

  @override
  int get hashCode => Object.hash(
        statusChipText,
        statusChipIcon,
        statusChipColor,
        isProminentChip,
      );
}

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

  /// Optional Android 16+ Rich Ongoing Notification (Status Bar Chip) configuration.
  final AndroidRichOngoingOptions? richOngoing;

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
    this.richOngoing,
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
      if (richOngoing != null) 'richOngoing': richOngoing!.toMap(),
    };
  }

  /// Creates an [AndroidOptions] from a serialized map.
  factory AndroidOptions.fromMap(Map<String, dynamic> map) {
    return AndroidOptions(
      channelId:
          map['channelId'] as String? ?? 'flutter_activity_kit_channel',
      channelName: map['channelName'] as String? ?? 'Live Activities',
      channelDescription: map['channelDescription'] as String?,
      smallIcon: map['smallIcon'] as String?,
      largeIcon: map['largeIcon'] as String?,
      color: map['color'] as int?,
      progress: (map['progress'] as num?)?.toDouble(),
      isIndeterminate: map['isIndeterminate'] as bool? ?? false,
      isChronometer: map['isChronometer'] as bool? ?? false,
      chronometerBase: map['chronometerBase'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['chronometerBase'] as int)
          : null,
      chronometerCountDown: map['chronometerCountDown'] as bool? ?? false,
      subText: map['subText'] as String?,
      showWhen: map['showWhen'] as bool? ?? true,
      category: map['category'] as String? ?? 'status',
      priority: map['priority'] as int? ?? 1,
      actions: (map['actions'] as List<dynamic>?)
              ?.map((a) => ActivityAction.fromMap(a as Map<String, dynamic>))
              .toList() ??
          const [],
      ongoing: map['ongoing'] as bool? ?? true,
      timer: map['timer'] != null
          ? ActivityTimer.fromMap(map['timer'] as Map<String, dynamic>)
          : null,
      sound: map['sound'] as String?,
      richOngoing: map['richOngoing'] != null
          ? AndroidRichOngoingOptions.fromMap(
              map['richOngoing'] as Map<String, dynamic>)
          : null,
    );
  }
}
