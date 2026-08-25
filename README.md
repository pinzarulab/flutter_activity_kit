# flutter_activity_kit ⚡️

[![pub package](https://img.shields.io/badge/pub-v0.1.0-blue.svg)](https://pub.dev/packages/flutter_activity_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![iOS: 16.1+](https://img.shields.io/badge/iOS-16.1%2B-lightgrey.svg)](https://developer.apple.com/documentation/activitykit)
[![Android: 5.0+](https://img.shields.io/badge/Android-5.0%2B-green.svg)](https://developer.android.com/develop/ui/views/notifications)

**Declarative iOS Live Activities (Dynamic Island & Lock Screen) and Android Ongoing Notifications for Flutter.**

Unified cross-platform API for real-time tracking, live sports scores, rideshare/delivery ETAs, interval timers, APNs push token synchronization, and interactive notification buttons.

---

## ✨ Features

- 🏝️ **iOS Live Activities & Dynamic Island**: Full support for Expanded, Compact Leading/Trailing, Minimal bubbles, and Lock Screen banners.
- 🔔 **Android Ongoing Notifications**: Pinned, rich notifications with custom action buttons, progress bars, categories, and chronometer count-up/countdown timers.
- 🔄 **Unified State Lifecycle**: Start, update, and end activities cleanly from Dart with typed or map-based state models.
- 📡 **Push Token Management**: Effortless bridging of APNs push-to-update and iOS 17.2+ push-to-start tokens.
- 🔘 **Interactive Actions**: Action button clicks (e.g. *"Call Courier"*, *"Cancel Order"*, *"Pause"*) bridged directly into Flutter stream listeners.
- 👁️ **In-App Flutter Previews**: Built-in `DynamicIslandPreview` and `OngoingNotificationPreview` widgets to visualize live activities on any simulator or device.
- 🛠️ **Swift Widget Generator CLI**: Generate ready-to-use SwiftUI WidgetKit extensions in one command.
- 🤝 **Ecosystem Synergy**: Natural companion to `flutter_watch_connectivity` and `flutter_liquid_glass_kit`.

---

## 🏗 Architecture

```
 ┌────────────────────────────────────────────────────────┐
 │                     Flutter App                        │
 │  ┌──────────────────────────────────────────────────┐  │
 │  │ FlutterActivityKit.startActivity()               │  │
 │  │ ActivitySession (update, end, tokenStream)       │  │
 │  │ DynamicIslandPreview & OngoingNotificationPreview│  │
 │  └──────────────────────────────────────────────────┘  │
 └──────────────────────────┬─────────────────────────────┘
                            │ Platform Channels
             ┌──────────────┴──────────────┐
             ▼                             ▼
 ┌──────────────────────┐      ┌──────────────────────┐
 │     iOS (Swift)      │      │   Android (Kotlin)   │
 │ ┌──────────────────┐ │      │ ┌──────────────────┐ │
 │ │ ActivityKit      │ │      │ │ NotificationCompat│ │
 │ │ Bridge (iOS 16+) │ │      │ │ Ongoing Service  │ │
 │ │ Push Tokens      │ │      │ │ Custom Actions   │ │
 │ │ WidgetKit Views  │ │      │ │ Chronometers/Bars│ │
 │ └──────────────────┘ │      │ └──────────────────┘ │
 └──────────────────────┘      └──────────────────────┘
```

---

## 🚀 Getting Started

### 1. Add Dependency

```yaml
dependencies:
  flutter_activity_kit: ^0.1.0
```

---

### 2. Platform Setup

#### 🍏 iOS Setup (Live Activities & Dynamic Island)

1. Set iOS Deployment Target to **iOS 16.1** or higher in your Xcode project settings.
2. In `ios/Runner/Info.plist`, enable Live Activities:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   <key>NSSupportsLiveActivitiesFrequentUpdates</key>
   <true/>
   ```
3. Add a **Widget Extension** to your Xcode project:
   - In Xcode: `File` -> `New` -> `Target...` -> `Widget Extension`.
   - Name it `LiveActivityWidget` and check **Include Live Activity**.
4. Generate the Swift widget template using the CLI tool:
   ```bash
   dart run flutter_activity_kit:generate_swift --name DeliveryStatus
   ```
   Add the generated Swift file to your Widget Extension target in Xcode.

---

#### 🤖 Android Setup (Ongoing Notifications)

1. Add the notification permission in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```
2. Request notification permissions at runtime on Android 13+ (API 33+).

---

## 📖 Usage Guide

### Starting a Live Activity

```dart
import 'package:flutter_activity_kit/flutter_activity_kit.dart';

// Start a food delivery live activity
final session = await FlutterActivityKit.startActivity(
  // Static attributes (immutable during the activity)
  attributes: const MapActivityAttributes({
    'orderId': 'ORD-9921',
    'restaurant': 'Bella Pizza',
  }, customActivityType: 'DeliveryAttributes'),

  // Initial dynamic state
  content: const ActivityContent(
    state: MapActivityContentState({
      'title': 'Order Placed',
      'message': 'Restaurant is preparing your pizza',
      'status': 'Preparing 🍕',
      'progress': 0.25,
    }),
    relevanceScore: 80.0,
    alert: ActivityAlert(
      title: 'Order Confirmed',
      body: 'Your pizza is on its way!',
    ),
  ),

  // iOS-specific configuration
  iosOptions: const IOSOptions(
    activityType: 'DeliveryAttributes',
    pushType: 'token',
  ),

  // Android-specific ongoing notification options
  androidOptions: const AndroidOptions(
    channelId: 'deliveries',
    channelName: 'Order Deliveries',
    category: 'progress',
    priority: 2,
    actions: [
      ActivityAction(id: 'call_courier', title: 'Call Courier'),
      ActivityAction(id: 'cancel', title: 'Cancel', isDestructive: true),
    ],
  ),
);

print('Activity started with ID: ${session.id}');
```

---

### Updating Dynamic State

```dart
// Update using the active session instance
await session.update(
  const ActivityContent(
    state: MapActivityContentState({
      'title': 'Out for Delivery',
      'message': 'Courier is 3 minutes away',
      'status': 'On the Way 🛵',
      'progress': 0.85,
    }),
    alert: ActivityAlert(
      title: 'Almost There!',
      body: 'Courier is turning onto your street.',
    ),
  ),
);
```

---

### Ending an Activity

```dart
// End immediately or with an automatic system dismissal delay
await session.end(
  finalContent: const ActivityContent(
    state: MapActivityContentState({
      'title': 'Delivered',
      'message': 'Enjoy your meal!',
      'status': 'Delivered 🎉',
      'progress': 1.0,
    }),
  ),
  dismissalPolicy: ActivityDismissalPolicy.immediate, // or .defaultPolicy / .after(dateTime)
);
```

---

### Listening to Remote Push Tokens & Actions

```dart
// Listen to APNs push tokens for server-side push-to-update
session.pushTokenStream.listen((tokenHex) {
  print('Push Token for backend: $tokenHex');
  // Send token to your backend (Firebase / AWS SNS / custom APNs server)
});

// Listen to notification action button clicks
session.actionStream.listen((event) {
  if (event.actionId == 'call_courier') {
    // Open phone dialer
  } else if (event.actionId == 'cancel') {
    // Cancel the order
  }
});
```

---

## 🎨 In-App Flutter Previews

Test and visually verify your Dynamic Island and Ongoing Notifications directly in your Flutter widgets without needing a physical device with Dynamic Island!

```dart
// Expanded Dynamic Island
DynamicIslandPreview(
  style: DynamicIslandStyle.expanded,
  leading: const Icon(Icons.local_pizza, color: Colors.amber),
  trailing: const Text('12m', style: TextStyle(color: Colors.greenAccent)),
  center: const Text('Bella Pizza - Baking in Oven'),
  bottom: const LinearProgressIndicator(value: 0.5),
)

// Compact Pill
DynamicIslandPreview(
  style: DynamicIslandStyle.compact,
  leading: const Icon(Icons.local_pizza, size: 14, color: Colors.amber),
  trailing: const Text('12m', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
)

// Android Ongoing Notification Card
OngoingNotificationPreview(
  appName: 'Foodie Delivery',
  subText: 'Order #9921',
  title: 'Out for Delivery',
  body: 'Driver is 5 mins away',
  progress: 0.75,
  actions: [
    TextButton(onPressed: () {}, child: const Text('Call Driver')),
  ],
)
```

---

## 🧪 Running Tests

```bash
flutter test
```

---

## 🤝 Synergy with Ecosystem

- **`flutter_watch_connectivity`**: Share live workout/order state simultaneously with Apple Watch / Wear OS companion apps.
- **`flutter_liquid_glass_kit`**: Style your in-app lock screen widgets and island cards with frosted glass shaders.

---

## 📄 License

MIT License © 2026 Flutter ActivityKit Contributors.
