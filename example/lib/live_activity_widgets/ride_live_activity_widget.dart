import 'package:flutter_activity_kit/flutter_activity_kit.dart';

/// Dart definition for the Ride & Navigation Live Activity widget.
///
/// Run `dart run flutter_activity_kit:generate_swift` to automatically
/// translate this Dart definition into native SwiftUI code!
class RideLiveActivityWidget extends LiveActivityWidgetDefinition {
  const RideLiveActivityWidget()
      : super(
          name: 'RideTracking',
          activityType: 'RideAttributes',
          template: const LiveActivityTemplate.navigation(
            accentColor: '#F59E0B',
            icon: 'car.fill',
            showRouteMap: true,
          ),
          actions: const [
            ActivityAction(
              id: 'call_driver',
              title: 'Call Driver',
              icon: 'ic_menu_call',
            ),
            ActivityAction(
              id: 'share_eta',
              title: 'Share ETA',
              icon: 'ic_menu_share',
            ),
          ],
        );
}
