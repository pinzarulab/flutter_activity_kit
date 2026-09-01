import 'package:flutter_activity_kit/src/models/activity_action.dart';
import 'live_activity_components.dart';

/// Enum representing the pre-built Live Activity UI templates.
enum LiveActivityTemplateType {
  /// Navigation & Ride Tracking with stylized Mini-Map route canvas.
  navigation,

  /// Food & Package Delivery with step-by-step progress tracking.
  delivery,

  /// Live Sports match scoreboard with real-time minutes & scores.
  sports,

  /// Workout & Fitness tracker with chronometer and metric badges.
  workout,

  /// Generic customizable Live Activity layout.
  generic,
}

/// Configuration options for a [LiveActivityTemplateType].
class LiveActivityTemplate {
  /// Template category.
  final LiveActivityTemplateType type;

  /// Primary accent color hex code (e.g. '#F59E0B' for amber, '#10B981' for green).
  final String accentColor;

  /// Default system icon or SF Symbol (e.g. 'car.fill', 'bag.fill', 'sportscourt.fill', 'figure.run').
  final String icon;

  /// Whether to render a vector route mini-map canvas (applicable to navigation/delivery).
  final bool showRouteMap;

  /// Custom background tint hex color.
  final String? backgroundTint;

  /// Default compact status pill text.
  final String? defaultStatus;

  const LiveActivityTemplate({
    required this.type,
    this.accentColor = '#007AFF',
    this.icon = 'sparkles',
    this.showRouteMap = false,
    this.backgroundTint,
    this.defaultStatus,
  });

  /// Pre-configured template for Ride Sharing, Taxi, and GPS Navigation.
  const LiveActivityTemplate.navigation({
    String accentColor = '#F59E0B',
    String icon = 'car.fill',
    bool showRouteMap = true,
    String? backgroundTint,
  }) : this(
          type: LiveActivityTemplateType.navigation,
          accentColor: accentColor,
          icon: icon,
          showRouteMap: showRouteMap,
          backgroundTint: backgroundTint,
          defaultStatus: 'On Trip',
        );

  /// Pre-configured template for Food, Grocery, and Parcel Delivery.
  const LiveActivityTemplate.delivery({
    String accentColor = '#EA580C',
    String icon = 'bag.fill',
    bool showRouteMap = false,
    String? backgroundTint,
  }) : this(
          type: LiveActivityTemplateType.delivery,
          accentColor: accentColor,
          icon: icon,
          showRouteMap: showRouteMap,
          backgroundTint: backgroundTint,
          defaultStatus: 'Preparing',
        );

  /// Pre-configured template for Live Sports matches and eSports.
  const LiveActivityTemplate.sports({
    String accentColor = '#10B981',
    String icon = 'sportscourt.fill',
    String? backgroundTint,
  }) : this(
          type: LiveActivityTemplateType.sports,
          accentColor: accentColor,
          icon: icon,
          showRouteMap: false,
          backgroundTint: backgroundTint,
          defaultStatus: 'Live',
        );

  /// Pre-configured template for Running, Cycling, Gym, and Fitness.
  const LiveActivityTemplate.workout({
    String accentColor = '#06B6D4',
    String icon = 'figure.run',
    String? backgroundTint,
  }) : this(
          type: LiveActivityTemplateType.workout,
          accentColor: accentColor,
          icon: icon,
          showRouteMap: false,
          backgroundTint: backgroundTint,
          defaultStatus: 'Running',
        );

  /// Pre-configured generic template.
  const LiveActivityTemplate.generic({
    String accentColor = '#007AFF',
    String icon = 'bolt.fill',
    String? backgroundTint,
  }) : this(
          type: LiveActivityTemplateType.generic,
          accentColor: accentColor,
          icon: icon,
          showRouteMap: false,
          backgroundTint: backgroundTint,
          defaultStatus: 'Active',
        );
}

/// Base class for defining a Live Activity Widget in Dart.
///
/// Place your widget definitions in `lib/live_activity_widgets/` (e.g. `ride_live_activity_widget.dart`),
/// and run `dart run flutter_activity_kit:generate_swift` to translate them into native SwiftUI WidgetKit code.
abstract class LiveActivityWidgetDefinition {
  /// The PascalCase Swift widget name (e.g. 'RideTracking', 'FoodDelivery').
  final String name;

  /// The activity type identifier bridged between Flutter and iOS (e.g. 'RideAttributes').
  final String activityType;

  /// The visual layout template.
  final LiveActivityTemplate template;

  /// Default interactive action buttons for Lock Screen & Notification.
  final List<ActivityAction> actions;

  const LiveActivityWidgetDefinition({
    required this.name,
    required this.activityType,
    this.template = const LiveActivityTemplate.generic(),
    this.actions = const [],
  });

  /// Override this method to design a 100% custom Lock Screen & Notification layout using pure Dart DSL.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// LAWidget buildLockScreen(LAContext context) {
  ///   return LAColumn(
  ///     children: [
  ///       LARow(children: [
  ///         LAImage.system('airplane.departure'),
  ///         LAText(context.title, font: LAFont.headline, bold: true),
  ///       ]),
  ///       LAProgressBar(tint: LAColor.cyan),
  ///     ],
  ///   );
  /// }
  /// ```
  LAWidget? buildLockScreen(LAContext context) => null;

  /// Override this method to design a 100% custom Dynamic Island layout using pure Dart DSL.
  LADynamicIsland? buildDynamicIsland(LAContext context) => null;
}
