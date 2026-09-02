# flutter_activity_kit

[![pub package](https://img.shields.io/badge/pub-v0.6.0-blue.svg)](https://pub.dev/packages/flutter_activity_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![iOS: 16.1+](https://img.shields.io/badge/iOS-16.1%2B-lightgrey.svg)](https://developer.apple.com/documentation/activitykit)
[![Android: 7.0+](https://img.shields.io/badge/Android-7.0%2B-green.svg)](https://developer.android.com/develop/ui/views/notifications)

Unified Flutter API for iOS Live Activities (Dynamic Island & Lock Screen) and Android Ongoing Notifications with push token sync, rich state models, and a **pure Dart UI DSL**.

---

## 🌟 What's New in v0.6.0

- 🤖 **Android 16 Rich Ongoing Notifications**: Unlocks persistent **Status Bar Chips** (Android's official answer to Dynamic Island) with custom icons, text pills, and accent colors.
- 🔊 **Dynamic Island Bounces & Haptic Alerts**: ActivityKit `AlertConfiguration` for native Dynamic Island pulse animations and sounds on milestones, with cross-platform native haptic feedback (`ActivityHapticFeedback`).
- 🗺️ **Static Map & Route Snapshot Generator**: Built-in `MapSnapshotGenerator` for Google Maps and Mapbox dark-mode / satellite snapshot URLs with markers and route paths.
- 🎨 **Pure Dart UI DSL**: Build custom Live Activity widgets in 100% Dart (`LAColumn`, `LARow`, `LAText`, `LAImage`, `LAProgressBar`, `LAButton`, `LASpacer`, `LAContainer`, `LATimer`) and transpile them to native SwiftUI.
- 📁 **Smart Folder Scanning (`lib/live_activity_widgets/`)**: Put your Dart widget definitions in `lib/live_activity_widgets/` and run `dart run flutter_activity_kit:generate_swift` to generate all Swift widgets automatically.

---

## Install

```yaml
dependencies:
  flutter_activity_kit: ^0.6.0
```

- **iOS 16.1+ Live Activities**: Lock Screen banners, Dynamic Island (compact, expanded, minimal).
- **Android Ongoing Notifications**: High priority status bar chips, progress bars, timers, and interactive action buttons.
- **Hardware Timers**: 60 FPS real-time countdowns and chronometers rendered natively by the OS.
- **Pure Dart UI DSL**: Write Live Activity layouts in Dart; transpile to native SwiftUI.
- **APNs & FCM Remote Sync**: Push-to-update and iOS 17.2+ push-to-start token streams.
- **Reactive Controller**: `ActivityController<T>` with auto-sync and built-in debouncing.
- **In-App Previews**: Flutter preview widgets for Dynamic Island and Android notifications.

---

## Install

```yaml
dependencies:
  flutter_activity_kit: ^0.5.1
```

---

## 🎨 Building Live Activities in Pure Dart

You can build Live Activities in **100% pure Dart** without writing any Swift!

### 1. Define your widget in Dart:
Create `lib/live_activity_widgets/flight_live_activity_widget.dart`:

```dart
import 'package:flutter_activity_kit/flutter_activity_kit.dart';

class FlightLiveActivityWidget extends LiveActivityWidgetDefinition {
  const FlightLiveActivityWidget()
      : super(
          name: 'FlightTracker',
          activityType: 'FlightAttributes',
          actions: const [
            ActivityAction(id: 'boarding_pass', title: 'Boarding Pass'),
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
```

### 2. Transpile to Swift:
Run the generator in your project root:

```bash
dart run flutter_activity_kit:generate_swift
```

The generator will scan `lib/live_activity_widgets/` and generate native, crash-proof SwiftUI code in `ios/LiveActivityWidget/`.

---

## 📦 Built-In Templates

If you don't want to design custom layouts, choose from pre-configured templates:

| Template | CLI Command | Features |
| :--- | :--- | :--- |
| **`navigation`** | `dart run flutter_activity_kit:generate_swift --name Ride --template navigation` | Vector Route Mini-Map, ETA badge, Waypoints, Call/Share actions |
| **`delivery`** | `dart run flutter_activity_kit:generate_swift --name Order --template delivery` | Step progress bar, Courier status, Call Courier / Cancel |
| **`sports`** | `dart run flutter_activity_kit:generate_swift --name Match --template sports` | Live Match Scoreboard, Team shields, Match Stats action |
| **`workout`** | `dart run flutter_activity_kit:generate_swift --name Run --template workout` | Real-time Chronometer, Pace & Distance metrics, Pause/Finish |
| **`generic`** | `dart run flutter_activity_kit:generate_swift --name Generic --template generic` | Multi-purpose status capsule, progress bar, timer, and buttons |

---

## 🚀 Quick Start in Dart

### Start an Activity (1 line):
```dart
import 'package:flutter_activity_kit/flutter_activity_kit.dart';

final session = await FlutterActivityKit.start(
  activityType: 'DeliveryAttributes',
  title: 'Bella Pizza',
  message: 'Chef is baking your pizza',
  status: 'Baking 🔥',
  progress: 0.45,
  countdown: const Duration(minutes: 18), // Hardware-rendered 60 FPS countdown!
  attributes: const {'orderId': 'ORD-9812'},
  actions: const [
    ActivityAction(id: 'call_driver', title: 'Call Driver', icon: 'ic_menu_call'),
    ActivityAction(id: 'cancel_order', title: 'Cancel', isDestructive: true),
  ],
);
```

### Update the Activity:
```dart
await session.quickUpdate(
  title: 'Out for Delivery',
  message: 'Driver Alex is on the way (0.8 miles away)',
  status: 'On the Way 🛵',
  progress: 0.85,
  countdown: const Duration(minutes: 5),
);
```

### End the Activity:
```dart
await session.quickEnd(
  title: 'Order Delivered',
  message: 'Enjoy your meal!',
  status: 'Delivered 🎉',
  dismissalPolicy: ActivityDismissalPolicy.immediate,
);
```

---

## 🎛️ Handling Action Button Taps

When the user taps an action button on the iOS Lock Screen banner or Android Notification:

```dart
// Wrap your root widget or listen declaratively:
FlutterActivityKit.onAction('call_driver', (event) async {
  print('User tapped Call Driver for activity: ${event.activityId}');
  final phoneUrl = Uri.parse('tel:+15550199');
  if (await canLaunchUrl(phoneUrl)) {
    await launchUrl(phoneUrl);
  }
});
```

---

## ⚡ Reactive Controller (`ActivityController<T>`)

For state-driven apps (workouts, real-time tracking, WebSocket streams):

```dart
final workoutController = ActivityController<WorkoutState>(
  initialState: WorkoutState(distance: 0.0, pace: '0:00'),
  activityType: 'WorkoutAttributes',
  stateToContent: (state) => ActivityContent(
    state: MapActivityContentState({
      'title': 'Outdoor Run',
      'message': 'Distance: ${state.distance} km • Pace: ${state.pace}',
      'progress': state.distance / 10.0,
    }),
  ),
);

// Start
await workoutController.start();

// Update anywhere in your business logic (auto-debounced to prevent OS rate limits):
workoutController.updateState(
  WorkoutState(distance: 4.2, pace: '5:10 min/km'),
);
```

---

## 📡 Remote Push Sync (APNs & FCM)

Listen for device tokens to push updates directly from your backend server:

```dart
FlutterActivityKit.pushTokenEvents.listen((event) {
  final activityId = event.activityId;
  final apnsToken = event.pushToken;

  // Send apnsToken to your backend (Node.js, Go, Firebase)
  apiService.registerPushToken(activityId: activityId, token: apnsToken);
});
```

---

## ⚙️ Platform Setup

### iOS
1. In `ios/Runner/Info.plist` add:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   <key>NSSupportsLiveActivitiesFrequentUpdates</key>
   <true/>
   ```
2. In Xcode: **File ➔ New ➔ Target ➔ Widget Extension** (name it `LiveActivityWidget`, check **Include Live Activity**).
3. Run `dart run flutter_activity_kit:generate_swift` and add the generated file to your Widget Extension target.

### Android
No native configuration needed. Permissions and ongoing notification channels are handled automatically.

---

## 📄 License
MIT License. Created by [PinzaruLab](https://github.com/pinzarulab).
