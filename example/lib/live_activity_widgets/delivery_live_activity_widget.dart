import 'package:flutter_activity_kit/flutter_activity_kit.dart';

/// Dart definition for the Food & Package Delivery Live Activity widget.
class DeliveryLiveActivityWidget extends LiveActivityWidgetDefinition {
  const DeliveryLiveActivityWidget()
      : super(
          name: 'FoodDelivery',
          activityType: 'DeliveryAttributes',
          template: const LiveActivityTemplate.delivery(
            accentColor: '#EA580C',
            icon: 'bag.fill',
          ),
          actions: const [
            ActivityAction(
              id: 'call_courier',
              title: 'Call Courier',
              icon: 'ic_menu_call',
            ),
            ActivityAction(
              id: 'cancel_order',
              title: 'Cancel',
              isDestructive: true,
            ),
          ],
        );
}
