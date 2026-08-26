import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(AppIntents)
import AppIntents
#endif

/// Generic ActivityAttributes bridging arbitrary JSON payloads from Flutter to WidgetKit.
#if canImport(ActivityKit)
@available(iOS 16.1, *)
public struct FlutterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Dynamic payload dictionary serialized as JSON string or key-value map.
        public var data: [String: String]
        public var progress: Double?
        public var title: String?
        public var message: String?
        public var status: String?

        public init(
            data: [String: String] = [:],
            progress: Double? = nil,
            title: String? = nil,
            message: String? = nil,
            status: String? = nil
        ) {
            self.data = data
            self.progress = progress
            self.title = title
            self.message = message
            self.status = status
        }
    }

    /// The activity identifier or type
    public var activityType: String

    /// Static attributes dictionary
    public var staticData: [String: String]

    public init(activityType: String, staticData: [String: String] = [:]) {
        self.activityType = activityType
        self.staticData = staticData
    }
}

#if canImport(AppIntents)
/// Background action intent that executes without opening the main app.
@available(iOS 17.0, *)
public struct FlutterActivityActionIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Flutter Activity Action"
    public static var isDiscoverable: Bool = false

    @Parameter(title: "Activity ID")
    public var activityId: String

    @Parameter(title: "Action ID")
    public var actionId: String

    public init() {
        self.activityId = ""
        self.actionId = ""
    }

    public init(activityId: String, actionId: String) {
        self.activityId = activityId
        self.actionId = actionId
    }

    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(
            name: NSNotification.Name("FlutterActivityKitActionEvent"),
            object: nil,
            userInfo: ["activityId": activityId, "actionId": actionId]
        )
        return .result()
    }
}

/// Foreground action intent that opens the main app when run and dispatches the action to Flutter.
@available(iOS 17.0, *)
public struct FlutterActivityOpenAppIntent: AppIntent {
    public static var title: LocalizedStringResource = "Flutter Activity Open App Action"
    public static var isDiscoverable: Bool = false
    public static var openAppWhenRun: Bool = true

    @Parameter(title: "Activity ID")
    public var activityId: String

    @Parameter(title: "Action ID")
    public var actionId: String

    public init() {
        self.activityId = ""
        self.actionId = ""
    }

    public init(activityId: String, actionId: String) {
        self.activityId = activityId
        self.actionId = actionId
    }

    @MainActor
    public func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(
            name: NSNotification.Name("FlutterActivityKitActionEvent"),
            object: nil,
            userInfo: ["activityId": activityId, "actionId": actionId]
        )
        return .result()
    }
}
#endif
#endif
