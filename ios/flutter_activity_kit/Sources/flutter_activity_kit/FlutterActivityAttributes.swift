import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Generic ActivityAttributes bridging arbitrary JSON payloads from Flutter to WidgetKit.
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
#endif
