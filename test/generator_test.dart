import 'package:flutter_test/flutter_test.dart';

import '../bin/generate_swift.dart' as generator;

void main() {
  test('Swift generator emits plugin-compatible generic attributes', () {
    final source = generator.generateSwiftTemplate('Delivery');
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
    expect(source, isNot(contains('DeliveryAttributes')));
  });
}
