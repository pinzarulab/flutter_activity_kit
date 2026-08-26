//
//  LiveActivityWidgetLiveActivity.swift
//  LiveActivityWidget
//

import ActivityKit
import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - Flutter Activity Attributes (Matches Flutter ActivityKit Bridge)
public struct FlutterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var data: [String: String]
        public var progress: Double?
        public var title: String?
        public var message: String?
        public var status: String?

        // Hardware-rendered real-time Countdown / Chronometer Timer
        public var timerStartDate: Date?
        public var timerTargetDate: Date?
        public var timerCountsDown: Bool?
        public var timerIsPaused: Bool?

        public init(
            data: [String: String] = [:],
            progress: Double? = nil,
            title: String? = nil,
            message: String? = nil,
            status: String? = nil,
            timerStartDate: Date? = nil,
            timerTargetDate: Date? = nil,
            timerCountsDown: Bool? = nil,
            timerIsPaused: Bool? = nil
        ) {
            self.data = data
            self.progress = progress
            self.title = title
            self.message = message
            self.status = status
            self.timerStartDate = timerStartDate
            self.timerTargetDate = timerTargetDate
            self.timerCountsDown = timerCountsDown
            self.timerIsPaused = timerIsPaused
        }
    }

    public var activityType: String
    public var staticData: [String: String]

    public init(activityType: String, staticData: [String: String] = [:]) {
        self.activityType = activityType
        self.staticData = staticData
    }
}

// MARK: - Interactive AppIntents for iOS 17+
#if canImport(AppIntents)
/// Background action intent
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

/// Foreground action intent that opens the main app
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

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            let isDelivery = context.attributes.activityType.contains("Delivery") || context.attributes.staticData["orderId"] != nil
            let accentColor: Color = isDelivery ? .orange : .green
            let iconName: String = isDelivery ? "bag.fill" : "sportscourt.fill"

            // Lock Screen Banner
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(context.state.title ?? (isDelivery ? "Food Order" : "Match Update"), systemImage: iconName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()

                    // Hardware Real-Time Countdown / Chronometer Timer
                    if let targetDate = context.state.timerTargetDate {
                        let startDate = context.state.timerStartDate ?? Date()
                        let countsDown = context.state.timerCountsDown ?? true
                        HStack(spacing: 4) {
                            Image(systemName: countsDown ? "timer" : "stopwatch.fill")
                                .font(.caption2)
                                .foregroundColor(accentColor)
                            Text(timerInterval: startDate...targetDate, pauseTime: nil, countsDown: countsDown)
                                .font(.caption)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(accentColor)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(accentColor.opacity(0.3)))
                    } else if let status = context.state.status {
                        Text(status)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(accentColor.opacity(0.3)))
                            .foregroundColor(accentColor)
                    }
                }

                if let message = context.state.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }

                if let progress = context.state.progress {
                    ProgressView(value: progress, total: 1.0)
                        .tint(accentColor)
                }

                // Action Buttons Row
                HStack(spacing: 8) {
                    if isDelivery {
                        Link(destination: URL(string: "tel://15550199")!) {
                            Label("Call Driver", systemImage: "phone.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)

                        #if canImport(AppIntents)
                        if #available(iOS 17.0, *) {
                            Button(intent: FlutterActivityActionIntent(activityId: context.activityID, actionId: "add_tip")) {
                                Label("Add Tip ($2)", systemImage: "dollarsign.circle.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }
                        #endif
                    } else {
                        #if canImport(AppIntents)
                        if #available(iOS 17.0, *) {
                            Button(intent: FlutterActivityActionIntent(activityId: context.activityID, actionId: "mute_match")) {
                                Label("Mute Match", systemImage: "bell.slash.fill")
                                    .font(.caption2)
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)

                            Button(intent: FlutterActivityOpenAppIntent(activityId: context.activityID, actionId: "match_stats")) {
                                Label("Match Stats", systemImage: "chart.bar.fill")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        } else {
                            Link(destination: URL(string: "flutteractivitykit://match_stats")!) {
                                Label("Match Stats", systemImage: "chart.bar.fill")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                        }
                        #else
                        Link(destination: URL(string: "flutteractivitykit://match_stats")!) {
                            Label("Match Stats", systemImage: "chart.bar.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        #endif
                    }
                }
                .padding(.top, 2)
            }
            .padding(16)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
            .widgetURL(URL(string: isDelivery ? "flutteractivitykit://delivery_order" : "flutteractivitykit://match_stats"))
        } dynamicIsland: { context in
            let isDelivery = context.attributes.activityType.contains("Delivery") || context.attributes.staticData["orderId"] != nil
            let accentColor: Color = isDelivery ? .orange : .green
            let iconName: String = isDelivery ? "bag.fill" : "sportscourt.fill"

            return DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: iconName)
                            .foregroundColor(accentColor)
                        Text(context.state.status ?? "")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }

                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    if let targetDate = context.state.timerTargetDate {
                        let startDate = context.state.timerStartDate ?? Date()
                        let countsDown = context.state.timerCountsDown ?? true
                        HStack(spacing: 2) {
                            Image(systemName: countsDown ? "timer" : "stopwatch.fill")
                                .font(.caption2)
                                .foregroundColor(accentColor)
                            Text(timerInterval: startDate...targetDate, pauseTime: nil, countsDown: countsDown)
                                .font(.caption)
                                .fontWeight(.bold)
                                .monospacedDigit()
                                .foregroundColor(accentColor)
                        }
                        .padding(.trailing, 8)
                    } else if let progress = context.state.progress {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                            .padding(.trailing, 8)
                    } else if let eta = context.state.data["eta"] {
                        Text(eta)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                            .padding(.trailing, 8)
                    }
                }

                // Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title ?? "")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(context.state.message ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if let progress = context.state.progress {
                            ProgressView(value: progress, total: 1.0)
                                .tint(accentColor)
                        }

                        HStack(spacing: 8) {
                            if isDelivery {
                                Link(destination: URL(string: "tel://15550199")!) {
                                    Label("Call", systemImage: "phone.fill")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            } else {
                                #if canImport(AppIntents)
                                if #available(iOS 17.0, *) {
                                    Button(intent: FlutterActivityActionIntent(activityId: context.activityID, actionId: "mute_match")) {
                                        Label("Mute", systemImage: "bell.slash.fill")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(.white)

                                    Button(intent: FlutterActivityOpenAppIntent(activityId: context.activityID, actionId: "match_stats")) {
                                        Label("Stats", systemImage: "chart.bar.fill")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                } else {
                                    Link(destination: URL(string: "flutteractivitykit://match_stats")!) {
                                        Label("Stats", systemImage: "chart.bar.fill")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                }
                                #else
                                Link(destination: URL(string: "flutteractivitykit://match_stats")!) {
                                    Label("Stats", systemImage: "chart.bar.fill")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                                #endif
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: iconName)
                        .foregroundColor(accentColor)
                    Text(context.state.status ?? "")
                        .font(.caption2)
                }
            } compactTrailing: {
                if let targetDate = context.state.timerTargetDate {
                    let startDate = context.state.timerStartDate ?? Date()
                    let countsDown = context.state.timerCountsDown ?? true
                    Text(timerInterval: startDate...targetDate, pauseTime: nil, countsDown: countsDown)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .foregroundColor(accentColor)
                } else if let progress = context.state.progress {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                } else if let eta = context.state.data["eta"] {
                    Text(eta)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                }
            } minimal: {
                Image(systemName: iconName)
                    .foregroundColor(accentColor)
            }
        }
    }
}
