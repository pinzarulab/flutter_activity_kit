/// iOS-specific configuration options for Live Activities.
class IOSOptions {
  /// Logical type label stored inside generic `FlutterActivityAttributes`.
  final String? activityType;

  /// The date at which the activity's content becomes stale.
  final DateTime? staleDate;

  /// Priority score (0.0 to 100.0) used by iOS to order multiple active Live Activities.
  final double? relevanceScore;

  /// Push notification type: 'token' (for remote APNs push updates) or 'none' / null for local.
  final String? pushType;

  const IOSOptions({
    this.activityType,
    this.staleDate,
    this.relevanceScore,
    this.pushType,
  });

  /// Converts this configuration to a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (activityType != null) 'activityType': activityType,
      if (staleDate != null) 'staleDate': staleDate!.millisecondsSinceEpoch,
      if (relevanceScore != null) 'relevanceScore': relevanceScore,
      if (pushType != null) 'pushType': pushType,
    };
  }

  /// Creates options from a serialized map.
  factory IOSOptions.fromMap(Map<String, dynamic> map) {
    return IOSOptions(
      activityType: map['activityType'] as String?,
      staleDate: map['staleDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['staleDate'] as int)
          : null,
      relevanceScore: (map['relevanceScore'] as num?)?.toDouble(),
      pushType: map['pushType'] as String?,
    );
  }
}
