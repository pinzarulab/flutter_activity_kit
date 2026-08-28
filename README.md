# flutter_activity_kit ⚡️

[![pub package](https://img.shields.io/badge/pub-v0.4.1-blue.svg)](https://pub.dev/packages/flutter_activity_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![iOS: 16.1+](https://img.shields.io/badge/iOS-16.1%2B-lightgrey.svg)](https://developer.apple.com/documentation/activitykit)
[![Android: 7.0+](https://img.shields.io/badge/Android-7.0%2B-green.svg)](https://developer.android.com/develop/ui/views/notifications)

**Declarative iOS Live Activities (Dynamic Island & Lock Screen) and Android Ongoing Notifications for Flutter.**

Unified cross-platform API for real-time order tracking, live sports matches, rideshare ETAs, hardware-rendered 60 FPS countdowns, reactive controllers, interactive background buttons, and APNs push token synchronization.

---

## ✨ Features

- 🏝️ **iOS Live Activities & Dynamic Island**: Full support for Expanded, Compact Leading/Trailing, Minimal bubbles, and Lock Screen banners.
- 🔔 **Android Ongoing Notifications**: Pinned, rich notifications with custom action buttons, progress bars, categories, and chronometer count-up/countdown timers.
- 🪄 **Fluent Quick-Start API**: Start, update, and end activities in a single readable call—eliminating over 70% of boilerplate.
- 🔄 **Reactive `ActivityController<T>`**: Bind any Flutter state model or `ValueNotifier` directly to an activity. When state changes, the Live Activity and Android Notification update automatically with built-in debouncing.
- ⏱️ **Native Hardware Countdowns & Chronometers (`ActivityTimer`)**: 60 FPS hardware timing rendered directly by Apple and Android SystemUI with **zero CPU wakeups and zero battery drain**.
- 🔘 **Interactive AppIntents & Actions**: Background button interactions (e.g. *"Mute"*, *"Tip"*) and foreground app-opening actions (e.g. *"Stats"*, *"Call Driver"*) bridged into Dart.
- 🎛️ **Declarative Action Routing**: Simple `FlutterActivityKit.onAction('id', callback)` and `ActivityActionListener` widget.
- 📡 **Push Token Management**: Effortless bridging of APNs push-to-update and iOS 17.2+ push-to-start tokens.
- 👁️ **In-App Flutter Previews**: Built-in `DynamicIslandPreview` and `OngoingNotificationPreview` widgets to inspect and preview live activities inside any Flutter view.

---

## 🚀 Getting Started

### 1. Add Dependency

```yaml
dependencies:
  flutter_activity_kit: ^0.4.1
```

---

### 2. Platform Setup

#### 🍏 iOS Setup (Live Activities & Dynamic Island)

1. Set iOS Deployment Target to **iOS 16.1** or higher in Xcode.
2. In `ios/Runner/Info.plist`, enable Live Activities:
   ```xml
   <key>NSSupportsLiveActivities</key>
   <true/>
   <key>NSSupportsLiveActivitiesFrequentUpdates</key>
   <true/>
   ```
3. Add a **Widget Extension** to your Xcode project:
   - In Xcode: `File` ➔ `New` ➔ `Target...` ➔ `Widget Extension`.
   - Name it `LiveActivityWidget` and check **Include Live Activity**.
4. In your Xcode Widget Extension, import `ActivityKit`, `WidgetKit`, `SwiftUI`, and your shared `FlutterActivityAttributes`.

---

#### 🤖 Android Setup (Ongoing Notifications)

1. Add the notification permission in `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```
2. Request notification permissions at runtime with `FlutterActivityKit.requestPermissions()`.

---

## 📖 Usage Guide

### 🪄 1. Fluent Quick-Start API (1-Liner)

Start a Live Activity and Android Ongoing Notification in a single clean call:

```dart
import 'package:flutter_activity_kit/flutter_activity_kit.dart';

// 🚀 Start in 1 readable call:
final session = await FlutterActivityKit.start(
  activityType: 'Delivery',
  title: 'Order Confirmed',
  message: 'Bella Pizza is preparing your order',
  status: 'Preparing 🍕',
  progress: 0.15,
  // ⏱️ 60 FPS zero-battery hardware countdown
  countdown: const Duration(minutes: 25),
  actions: const [
    ActivityAction(id: 'call_driver', title: 'Call Driver'),
    ActivityAction(id: 'cancel_order', title: 'Cancel', isDestructive: true),
  ],
);

// ⚡ Update directly on the session:
await session.quickUpdate(
  status: 'On the Way 🛵',
  progress: 0.85,
  message: 'Driver Alex is 3 mins away',
);

// 🏁 End cleanly:
await session.quickEnd(
  status: 'Delivered 🎉',
);
```

---

### 🔄 2. Reactive State Controller (`ActivityController<T>`)

Bind any state model or `ValueNotifier` directly to an activity. When your app state changes, the Live Activity updates automatically with smart debouncing:

```dart
class OrderState {
  final String status;
  final double progress;
  final String message;

  const OrderState({required this.status, required this.progress, required this.message});
}

// 1. Create the controller
final controller = ActivityController<OrderState>(
  initialState: const OrderState(status: 'Baking', progress: 0.3, message: 'In oven'),
  activityType: 'Delivery',
  stateToMap: (state) => {
    'status': state.status,
    'progress': state.progress,
    'message': state.message,
  },
  autoStart: true,
);

// 2. Just update the value anywhere in your app:
controller.value = const OrderState(status: 'Delivered', progress: 1.0, message: 'Enjoy!');
// 🪄 Dynamic Island & Android Notification sync automatically!

// 3. Bind to Flutter UI with ActivityBuilder:
ActivityBuilder<OrderState>(
  controller: controller,
  builder: (context, state, isActive, child) {
    return Text('${state.status} - ${(state.progress * 100).toInt()}%');
  },
)
```

---

### ⏱️ 3. Native Hardware Countdowns & Chronometers (`ActivityTimer`)

Render smooth, real-time counting clocks directly in Apple and Android SystemUI with **zero battery drain**:

```dart
// 1. Countdown Timer (e.g. Delivery ETA / Oven timer)
final countdownTimer = ActivityTimer.countdown(const Duration(minutes: 25));

// 2. Elapsed Chronometer (e.g. Sports Match / Stopwatch)
final matchTimer = ActivityTimer.chronometer(start: matchKickoffDate);

await session.quickUpdate(
  title: 'Real Madrid vs Barcelona',
  timer: matchTimer, // ⏱️ Ticking live on Lock Screen & Dynamic Island
);
```

---

### 🎛️ 4. Declarative Action Routing

Listen to action button clicks without manual `StreamSubscription` boilerplate:

```dart
// Hook specific actions anywhere:
FlutterActivityKit.onAction('call_driver', (event) async {
  final uri = Uri.parse('tel:+15550199');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
});

FlutterActivityKit.onAction('match_stats', (event) {
  showModalBottomSheet(...);
});

// Or declaratively wrap your widget tree:
ActivityActionListener(
  actions: {
    'call_driver': (event) => _callDriver(),
    'match_stats': (event) => _openStatsModal(),
  },
  child: HomeScreen(),
)
```

---

### 🌐 5. Real-Time API & Backend Push Integration

#### A. In-App Real-Time Stream (WebSocket / Firebase Firestore)
```dart
FirebaseFirestore.instance
    .collection('orders')
    .doc(orderId)
    .snapshots()
    .listen((snapshot) {
  final data = snapshot.data()!;
  controller.value = OrderState(
    status: data['status'],
    progress: (data['progress'] as num).toDouble(),
    message: data['driverMessage'] ?? '',
  );
});
```

#### B. Remote APNs Push Updates (When App is Closed or Screen Locked)
1. Hook token registration in Flutter:
   ```dart
   FlutterActivityKit.onPushToken((activityId, token) {
     myBackendApi.registerToken(activityId, token);
   });
   ```

2. Send APNs HTTP/2 Live Activity payload from your server:
   ```http
   POST https://api.sandbox.push.apple.com/3/device/<PUSH_TOKEN>
   apns-topic: com.example.myApp.push-type.liveactivity
   apns-push-type: liveactivity
   apns-priority: 10
   ```
   ```json
   {
     "aps": {
       "timestamp": 1724660900,
       "event": "update",
       "content-state": {
         "title": "Real Madrid vs Barcelona",
         "message": "⚽ GOAL! Bellingham (3 - 1)",
         "status": "GOAL! 82'",
         "progress": 0.88
       },
       "alert": {
         "title": "⚽ GOAL! Real Madrid",
         "body": "Jude Bellingham scores!"
       }
     }
   }
   ```

---

## 🎨 In-App Flutter Previews

Test and visually verify your Dynamic Island and Ongoing Notifications directly inside your Flutter widget tree:

```dart
// Expanded Dynamic Island Preview
DynamicIslandPreview(
  leading: const Icon(Icons.local_pizza, color: Colors.orange),
  trailing: const Text('12m', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
  title: 'Bella Pizza',
  subtitle: 'Baking in stone oven',
  bottom: const LinearProgressIndicator(value: 0.5, color: Colors.orange),
)

// Android Ongoing Notification Preview
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

## 📄 License

MIT License © 2026 Flutter ActivityKit Contributors.
