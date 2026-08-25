/// Base interface for static attributes of a Live Activity.
///
/// Static attributes are immutable properties established when the activity is started
/// (e.g., order ID, restaurant name, driver name).
abstract class ActivityAttributes {
  const ActivityAttributes();

  /// Converts the static attributes into a JSON-compatible map.
  Map<String, dynamic> toMap();

  /// Optional activity identifier or type name matching Swift struct.
  String get activityType => runtimeType.toString();
}

/// Generic map-backed implementation of [ActivityAttributes].
class MapActivityAttributes extends ActivityAttributes {
  final Map<String, dynamic> data;
  final String? customActivityType;

  const MapActivityAttributes(this.data, {this.customActivityType});

  @override
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(data);

  @override
  String get activityType => customActivityType ?? 'GenericActivityAttributes';
}
