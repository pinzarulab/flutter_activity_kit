import 'activity_alert.dart';

/// Base interface for dynamic state of a Live Activity.
///
/// Content state represents properties that change dynamically over the lifetime
/// of the activity (e.g. ETA, current stage, delivery progress, sports score).
abstract class ActivityContentState {
  const ActivityContentState();

  /// Converts the dynamic state into a JSON-compatible map.
  Map<String, dynamic> toMap();
}

/// Generic map-backed implementation of [ActivityContentState].
class MapActivityContentState extends ActivityContentState {
  final Map<String, dynamic> data;

  const MapActivityContentState(this.data);

  @override
  Map<String, dynamic> toMap() => Map<String, dynamic>.from(data);
}

/// Encapsulates the dynamic content of an activity along with metadata.
class ActivityContent<T extends ActivityContentState> {
  /// The dynamic state object.
  final T state;

  /// Optional date at which the activity's content is considered stale.
  final DateTime? staleDate;

  /// Priority relevance score for iOS (0.0 - 100.0).
  final double? relevanceScore;

  /// Optional alert displayed to the user when this content is pushed.
  final ActivityAlert? alert;

  const ActivityContent({
    required this.state,
    this.staleDate,
    this.relevanceScore,
    this.alert,
  });

  /// Converts this content wrapper to a serializable map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'state': state.toMap(),
      if (staleDate != null) 'staleDate': staleDate!.millisecondsSinceEpoch,
      if (relevanceScore != null) 'relevanceScore': relevanceScore,
      if (alert != null) 'alert': alert!.toMap(),
    };
  }
}
