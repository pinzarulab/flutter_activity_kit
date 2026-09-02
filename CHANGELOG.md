# Changelog

## 0.6.1

- **iOS Deep Linking & Action Button Fix**: Changed `openApp` behavior in SwiftUI `ActionButton` to correctly render `Link` elements instead of background intents, allowing `FlutterActivityKit.onAction()` callbacks to reliably execute in Dart when tapping Dynamic Island buttons.
- **Native iOS Haptic Engine Manager**: Replaced heavy `AlertConfiguration` overrides with a custom `HapticEngineManager` and `UINotificationFeedbackGenerator`. This allows for distinct, subtle custom haptics (success, warning, light/medium/heavy impact, selection) during silent widget updates.
- **iOS 17 Widget Interception Fix**: Removed overlapping `.widgetURL` constraints that were swallowing tap gestures in the expanded Dynamic Island.
- **Simulator Sound Fallback**: Added `AudioServicesPlaySystemSound` fallback to iOS haptics engine and `HapticFeedback.vibrate()` to Dart example app to aid testing on iOS Simulators lacking physical haptic motors.

## 0.6.0

- **Android 16 Rich Ongoing Notifications (Status Bar Chips)**:
  - Added `AndroidRichOngoingOptions` with `statusChipText`, `statusChipIcon`, `statusChipColor`, and `isProminentChip`.
  - Unlocks persistent status bar chips (Android's official equivalent to Dynamic Island) with graceful fallback on Android 7.0–15.
- **Dynamic Island Bounces & Haptic Milestone Alerts**:
  - Added `ActivityHapticFeedback` enum (`none`, `success`, `warning`, `error`, `impactLight`, `impactMedium`, `impactHeavy`, `selection`).
  - Added native iOS ActivityKit `AlertConfiguration(title:body:sound:)` for Dynamic Island pulse/bounce animations and system sounds.
  - Added native vibration effects on Android.
- **Static Map & Route Snapshot Generator**:
  - Added `MapSnapshotGenerator`, `LatLng`, and `MapMarker` for generating Google Maps Static API and Mapbox dark-mode/satellite snapshot URLs with markers and route paths.

- **Pure Dart UI DSL & Transpiler**:
  - Build 100% custom Live Activity widgets in pure Dart using `LAWidget`, `LAColumn`, `LARow`, `LAText`, `LAImage`, `LAProgressBar`, `LAButton`, `LASpacer`, `LAContainer`, and `LATimer`.
  - Transpile Dart widget definitions directly into native SwiftUI WidgetKit code without writing Swift.
- **Smart Swift Generator & Folder Scanning**:
  - Automatically scans `lib/live_activity_widgets/` for Dart widget definitions.
  - Added pre-configured, production-ready templates: `navigation` (Mini-Map route canvas), `delivery`, `sports`, `workout`, and `generic`.
- **Mini-Map & Ride Tracking**:
  - Added Vector Route Canvas for navigation and ridesharing Live Activities in Dynamic Island and Lock Screen.
- **Lock Screen Banner Layout Optimization**:
  - Compacted Lock Screen banner padding and controls to prevent clipping within Apple's 160pt height constraint.
- Added explicit timer removal with `clearTimer`, including delivery arrival updates.
- Stopped Android countdowns at zero using a persisted native expiration alarm.
- Kept iOS timer capsules compact and right-aligned instead of filling the row.

## 0.5.0

- Fixed `ActivitySession` snapshots so sequential quick updates preserve prior state and ended sessions report `ended`.
- Added explicit Android action behavior (`background`, `opensApp`, and `deepLink`) plus action payloads.
- Added cold-start action buffering and reliable foreground iOS deep-link routing.
- Removed broken cross-process iOS `NotificationCenter` AppIntent bridge; documented native background-action boundary.
- Persisted Android activity metadata and notification IDs across process restarts.
- Added Android not-found errors, lifecycle events, delayed dismissal, alert sounds, large icons, categories, visibility timestamps, and priority handling.
- Stopped swallowing Android notification permission failures.
- Added `iosPushType` to quick start for APNs push-to-update token requests.
- Added controller sync error reporting and synchronization/end ordering.
- Fixed Swift generator to emit plugin-compatible `FlutterActivityAttributes`.
- Added CI verification for analysis, tests, Android build, iOS build, and publish validation.
- Corrected package docs and CocoaPods metadata.
- Fixed duplicate iOS action delivery caused by routing the same URL through
  `SceneDelegate`, `AppDelegate`, and the plugin.
- Fixed workout taps incorrectly opening match statistics and routed Call Driver
  through the app before launching the phone dialer.

## 0.4.1

- **Documentation Overhaul & Developer Guide**:
  - Comprehensive documentation covering the Fluent Quick-Start API, reactive `ActivityController<T>`, and `ActivityActionListener`.
  - Added full guide for backend integration with WebSockets, Firebase Cloud Firestore, Apple APNs HTTP/2 Live Activity Pushes, and FCM background handlers.
  - Added setup instructions for Swift Package Manager (SPM), iOS actions, and Android 13+ notification permissions.
  - Added native chronometer and countdown guides.
- **Smart Concurrency Debouncing in `ActivityController`**:
  - Built-in `syncDebounce` (150ms) and in-flight concurrency queue to eliminate platform channel throttling and latency during rapid UI state mutations.

## 0.4.0

- **Fluent Quick-Start API (`FlutterActivityKit.start()`, `quickUpdate()`, `quickEnd()`)**:
  - Start, update, and end Live Activities and Ongoing Notifications in 1 concise line of code without needing nested wrapper classes.
  - Automatically resolves hardware countdowns, custom activity types, and channel options.
- **Reactive State Controller (`ActivityController<T>`)**:
  - Bind any Flutter data model or `ValueNotifier` directly to an activity.
  - Updating `controller.value = newState` automatically pushes synchronization to the Dynamic Island & Android Notification.
  - Includes `ActivityBuilder<T>` widget for reactive UI binding.
- **Declarative Action Routing & Push Hooks (`FlutterActivityKit.onAction()`, `ActivityActionListener`)**:
  - Register action callbacks anywhere without manual `StreamSubscription` lifecycle management.
  - `FlutterActivityKit.onPushToken()` helper for easy backend token synchronization.
- **Updated Example App**:
  - Refactored example app to showcase the Fluent Quick-Start API, reactive `ActivityController`, `ActivityBuilder`, and `ActivityActionListener`.

## 0.3.0

- **Fluent Quick-Start API (`FlutterActivityKit.start()`, `quickUpdate()`, `quickEnd()`)**:
  - Start, update, and end Live Activities and Ongoing Notifications in 1 concise line of code without needing nested wrapper classes.
  - Automatically resolves hardware countdowns, custom activity types, and channel options.
- **Reactive State Controller (`ActivityController<T>`)**:
  - Bind any Flutter data model or `ValueNotifier` directly to an activity.
  - Updating `controller.value = newState` automatically pushes synchronization to the Dynamic Island & Android Notification.
  - Includes `ActivityBuilder<T>` widget for reactive UI binding.
- **Declarative Action Routing & Push Hooks (`FlutterActivityKit.onAction()`, `ActivityActionListener`)**:
  - Register action callbacks anywhere without manual `StreamSubscription` lifecycle management.
  - `FlutterActivityKit.onPushToken()` helper for easy backend token synchronization.
- **Native Hardware Countdowns & Chronometers (`ActivityTimer`)**:
  - Hardware-rendered real-time countdown timers and elapsed stopwatches.
  - Rendered by SwiftUI on Dynamic Island and Lock Screen using `Text(timerInterval:pauseTime:countsDown:)` without a Dart polling loop.
  - Rendered in Android Ongoing Notifications via SystemUI `setUsesChronometer` and `setChronometerCountDown`.
  - Added `ActivityTimer.countdown()` and `ActivityTimer.chronometer()` factory constructors.
- **Deep Linking & Foreground Intent Launching**:
  - Added foreground app-opening actions from Dynamic Island / Lock Screen buttons.
  - Native Phone dialer launcher (`Link(destination: "tel://...")`).
  - `SceneDelegate` / `AppDelegate` URL context bridge.
  - Android `PendingIntent.getActivity` with `FLAG_ACTIVITY_SINGLE_TOP` for seamless foreground navigation.

## 0.2.0

- **Interactive iOS actions**:
  - Added initial action-routing support; replaced in 0.5.0 because extension-local notifications cannot reach Dart across processes.
  - Fixed platform channel threading to guarantee all action events dispatch on the platform main thread.
- **Android Runtime Permission (`POST_NOTIFICATIONS`)**:
  - Added native `FlutterActivityKit.requestPermissions()` with automated `ActivityAware` runtime permission handling on Android 13+ (API 33+).
- **iOS 16.1 & 16.2+ Compatibility**:
  - Full compatibility branching between `Activity.content` (iOS 16.2+) and `Activity.contentState` (iOS 16.1).
  - Made `IOSOptions.pushType` optional/nullable for seamless local activities without requiring remote APNs certificates.
- **Swift Package Manager (SPM)**:
  - Added full Swift Package Manager compatibility for modern Flutter iOS builds.
- **Automatic Live Sports Match Simulation**:
  - Added real-time auto-updating match simulation to the example application.

## 0.1.0

- Initial release of `flutter_activity_kit`.
- **Unified Declarative API**:
  - `startActivity`, `updateActivity`, `endActivity`, `listActivities`, `getActivityState`, `areActivitiesEnabled`.
- **iOS Live Activities & Dynamic Island Support**:
  - Full Swift ActivityKit bridge for iOS 16.1+.
  - Support for Dynamic Island (Expanded, Compact, Minimal) and Lock Screen banners.
  - Push-to-update and push-to-start token management and streams.
  - Live activity state change streams.
  - Swift code generator CLI tool (`dart run flutter_activity_kit:generate_swift`).
- **Android Ongoing Notifications Support**:
  - Ongoing, pinned notification channel management.
  - Progress bars, chronometer/countdown timers, badges, and custom action buttons.
  - Broadcast receiver bridging action clicks back to Dart event stream.
- **Flutter In-App Previews**:
  - `DynamicIslandPreview` and `OngoingNotificationPreview` widgets to inspect and preview live activities inside any Flutter view.
- **Rich Models & Configuration**:
  - `ActivityAttributes`, `ActivityContentState`, `ActivityContent`, `ActivityAlert`, `ActivityAction`, `AndroidOptions`, `IOSOptions`.
- Comprehensive example application with delivery tracking, sports live score, and timer use cases.
