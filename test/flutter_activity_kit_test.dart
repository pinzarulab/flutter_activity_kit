import 'package:flutter/services.dart';
import 'package:flutter_activity_kit/flutter_activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel =
      MethodChannel('flutter_activity_kit/methods');
  final List<MethodCall> log = <MethodCall>[];
  bool failUpdates = false;

  setUp(() {
    log.clear();
    failUpdates = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'isSupported':
          return true;
        case 'areActivitiesEnabled':
          return true;
        case 'requestPermissions':
          return true;
        case 'getPushToStartToken':
          return 'push_to_start_hex_token';
        case 'startActivity':
          return <String, dynamic>{
            'id': 'test-activity-id-123',
            'activityType': 'DeliveryAttributes',
            'state': 'active',
            'attributes': {'orderId': 'ORD-987'},
            'contentState': {'status': 'Preparing'},
            'pushToken': 'push_token_abc_123',
          };
        case 'updateActivity':
          if (failUpdates) {
            throw PlatformException(
              code: 'UPDATE_FAILED',
              message: 'Synthetic update failure',
            );
          }
          return null;
        case 'endActivity':
          return null;
        case 'getAllActivities':
          return <dynamic>[
            <String, dynamic>{
              'id': 'test-activity-id-123',
              'activityType': 'DeliveryAttributes',
              'state': 'active',
              'attributes': {'orderId': 'ORD-987'},
              'contentState': {'status': 'Preparing'},
              'pushToken': 'push_token_abc_123',
            }
          ];
        case 'getActivity':
          return <String, dynamic>{
            'id': 'test-activity-id-123',
            'activityType': 'DeliveryAttributes',
            'state': 'active',
            'attributes': {'orderId': 'ORD-987'},
            'contentState': {'status': 'Preparing'},
            'pushToken': 'push_token_abc_123',
          };
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  test('isSupported returns true', () async {
    final supported = await FlutterActivityKit.isSupported();
    expect(supported, isTrue);
    expect(log, hasLength(1));
    expect(log.first.method, 'isSupported');
  });

  test('areActivitiesEnabled returns true', () async {
    final enabled = await FlutterActivityKit.areActivitiesEnabled();
    expect(enabled, isTrue);
    expect(log.first.method, 'areActivitiesEnabled');
  });

  test('requestPermissions returns true', () async {
    final granted = await FlutterActivityKit.requestPermissions();
    expect(granted, isTrue);
    expect(log.first.method, 'requestPermissions');
  });

  test('getPushToStartToken returns token', () async {
    final token = await FlutterActivityKit.getPushToStartToken();
    expect(token, 'push_to_start_hex_token');
    expect(log.first.method, 'getPushToStartToken');
  });

  test('startActivity, update and end flow via ActivitySession', () async {
    final session = await FlutterActivityKit.startActivity(
      attributes: const MapActivityAttributes({'orderId': 'ORD-987'}),
      content: const ActivityContent(
        state: MapActivityContentState({'status': 'Preparing'}),
      ),
      iosOptions: const IOSOptions(activityType: 'DeliveryAttributes'),
      androidOptions: const AndroidOptions(channelName: 'Orders'),
    );

    expect(session.id, 'test-activity-id-123');
    expect(session.state, ActivityState.active);
    expect(session.pushToken, 'push_token_abc_123');

    // Update
    await session.update(
      const ActivityContent(
        state:
            MapActivityContentState({'status': 'On the way', 'progress': 0.7}),
      ),
    );

    expect(log.any((call) => call.method == 'updateActivity'), isTrue);

    // End
    await session.end(
      dismissalPolicy: ActivityDismissalPolicy.immediate,
    );

    expect(log.any((call) => call.method == 'endActivity'), isTrue);
  });

  test('getAllActivities and getActivity', () async {
    final all = await FlutterActivityKit.getAllActivities();
    expect(all.length, 1);
    expect(all.first.id, 'test-activity-id-123');

    final single = await FlutterActivityKit.getActivity('test-activity-id-123');
    expect(single, isNotNull);
    expect(single!.id, 'test-activity-id-123');
  });

  group('Fluent Quick-Start API', () {
    test('FlutterActivityKit.start fluent one-liner', () async {
      final session = await FlutterActivityKit.start(
        activityType: 'Delivery',
        title: 'Order Confirmed',
        message: 'Pizza is baking',
        status: 'Baking 🍕',
        progress: 0.25,
        countdown: const Duration(minutes: 20),
        actions: const [
          ActivityAction(id: 'call_driver', title: 'Call Driver'),
        ],
      );

      expect(session.id, 'test-activity-id-123');
      expect(session.state, ActivityState.active);

      final startCall =
          log.firstWhere((call) => call.method == 'startActivity');
      final args = startCall.arguments as Map<dynamic, dynamic>;
      expect(args['activityType'], 'Delivery');
      final content = args['content'] as Map<dynamic, dynamic>;
      final state = content['state'] as Map<dynamic, dynamic>;
      expect(state['title'], 'Order Confirmed');
      expect(state['status'], 'Baking 🍕');
      expect(state['progress'], 0.25);
      expect(content['timer'], isNotNull);

      // quickUpdate
      await session.quickUpdate(
        status: 'On the Way 🛵',
        progress: 0.85,
      );

      await session.quickUpdate(message: 'Almost there');

      final updateCall =
          log.lastWhere((call) => call.method == 'updateActivity');
      final updateArgs = updateCall.arguments as Map<dynamic, dynamic>;
      final updateContent = updateArgs['content'] as Map<dynamic, dynamic>;
      final updateState = updateContent['state'] as Map<dynamic, dynamic>;
      expect(updateState['status'], 'On the Way 🛵');
      expect(updateState['progress'], 0.85);
      expect(updateState['message'], 'Almost there');

      // quickEnd
      await session.quickEnd(
        status: 'Delivered 🎉',
      );

      expect(log.any((call) => call.method == 'endActivity'), isTrue);
      expect(session.state, ActivityState.ended);
    });

    test('quick start requests an iOS push token', () async {
      await FlutterActivityKit.start(
        title: 'Push enabled',
        iosPushType: 'token',
      );

      final startCall =
          log.firstWhere((call) => call.method == 'startActivity');
      final args = startCall.arguments as Map<dynamic, dynamic>;
      final iosOptions = args['iosOptions'] as Map<dynamic, dynamic>;
      expect(iosOptions['pushType'], 'token');
    });
  });

  group('ActivityController<T>', () {
    test('starts and syncs reactive state changes', () async {
      final controller = ActivityController<Map<String, dynamic>>(
        initialState: {
          'status': 'Preparing',
          'progress': 0.1,
        },
        activityType: 'Delivery',
        actions: const [
          ActivityAction(id: 'cancel_order', title: 'Cancel'),
        ],
        syncDebounce: Duration.zero,
      );

      expect(controller.isActive, isFalse);

      final session = await controller.start();
      expect(controller.isActive, isTrue);
      expect(controller.session, session);

      // Mutate state reactive style
      controller.value = {
        'status': 'Out for Delivery',
        'progress': 0.75,
      };

      expect(log.any((call) => call.method == 'updateActivity'), isTrue);

      await controller.end(finalState: {
        'status': 'Delivered',
        'progress': 1.0,
      });

      expect(controller.isActive, isFalse);
      controller.dispose();
    });

    test('syncImmediately exposes errors and records last error', () async {
      final controller = ActivityController<Map<String, dynamic>>(
        initialState: {'status': 'Preparing'},
        syncDebounce: Duration.zero,
      );
      await controller.start();
      failUpdates = true;

      await expectLater(
        controller.syncImmediately(),
        throwsA(isA<PlatformException>()),
      );
      expect(controller.lastSyncError, isA<PlatformException>());

      controller.dispose();
    });
  });
}
