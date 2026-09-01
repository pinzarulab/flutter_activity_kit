//
//  LiveActivityWidgetLiveActivity.swift
//  LiveActivityWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

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

// MARK: - Native Vector Route Mini-Map for Dynamic Island & Lock Screen
// In WidgetKit, interactive MapKit views are disallowed by Apple (showing 🚫).
// Production apps (Uber, Lyft, Apple Maps) use native SwiftUI vector route views.
struct MiniMapView: View {
    let progress: Double
    let eta: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 8) {
            // Stylized Route Map Canvas
            ZStack(alignment: .leading) {
                // Background Navigation Road
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.12))
                    .frame(height: 52)
                    .overlay(
                        // Dashed road centerlines
                        HStack(spacing: 6) {
                            ForEach(0..<12) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 12, height: 2)
                            }
                        }
                    )

                // Completed Route Highlight
                GeometryReader { geo in
                    let totalWidth = geo.size.width - 48
                    let currentX = 24 + (totalWidth * CGFloat(progress.clamped(to: 0.0...1.0)))

                    // Active traveled path line
                    Path { path in
                        path.move(to: CGPoint(x: 24, y: 26))
                        path.addLine(to: CGPoint(x: currentX, y: 26))
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))

                    // Pickup Origin Pin
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .position(x: 24, y: 26)

                    // Destination Pin
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                        Image(systemName: "flag.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    }
                    .position(x: geo.size.width - 24, y: 26)

                    // Moving Vehicle Marker (🚗)
                    ZStack {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 26, height: 26)
                            .shadow(color: accentColor.opacity(0.6), radius: 4)
                        Image(systemName: "car.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .position(x: currentX, y: 26)
                }
                .frame(height: 52)
            }

            // Route Waypoint Labels
            HStack {
                HStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 6, height: 6)
                    Text("Pickup (Market St)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("ETA: \(eta)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentColor)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("Drop-off")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
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
            let isSports = context.attributes.activityType.contains("Sports") || context.attributes.staticData["matchId"] != nil

            let accentColor: Color = isRide ? .yellow : (isDelivery ? .orange : .green)
            let iconName: String = isRide ? "car.fill" : (isDelivery ? "bag.fill" : "sportscourt.fill")
            let progress = context.state.progress ?? 0.0
            let eta = context.state.data["eta"] ?? "5 mins"

            // Lock Screen Banner
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(context.state.title ?? (isRide ? "Ride Tracking" : (isDelivery ? "Food Order" : "Match Update")), systemImage: iconName)
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
                            safeTimerText(startDate: startDate, targetDate: targetDate, countsDown: countsDown, font: .caption, color: accentColor)
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

                // 🗺️ Vector Route Mini-Map for Ride activities!
                if isRide {
                    MiniMapView(progress: progress, eta: eta, accentColor: accentColor)
                } else if let progress = context.state.progress {
                    ProgressView(value: progress, total: 1.0)
                        .tint(accentColor)
                }

                // Action Buttons Row on Lock Screen
                HStack(spacing: 8) {
                    if isRide {
                        Link(destination: URL(string: "flutteractivitykit://action/call_driver?activityId=\(context.activityID)")!) {
                            Label("Call Driver", systemImage: "phone.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.yellow)

                        Link(destination: URL(string: "flutteractivitykit://action/share_eta?activityId=\(context.activityID)")!) {
                            Label("Share ETA", systemImage: "square.and.arrow.up.fill")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    } else if isDelivery {
                        Link(destination: URL(string: "flutteractivitykit://action/call_driver?activityId=\(context.activityID)")!) {
                            Label("Call Driver", systemImage: "phone.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)

                        Link(destination: URL(string: "flutteractivitykit://action/cancel_order?activityId=\(context.activityID)")!) {
                            Label("Cancel", systemImage: "xmark.circle.fill")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    } else {
                        Link(destination: URL(string: "flutteractivitykit://action/mute_match?activityId=\(context.activityID)")!) {
                            Label("Mute Match", systemImage: "bell.slash.fill")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)

                        Link(destination: URL(string: "flutteractivitykit://action/match_stats?activityId=\(context.activityID)")!) {
                            Label("Match Stats", systemImage: "chart.bar.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding(.top, 2)
            }
            .padding(16)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
            .widgetURL(URL(string: isRide
                ? "flutteractivitykit://action/view_ride?activityId=\(context.activityID)"
                : (isSports
                    ? "flutteractivitykit://action/match_stats?activityId=\(context.activityID)"
                    : "flutteractivitykit://action/open_activity?activityId=\(context.activityID)"
                )
            ))
        } dynamicIsland: { context in
            let isRide = context.attributes.activityType.contains("Ride") || context.state.data["driverLat"] != nil
            let isDelivery = context.attributes.activityType.contains("Delivery") || context.attributes.staticData["orderId"] != nil

            let accentColor: Color = isRide ? .yellow : (isDelivery ? .orange : .green)
            let iconName: String = isRide ? "car.fill" : (isDelivery ? "bag.fill" : "sportscourt.fill")
            let progress = context.state.progress ?? 0.0
            let eta = context.state.data["eta"] ?? "5 mins"

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
                            safeTimerText(startDate: startDate, targetDate: targetDate, countsDown: countsDown, font: .caption, color: accentColor)
                        }
                        .padding(.trailing, 8)
                    } else if let eta = context.state.data["eta"] {
                        Text(eta)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                            .padding(.trailing, 8)
                    } else if let progress = context.state.progress {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(accentColor)
                            .padding(.trailing, 8)
                    }
                }

                // Expanded Bottom -> Vector Route Mini-Map embedded directly into Expanded Dynamic Island!
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(context.state.title ?? "")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(context.state.message ?? "")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }

                        if isRide {
                            // 🗺️ Vector Route Mini-Map!
                            MiniMapView(progress: progress, eta: eta, accentColor: accentColor)
                        } else if let progress = context.state.progress {
                            ProgressView(value: progress, total: 1.0)
                                .tint(accentColor)
                        }
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
            .widgetURL(URL(string: isRide
                ? "flutteractivitykit://action/view_ride?activityId=\(context.activityID)"
                : "flutteractivitykit://action/open_activity?activityId=\(context.activityID)"
            ))
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
