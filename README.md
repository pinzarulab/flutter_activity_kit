# flutter_activity_kit

[![pub package](https://img.shields.io/badge/pub-v0.5.0-blue.svg)](https://pub.dev/packages/flutter_activity_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![iOS: 16.1+](https://img.shields.io/badge/iOS-16.1%2B-lightgrey.svg)](https://developer.apple.com/documentation/activitykit)
[![Android: 7.0+](https://img.shields.io/badge/Android-7.0%2B-green.svg)](https://developer.android.com/develop/ui/views/notifications)

Unified Flutter API for iOS Live Activities and Android ongoing notifications.

## Features

- iOS 16.1+ Lock Screen Live Activities and Dynamic Island content.
- Android ongoing notifications with progress, timers, icons, sound, and actions.
- OS-rendered countdowns and chronometers without a Dart polling timer.
- APNs push-to-update and iOS 17.2+ push-to-start tokens.
- Reactive `ActivityController<T>` with serialized, debounced updates.
- In-app Flutter previews.
- Persisted Android activity metadata across process restarts.

## Install

```yaml
dependencies:
  flutter_activity_kit: ^0.5.0
```

## Platform setup

### iOS

1. Set Runner and Widget Extension deployment targets to iOS 16.1 or newer.
2. Add to `ios/Runner/Info.plist`:

```xml
<key>NSSupportsLiveActivities</key>
<true/>
<key>NSSupportsLiveActivitiesFrequentUpdates</key>
<true/>
```

3. Add a Widget Extension with **Include Live Activity** enabled.
4. Generate a widget whose `FlutterActivityAttributes` contract matches the plugin:

```bash
dart run flutter_activity_kit:generate_swift \
  --name Delivery \
  --output ios/LiveActivityWidget
```

Add generated `DeliveryWidget.swift` to Widget Extension target. Do not replace
`FlutterActivityAttributes` with a differently named attributes type: ActivityKit
requires plugin and widget extension to use matching attributes and content-state
schemas.

### iOS foreground action links

Dart cannot execute inside a Widget Extension process. Route a Live Activity
button into running app with URL:

```swift
Link(
    destination: URL(
        string: "flutteractivitykit://action/open_order?activityId=\(context.activityID)"
    )!
) {
    Text("Open order")
}
```

Register `flutteractivitykit` under `CFBundleURLTypes`. Apps using scenes should
forward URLs from `SceneDelegate`:

```swift
import Flutter
import UIKit
import flutter_activity_kit

class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)
        connectionOptions.urlContexts.forEach { routeActivityURL($0.url) }
    }

    override func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        var remaining = Set<UIOpenURLContext>()
        for context in URLContexts {
            if !routeActivityURL(context.url) { remaining.insert(context) }
        }
        if !remaining.isEmpty {
            super.scene(scene, openURLContexts: remaining)
        }
    }

    @discardableResult
    private func routeActivityURL(_ url: URL) -> Bool {
        guard url.scheme == "flutteractivitykit" else { return false }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let actionId = url.host == "action"
            ? url.path.split(separator: "/").first.map(String.init)
            : url.host
        let activityId = components?.queryItems?
            .first(where: { $0.name == "activityId" })?.value ?? ""
        guard let actionId = actionId else { return false }
        FlutterActivityKitPlugin.sendActionEvent(
            activityId: activityId,
            actionId: actionId
        )
        return true
    }
}
```

Do not also route `flutteractivitykit` URLs in `AppDelegate`; doing both emits
the same action more than once.

Background `AppIntent` work must be implemented in native extension code or a
backend. A Widget Extension cannot call a Dart callback while Flutter engine is
not running.

### Android

Plugin manifest includes `POST_NOTIFICATIONS`. Request runtime permission before
starting an activity on Android 13+:

```dart
final granted = await FlutterActivityKit.requestPermissions();
if (!granted) return;
```

Use a valid monochrome drawable as `AndroidOptions.smallIcon` in production.
If a Dart action calls `canLaunchUrl()` for `tel:`, declare Android 11+
package visibility in app manifest:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="tel"/>
    </intent>
</queries>
```

## Quick start

```dart
import 'package:flutter_activity_kit/flutter_activity_kit.dart';

final session = await FlutterActivityKit.start(
  activityType: 'Delivery',
  title: 'Order confirmed',
  message: 'Pizza is being prepared',
  status: 'Preparing',
  progress: 0.15,
  countdown: const Duration(minutes: 25),
  actions: const [
    ActivityAction(
      id: 'open_order',
      title: 'Open',
      behavior: ActivityActionBehavior.opensApp,
    ),
    ActivityAction(
      id: 'cancel_order',
      title: 'Cancel',
      behavior: ActivityActionBehavior.background,
      payload: {'source': 'notification'},
    ),
  ],
);

await session.quickUpdate(
  status: 'On the way',
  progress: 0.85,
  message: 'Driver is three minutes away',
);

await session.quickEnd(
  status: 'Delivered',
  dismissalPolicy: ActivityDismissalPolicy.immediate,
);
```

Android action behavior:

- `opensApp`: opens app, then delivers event to Dart.
- `background`: sends broadcast without opening UI. Event is queued while
  process and plugin initialize; business-critical background work should use
  native Android code or a background execution framework.
- `deepLink`: opens `ActivityAction.uri` using Android intent resolver.

Listen in Dart:

```dart
final unregister = FlutterActivityKit.onAction('open_order', (event) {
  openOrder(event.activityId);
});

// Later:
unregister();
```

## APNs push updates

Request push-to-update token when starting:

```dart
final session = await FlutterActivityKit.start(
  activityType: 'Delivery',
  title: 'Order confirmed',
  iosPushType: 'token',
);

final unregister = FlutterActivityKit.onPushToken((activityId, token) {
  backend.registerLiveActivityToken(activityId, token);
});
```

APNs request requires app-specific topic and credentials:

```text
apns-topic: com.example.app.push-type.liveactivity
apns-push-type: liveactivity
```

```json
{
  "aps": {
    "timestamp": 1788264000,
    "event": "update",
    "content-state": {
      "data": {"orderId": "42"},
      "title": "Order update",
      "message": "Driver is nearby",
      "status": "Arriving",
      "progress": 0.9
    }
  }
}
```

`getPushToStartToken()` uses package's generic `FlutterActivityAttributes` type.

## Reactive controller

```dart
final controller = ActivityController<OrderState>(
  initialState: initialOrder,
  activityType: 'Delivery',
  stateToMap: (state) => {
    'status': state.status,
    'progress': state.progress,
    'message': state.message,
  },
);

controller.syncErrors.listen(logActivityError);
await controller.start();
controller.value = nextOrder;
await controller.end(finalState: deliveredOrder);
controller.dispose();
```

Explicit `start`, `updateState`, `syncImmediately`, and `end` calls return errors.
Automatic debounced updates report through `syncErrors`, `lastSyncError`, and
Flutter error reporting.

## Tests

```bash
flutter analyze
flutter test
cd example && flutter build apk --debug
cd example && flutter build ios --simulator
dart pub publish --dry-run
```

## License

MIT
