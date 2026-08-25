import 'package:flutter_activity_kit/flutter_activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityState', () {
    test('serializes and deserializes correctly', () {
      expect(ActivityState.fromString('active'), ActivityState.active);
      expect(ActivityState.fromString('stale'), ActivityState.stale);
      expect(ActivityState.fromString('ended'), ActivityState.ended);
      expect(ActivityState.fromString('dismissed'), ActivityState.dismissed);
      expect(ActivityState.fromString('invalid'), ActivityState.unknown);
      expect(ActivityState.active.toValue(), 'active');
    });
  });

  group('ActivityDismissalPolicy', () {
    test('immediate policy', () {
      const policy = ActivityDismissalPolicy.immediate;
      expect(policy.type, 'immediate');
      expect(policy.afterDate, isNull);
      expect(policy.toMap(), {'type': 'immediate'});
    });

    test('default policy', () {
      const policy = ActivityDismissalPolicy.defaultPolicy;
      expect(policy.type, 'default');
      expect(policy.toMap(), {'type': 'default'});
    });

    test('after date policy', () {
      final date = DateTime(2026, 8, 25, 12, 0, 0);
      final policy = ActivityDismissalPolicy.after(date);
      expect(policy.type, 'after');
      expect(policy.afterDate, date);
      expect(policy.toMap(), {
        'type': 'after',
        'afterDate': date.millisecondsSinceEpoch,
      });

      final parsed = ActivityDismissalPolicy.fromMap(policy.toMap());
      expect(parsed.type, 'after');
      expect(parsed.afterDate, date);
    });
  });

  group('ActivityAlert', () {
    test('maps correctly', () {
      const alert = ActivityAlert(
        title: 'Order On The Way',
        body: 'Driver is 5 mins away',
        sound: 'alert.caf',
      );
      final map = alert.toMap();
      expect(map['title'], 'Order On The Way');
      expect(map['body'], 'Driver is 5 mins away');
      expect(map['sound'], 'alert.caf');

      final parsed = ActivityAlert.fromMap(map);
      expect(parsed.title, alert.title);
      expect(parsed.body, alert.body);
      expect(parsed.sound, alert.sound);
    });
  });

  group('ActivityAction', () {
    test('maps correctly', () {
      const action = ActivityAction(
        id: 'cancel_order',
        title: 'Cancel',
        icon: 'ic_cancel',
        isDestructive: true,
        authenticationRequired: true,
      );
      final map = action.toMap();
      expect(map['id'], 'cancel_order');
      expect(map['title'], 'Cancel');
      expect(map['isDestructive'], isTrue);
      expect(map['authenticationRequired'], isTrue);

      final parsed = ActivityAction.fromMap(map);
      expect(parsed.id, action.id);
      expect(parsed.title, action.title);
      expect(parsed.isDestructive, isTrue);
      expect(parsed.authenticationRequired, isTrue);
    });
  });

  group('AndroidOptions & IOSOptions', () {
    test('AndroidOptions serialization', () {
      final baseTime = DateTime(2026, 8, 25, 10, 0, 0);
      final options = AndroidOptions(
        channelId: 'delivery_channel',
        channelName: 'Deliveries',
        color: 0xFF2196F3,
        progress: 0.75,
        isChronometer: true,
        chronometerBase: baseTime,
        actions: const [
          ActivityAction(id: 'call_driver', title: 'Call Driver'),
        ],
      );

      final map = options.toMap();
      expect(map['channelId'], 'delivery_channel');
      expect(map['progress'], 0.75);
      expect(map['isChronometer'], isTrue);
      expect(map['chronometerBase'], baseTime.millisecondsSinceEpoch);

      final parsed = AndroidOptions.fromMap(map);
      expect(parsed.channelId, 'delivery_channel');
      expect(parsed.progress, 0.75);
      expect(parsed.isChronometer, isTrue);
      expect(parsed.actions.length, 1);
      expect(parsed.actions.first.id, 'call_driver');
    });

    test('IOSOptions serialization', () {
      final stale = DateTime(2026, 8, 25, 11, 0, 0);
      final options = IOSOptions(
        activityType: 'DeliveryAttributes',
        staleDate: stale,
        relevanceScore: 85.0,
      );

      final map = options.toMap();
      expect(map['activityType'], 'DeliveryAttributes');
      expect(map['staleDate'], stale.millisecondsSinceEpoch);
      expect(map['relevanceScore'], 85.0);

      final parsed = IOSOptions.fromMap(map);
      expect(parsed.activityType, 'DeliveryAttributes');
      expect(parsed.staleDate, stale);
      expect(parsed.relevanceScore, 85.0);
    });
  });

  group('ActivityAttributes and ActivityContent', () {
    test('MapActivityAttributes and MapActivityContentState', () {
      const attrs = MapActivityAttributes(
        {'orderId': '12345', 'restaurant': 'Pizza Palace'},
        customActivityType: 'FoodDelivery',
      );
      expect(attrs.activityType, 'FoodDelivery');
      expect(attrs.toMap(), {'orderId': '12345', 'restaurant': 'Pizza Palace'});

      const contentState = MapActivityContentState(
        {'status': 'Cooking', 'etaMinutes': 15, 'progress': 0.3},
      );
      const content = ActivityContent(
        state: contentState,
        relevanceScore: 50.0,
        alert: ActivityAlert(title: 'Updated', body: 'Pizza is baking!'),
      );

      final map = content.toMap();
      expect(map['state'], {'status': 'Cooking', 'etaMinutes': 15, 'progress': 0.3});
      expect(map['relevanceScore'], 50.0);
      expect(map['alert']?['title'], 'Updated');
    });
  });

  group('ActivityInstance and Events', () {
    test('ActivityInstance serialization', () {
      final instance = ActivityInstance.fromMap(const {
        'id': 'act_001',
        'activityType': 'Delivery',
        'state': 'active',
        'attributes': {'orderId': '99'},
        'contentState': {'progress': 0.5},
        'pushToken': 'aabbcc112233',
      });

      expect(instance.id, 'act_001');
      expect(instance.activityType, 'Delivery');
      expect(instance.state, ActivityState.active);
      expect(instance.pushToken, 'aabbcc112233');
    });

    test('Events serialization', () {
      final pushTokenEvent = ActivityPushTokenEvent.fromMap(const {
        'activityId': 'act_001',
        'pushToken': 'token_hex_123',
      });
      expect(pushTokenEvent.activityId, 'act_001');
      expect(pushTokenEvent.pushToken, 'token_hex_123');

      final stateEvent = ActivityStateUpdateEvent.fromMap(const {
        'activityId': 'act_001',
        'state': 'ended',
      });
      expect(stateEvent.activityId, 'act_001');
      expect(stateEvent.state, ActivityState.ended);

      final actionEvent = ActivityActionEvent.fromMap(const {
        'activityId': 'act_001',
        'actionId': 'call_courier',
        'payload': {'phone': '555-1234'},
      });
      expect(actionEvent.activityId, 'act_001');
      expect(actionEvent.actionId, 'call_courier');
      expect(actionEvent.payload?['phone'], '555-1234');
    });
  });
}
