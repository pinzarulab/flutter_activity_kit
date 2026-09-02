//
//  LiveActivityWidgetLiveActivity.swift
//  LiveActivityWidget
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// MARK: - iOS 17+ Background Interactive Live Activity Intent (No App Launch Required!)
@available(iOS 17.0, *)
public struct ActivityKitActionIntent: LiveActivityIntent {
    public static var title: LocalizedStringResource = "Live Activity Action"
    public static var isDiscoverable: Bool = false
    public static var openAppWhenRun: Bool = false

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
        // Direct in-background Activity update without opening the Flutter app
        if let activity = Activity<FlutterActivityAttributes>.activities.first(where: { $0.id == activityId }) {
            let updatedData = activity.content.state.data
            var progress = activity.content.state.progress ?? 0.0
            var title = activity.content.state.title
            var message = activity.content.state.message
            var status = activity.content.state.status

            switch actionId {
            case "haptic_success":
                progress = min(1.0, progress + 0.15)
                status = "Success ✅"
                message = "Milestone recorded in background!"
                title = "Mission In Progress ⚡"
            case "haptic_warning":
                status = "Warning ⚠️"
                message = "Caution threshold flagged in background!"
            case "haptic_heavy":
                status = "Heavy 💥"
                message = "Heavy impact logged in background!"
            case "haptic_complete":
                progress = 1.0
                status = "Completed 🏆"
                message = "Mission accomplished in background!"
            case "mute_match":
                status = "Muted 🔕"
                message = "Match notifications muted in background"
            case "cancel_order":
                status = "Cancelled ❌"
                message = "Order cancelled from Live Activity"
            default:
                status = "Tapped \(actionId)"
            }

            let newState = FlutterActivityAttributes.ContentState(
                data: updatedData,
                progress: progress,
                title: title,
                message: message,
                status: status,
                timerStartDate: activity.content.state.timerStartDate,
                timerTargetDate: activity.content.state.timerTargetDate,
                timerCountsDown: activity.content.state.timerCountsDown,
                timerIsPaused: activity.content.state.timerIsPaused
            )

            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }

        return .result()
    }
}

// MARK: - Reusable Action Button (Background AppIntent vs Open App Deep Link)
struct ActionButton: View {
    let activityId: String
    let actionId: String
    let title: String
    let systemImage: String
    let tintColor: Color
    var isProminent: Bool = true
    var fontSize: CGFloat = 10
    var openApp: Bool = false

    @ViewBuilder
    var body: some View {
        if openApp {
            if isProminent {
                Link(destination: URL(string: "flutteractivitykit://action/\(actionId)?activityId=\(activityId)")!) {
                    Label(title, systemImage: systemImage)
                        .font(.system(size: fontSize, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(tintColor)
            } else {
                Link(destination: URL(string: "flutteractivitykit://action/\(actionId)?activityId=\(activityId)")!) {
                    Label(title, systemImage: systemImage)
                        .font(.system(size: fontSize, weight: .bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(tintColor)
            }
        } else {
            if #available(iOS 17.0, *) {
                if isProminent {
                    Button(intent: ActivityKitActionIntent(activityId: activityId, actionId: actionId)) {
                        Label(title, systemImage: systemImage)
                            .font(.system(size: fontSize, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(tintColor)
                } else {
                    Button(intent: ActivityKitActionIntent(activityId: activityId, actionId: actionId)) {
                        Label(title, systemImage: systemImage)
                            .font(.system(size: fontSize, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(tintColor)
                }
            } else {
                if isProminent {
                    Link(destination: URL(string: "flutteractivitykit://action/\(actionId)?activityId=\(activityId)")!) {
                        Label(title, systemImage: systemImage)
                            .font(.system(size: fontSize, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(tintColor)
                } else {
                    Link(destination: URL(string: "flutteractivitykit://action/\(actionId)?activityId=\(activityId)")!) {
                        Label(title, systemImage: systemImage)
                            .font(.system(size: fontSize, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(tintColor)
                }
            }
        }
    }
}

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

// MARK: - Beautiful Route Mini-Map
struct MiniMapView: View {
    let progress: Double
    let eta: String
    let accentColor: Color

    var body: some View {
        let roadHeight: CGFloat = 22
        let carSize: CGFloat = 18

        VStack(spacing: 3) {
            // Stylized Route Map Track
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: roadHeight / 2)
                    .fill(Color(white: 0.16))
                    .frame(height: roadHeight)
                    .overlay(
                        HStack(spacing: 4) {
                            ForEach(0..<14) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 8, height: 1.5)
                            }
                        }
                    )

                GeometryReader { geo in
                    let totalWidth = geo.size.width - carSize
                    let currentX = (carSize / 2) + (totalWidth * CGFloat(progress.clamped(to: 0.0...1.0)))
                    let midY = roadHeight / 2

                    // Active traveled line
                    Path { path in
                        path.move(to: CGPoint(x: carSize / 2, y: midY))
                        path.addLine(to: CGPoint(x: currentX, y: midY))
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                    // Origin Pin
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .position(x: carSize / 2, y: midY)

                    // Destination Pin
                    ZStack {
                        Circle().fill(Color.green).frame(width: 10, height: 10)
                        Image(systemName: "flag.fill").font(.system(size: 5.5)).foregroundColor(.white)
                    }
                    .position(x: geo.size.width - (carSize / 2), y: midY)

                    // Moving Car Marker (🚗)
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: carSize, height: carSize)
                            .shadow(color: accentColor.opacity(0.6), radius: 2)
                        Image(systemName: "car.fill")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .position(x: currentX, y: midY)
                }
                .frame(height: roadHeight)
            }

            // Route Waypoint Subtitles
            HStack {
                HStack(spacing: 3) {
                    Circle().fill(Color.blue).frame(width: 4, height: 4)
                    Text("Pickup")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 3) {
                    Text("ETA: \(eta)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(accentColor)
                    Image(systemName: "arrow.right").font(.system(size: 7)).foregroundColor(.gray)
                    Circle().fill(Color.green).frame(width: 4, height: 4)
                    Text("Drop-off")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.black.opacity(0.4))
        )
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct LiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            let isRide = context.attributes.activityType.contains("Ride") || context.state.data["driverLat"] != nil
            let isDelivery = context.attributes.activityType.contains("Delivery") || context.attributes.staticData["orderId"] != nil
            let isAlerts = context.attributes.activityType.contains("Alert") || context.attributes.staticData["missionId"] != nil
            let isSports = context.attributes.activityType.contains("Sports") || context.attributes.staticData["matchId"] != nil

            let accentColor: Color = isRide ? .yellow : (isDelivery ? .orange : (isAlerts ? .purple : .green))
            let iconName: String = isRide ? "car.fill" : (isDelivery ? "bag.fill" : (isAlerts ? "bolt.shield.fill" : "sportscourt.fill"))
            let progress = context.state.progress ?? 0.0
            let eta = context.state.data["eta"] ?? "5 mins"

            // MARK: - Lock Screen Banner
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(context.state.title ?? (isRide ? "Ride Tracking" : (isDelivery ? "Food Order" : (isAlerts ? "Haptics & Alerts" : "Match Update"))), systemImage: iconName)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()

                    // Real-time Timer / Status Capsule
                    if let targetDate = context.state.timerTargetDate {
                        let startDate = context.state.timerStartDate ?? Date()
                        let countsDown = context.state.timerCountsDown ?? true
                        HStack(spacing: 3) {
                            Image(systemName: countsDown ? "timer" : "stopwatch.fill")
                                .font(.caption2)
                                .foregroundColor(accentColor)
                            safeTimerText(startDate: startDate, targetDate: targetDate, countsDown: countsDown, font: .caption2, color: accentColor)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(accentColor.opacity(0.25)))
                    } else if let status = context.state.status {
                        Text(status)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accentColor.opacity(0.25)))
                            .foregroundColor(accentColor)
                    }
                }

                if let message = context.state.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                // Route Map or Progress
                if isRide {
                    MiniMapView(progress: progress, eta: eta, accentColor: accentColor)
                } else if let progress = context.state.progress {
                    ProgressView(value: progress, total: 1.0)
                        .tint(accentColor)
                }

                // Action Buttons Row on Lock Screen
                HStack(spacing: 6) {
                    if isRide {
                        ActionButton(activityId: context.activityID, actionId: "call_driver", title: "Call Driver", systemImage: "phone.fill", tintColor: .yellow, isProminent: true, fontSize: 11, openApp: true)
                        ActionButton(activityId: context.activityID, actionId: "share_eta", title: "Share ETA", systemImage: "square.and.arrow.up.fill", tintColor: .white, isProminent: false, fontSize: 11, openApp: true)
                    } else if isDelivery {
                        ActionButton(activityId: context.activityID, actionId: "call_driver", title: "Call Courier", systemImage: "phone.fill", tintColor: .orange, isProminent: true, fontSize: 11, openApp: true)
                        ActionButton(activityId: context.activityID, actionId: "cancel_order", title: "Cancel", systemImage: "xmark.circle.fill", tintColor: .white, isProminent: false, fontSize: 11, openApp: true)
                    } else if isAlerts {
                        ActionButton(activityId: context.activityID, actionId: "haptic_success", title: "Success", systemImage: "checkmark.circle.fill", tintColor: .green, isProminent: true, openApp: true)
                        ActionButton(activityId: context.activityID, actionId: "haptic_warning", title: "Warning", systemImage: "exclamationmark.triangle.fill", tintColor: .orange, isProminent: true, openApp: true)
                        ActionButton(activityId: context.activityID, actionId: "haptic_heavy", title: "Heavy", systemImage: "bolt.fill", tintColor: .purple, isProminent: true, openApp: true)
                        ActionButton(activityId: context.activityID, actionId: "haptic_complete", title: "Finish", systemImage: "flag.fill", tintColor: .red, isProminent: false, openApp: true)
                    } else {
                        ActionButton(activityId: context.activityID, actionId: "mute_match", title: "Mute Match", systemImage: "bell.slash.fill", tintColor: .white, isProminent: false, fontSize: 11, openApp: false)
                        ActionButton(activityId: context.activityID, actionId: "match_stats", title: "Match Stats", systemImage: "chart.bar.fill", tintColor: .green, isProminent: true, fontSize: 11, openApp: true)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
            .widgetURL(isRide
                ? URL(string: "flutteractivitykit://action/view_ride?activityId=\(context.activityID)")
                : (isSports
                    ? URL(string: "flutteractivitykit://action/match_stats?activityId=\(context.activityID)")
                    : nil
                )
            )
        } dynamicIsland: { context in
            let isRide = context.attributes.activityType.contains("Ride") || context.state.data["driverLat"] != nil
            let isDelivery = context.attributes.activityType.contains("Delivery") || context.attributes.staticData["orderId"] != nil
            let isAlerts = context.attributes.activityType.contains("Alert") || context.attributes.staticData["missionId"] != nil
            let isSports = context.attributes.activityType.contains("Sports") || context.attributes.staticData["matchId"] != nil

            let accentColor: Color = isRide ? .yellow : (isDelivery ? .orange : (isAlerts ? .purple : .green))
            let iconName: String = isRide ? "car.fill" : (isDelivery ? "bag.fill" : (isAlerts ? "bolt.shield.fill" : "sportscourt.fill"))
            let progress = context.state.progress ?? 0.0
            let eta = context.state.data["eta"] ?? "5 mins"

            return DynamicIsland {
                // MARK: - Expanded Leading (Icon + Title)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: iconName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(accentColor)
                        Text(context.state.title ?? (isRide ? "Ride Tracking" : (isAlerts ? "Mission Alert" : "Activity")))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                    .padding(.top, 4)
                }

                // MARK: - Expanded Trailing (ETA Badge / Timer)
                DynamicIslandExpandedRegion(.trailing) {
                    if let targetDate = context.state.timerTargetDate {
                        let startDate = context.state.timerStartDate ?? Date()
                        let countsDown = context.state.timerCountsDown ?? true
                        HStack(spacing: 2) {
                            Image(systemName: countsDown ? "timer" : "stopwatch.fill")
                                .font(.caption2)
                                .foregroundColor(accentColor)
                            safeTimerText(startDate: startDate, targetDate: targetDate, countsDown: countsDown, font: .caption2, color: accentColor)
                        }
                        .padding(.trailing, 8)
                        .padding(.top, 4)
                    } else if let eta = context.state.data["eta"] {
                        Text(eta)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentColor)
                            .padding(.trailing, 8)
                            .padding(.top, 4)
                    } else if let progress = context.state.progress {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentColor)
                            .padding(.trailing, 8)
                            .padding(.top, 4)
                    }
                }

                // MARK: - Expanded Bottom (Subtitle + Route Map + Full Prominent Buttons)
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Driver / Vehicle Subtitle
                        if let message = context.state.message {
                            Text(message)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)
                        }

                        // Route Map or Progress
                        if isRide {
                            MiniMapView(progress: progress, eta: eta, accentColor: accentColor)
                        } else if let progress = context.state.progress {
                            ProgressView(value: progress, total: 1.0)
                                .tint(accentColor)
                        }

                        // Full-width, prominent Action Buttons
                        HStack(spacing: 6) {
                            if isRide {
                                ActionButton(activityId: context.activityID, actionId: "call_driver", title: "Call Driver", systemImage: "phone.fill", tintColor: .yellow, isProminent: true, fontSize: 11, openApp: true)
                                ActionButton(activityId: context.activityID, actionId: "share_eta", title: "Share ETA", systemImage: "square.and.arrow.up.fill", tintColor: .white, isProminent: false, fontSize: 11, openApp: true)
                            } else if isDelivery {
                                ActionButton(activityId: context.activityID, actionId: "call_driver", title: "Call Courier", systemImage: "phone.fill", tintColor: .orange, isProminent: true, fontSize: 11, openApp: true)
                                ActionButton(activityId: context.activityID, actionId: "cancel_order", title: "Cancel", systemImage: "xmark.circle.fill", tintColor: .white, isProminent: false, fontSize: 11, openApp: true)
                            } else if isAlerts {
                                ActionButton(activityId: context.activityID, actionId: "haptic_success", title: "Success", systemImage: "checkmark.circle.fill", tintColor: .green, isProminent: true, openApp: true)
                                ActionButton(activityId: context.activityID, actionId: "haptic_warning", title: "Warning", systemImage: "exclamationmark.triangle.fill", tintColor: .orange, isProminent: true, openApp: true)
                                ActionButton(activityId: context.activityID, actionId: "haptic_heavy", title: "Heavy", systemImage: "bolt.fill", tintColor: .purple, isProminent: true, openApp: true)
                                ActionButton(activityId: context.activityID, actionId: "haptic_complete", title: "Finish", systemImage: "flag.fill", tintColor: .red, isProminent: false, openApp: true)
                            } else {
                                ActionButton(activityId: context.activityID, actionId: "mute_match", title: "Mute Match", systemImage: "bell.slash.fill", tintColor: .white, isProminent: false, fontSize: 11, openApp: false)
                                ActionButton(activityId: context.activityID, actionId: "match_stats", title: "Match Stats", systemImage: "chart.bar.fill", tintColor: .green, isProminent: true, fontSize: 11, openApp: true)
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
                    safeTimerText(startDate: startDate, targetDate: targetDate, countsDown: countsDown, font: .caption2, color: accentColor)
                } else if let eta = context.state.data["eta"] {
                    Text(eta)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                } else if let progress = context.state.progress {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                }
            } minimal: {
                Image(systemName: iconName)
                    .foregroundColor(accentColor)
            }
            .widgetURL(isRide
                ? URL(string: "flutteractivitykit://action/view_ride?activityId=\(context.activityID)")
                : (isSports
                    ? URL(string: "flutteractivitykit://action/match_stats?activityId=\(context.activityID)")
                    : nil
                )
            )
        }
    }

    @ViewBuilder
    private func safeTimerText(startDate: Date, targetDate: Date, countsDown: Bool, font: Font, color: Color) -> some View {
        let lower = min(startDate, targetDate)
        let upper = max(startDate, targetDate)
        let safeRange = (lower == upper) ? lower...upper.addingTimeInterval(1) : lower...upper
        Text(timerInterval: safeRange, pauseTime: nil, countsDown: countsDown)
            .font(font)
            .fontWeight(.bold)
            .monospacedDigit()
            .fixedSize(horizontal: true, vertical: false)
            .foregroundColor(color)
    }
}
