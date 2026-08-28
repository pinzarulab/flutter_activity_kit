import 'package:flutter/material.dart';
import 'package:flutter_activity_kit/flutter_activity_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ActivityBuilder renders with initial controller state',
      (tester) async {
    final controller = ActivityController<String>(
      initialState: 'Initial Order Status',
      activityType: 'Delivery',
      stateToMap: (s) => {'status': s},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityBuilder<String>(
            controller: controller,
            builder: (context, state, isActive, child) {
              return Text('Status: $state (Active: $isActive)');
            },
          ),
        ),
      ),
    );

    expect(find.text('Status: Initial Order Status (Active: false)'), findsOneWidget);

    controller.value = 'Out for Delivery';
    await tester.pump();

    expect(find.text('Status: Out for Delivery (Active: false)'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('ActivityActionListener wraps child correctly', (tester) async {
    ActivityActionEvent? receivedEvent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityActionListener(
            onAction: (event) {
              receivedEvent = event;
            },
            child: const Text('My App Content'),
          ),
        ),
      ),
    );

    expect(find.text('My App Content'), findsOneWidget);
    expect(receivedEvent, isNull);
  });
}
