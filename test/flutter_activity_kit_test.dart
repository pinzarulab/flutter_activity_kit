import 'package:flutter/services.dart';
import 'package:flutter_activity_kit/flutter_activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel methodChannel =
      MethodChannel('flutter_activity_kit/methods');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
      log.add(methodCall);
      switch (methodCall.method) {
        case 'isSupported':
          return true;
        case 'areActivitiesEnabled':
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
        state: MapActivityContentState({'status': 'On the way', 'progress': 0.7}),
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
}
