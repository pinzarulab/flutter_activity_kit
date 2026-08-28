/// Base interface for immutable static attributes of an iOS Live Activity or Android Notification.
///
/// Static attributes are immutable properties established when the activity is initiated
/// (e.g., order ID, restaurant name, sports match ID, driver information).
abstract class ActivityAttributes {
  const ActivityAttributes();

  /// Converts the static attributes into a JSON-compatible map.
  Map<String, dynamic> toMap();

  /// The activity identifier or Swift `ActivityAttributes` struct type name.
  String get activityType => runtimeType.toString();
}

/// Generic map-backed implementation of [ActivityAttributes].
///
/// Ideal for quick prototyping without defining custom Dart model classes.
class MapActivityAttributes extends ActivityAttributes {
  /// The raw attributes key-value map.
  final Map<String, dynamic> data;

  /// Custom Swift `ActivityAttributes` struct name (e.g. `'DeliveryAttributes'`).
  final String? customActivityType;

  const MapActivityAttributes(this.data, {this.customActivityType});

  @override
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(data);

  @override
  String get activityType => customActivityType ?? 'GenericActivityAttributes';
}
