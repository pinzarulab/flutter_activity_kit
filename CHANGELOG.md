# Changelog

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
