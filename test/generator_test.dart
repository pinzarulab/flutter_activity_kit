import 'package:flutter_test/flutter_test.dart';

import '../bin/generate_swift.dart' as generator;

void main() {
  group('Swift Generator Tests', () {
    test('Swift generator emits plugin-compatible generic attributes', () {
      final source = generator.generateSwiftTemplate('GenericLiveActivity');
      expect(
        source,
        contains('public struct FlutterActivityAttributes: ActivityAttributes'),
      );
      expect(
        source,
        contains(
          'ActivityConfiguration(for: FlutterActivityAttributes.self)',
        ),
      );
    });

    test('Swift generator emits navigation template with mini-map', () {
      final source =
          generator.generateSwiftTemplate('RideTracking', 'navigation');
      expect(source, contains('struct MiniMapView: View'));
      expect(source, contains('RideTrackingWidget'));
      expect(source, contains('call_driver'));
    });

    test('Swift generator emits delivery template', () {
      final source =
          generator.generateSwiftTemplate('FoodDelivery', 'delivery');
      expect(source, contains('FoodDeliveryWidget'));
      expect(source, contains('call_courier'));
    });

    test('Swift generator emits sports template', () {
      final source = generator.generateSwiftTemplate('LiveMatch', 'sports');
      expect(source, contains('LiveMatchWidget'));
      expect(source, contains('match_stats'));
    });

    test('Swift generator emits workout template', () {
      final source = generator.generateSwiftTemplate('OutdoorRun', 'workout');
      expect(source, contains('OutdoorRunWidget'));
      expect(source, contains('pause_workout'));
    });
  });
}
