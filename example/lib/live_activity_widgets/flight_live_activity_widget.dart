import 'package:flutter_activity_kit/flutter_activity_kit.dart';

/// ✈️ 100% Custom Flight Tracker Live Activity written entirely in pure Dart!
///
/// Demonstrates how developers can build custom Dynamic Island and Lock Screen
/// widgets in Dart without writing any Swift code.
class FlightLiveActivityWidget extends LiveActivityWidgetDefinition {
  const FlightLiveActivityWidget()
      : super(
          name: 'FlightTracker',
          activityType: 'FlightAttributes',
          actions: const [
            ActivityAction(
              id: 'boarding_pass',
              title: 'Boarding Pass',
              icon: 'ic_menu_agenda',
            ),
          ],
        );

  @override
  LAWidget buildLockScreen(LAContext context) {
    return LAColumn(
      spacing: 6,
      children: [
        LARow(
          children: [
            const LAImage.system('airplane.departure', color: LAColor.cyan),
            LAText(context.title, font: LAFont.headline, bold: true),
            const LASpacer(),
            LAText(context.status, font: LAFont.caption, bold: true, color: LAColor.cyan),
          ],
        ),
        LAText(context.message, font: LAFont.subheadline, color: LAColor.gray),
        const LAProgressBar(tint: LAColor.cyan),
        const LARow(
          children: [
            LAButton(
              title: 'Boarding Pass',
              actionId: 'boarding_pass',
              systemIcon: 'ticket.fill',
              isProminent: true,
              tint: LAColor.cyan,
            ),
          ],
        ),
      ],
    );
  }
}
