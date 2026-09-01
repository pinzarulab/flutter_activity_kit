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
            let isSports = context.attributes.activityType.contains("Sports") || context.attributes.staticData["matchId"] != nil

            let accentColor: Color = isRide ? .yellow : (isDelivery ? .orange : .green)
            let iconName: String = isRide ? "car.fill" : (isDelivery ? "bag.fill" : "sportscourt.fill")
            let progress = context.state.progress ?? 0.0
            let eta = context.state.data["eta"] ?? "5 mins"

            // MARK: - Lock Screen Banner
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(context.state.title ?? (isRide ? "Ride Tracking" : (isDelivery ? "Food Order" : "Match Update")), systemImage: iconName)
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
                HStack(spacing: 8) {
                    if isRide {
                        Link(destination: URL(string: "flutteractivitykit://action/call_driver?activityId=\(context.activityID)")!) {
                            Label("Call Driver", systemImage: "phone.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.yellow)

                        Link(destination: URL(string: "flutteractivitykit://action/share_eta?activityId=\(context.activityID)")!) {
                            Label("Share ETA", systemImage: "square.and.arrow.up.fill")
                                .font(.caption2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.white)
                    } else if isDelivery {
                        Link(destination: URL(string: "flutteractivitykit://action/call_driver?activityId=\(context.activityID)")!) {
                            Label("Call Driver", systemImage: "phone.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.orange)

                        Link(destination: URL(string: "flutteractivitykit://action/cancel_order?activityId=\(context.activityID)")!) {
                            Label("Cancel", systemImage: "xmark.circle.fill")
                                .font(.caption2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.white)
                    } else {
                        Link(destination: URL(string: "flutteractivitykit://action/mute_match?activityId=\(context.activityID)")!) {
                            Label("Mute Match", systemImage: "bell.slash.fill")
                                .font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.white)

                        Link(destination: URL(string: "flutteractivitykit://action/match_stats?activityId=\(context.activityID)")!) {
                            Label("Match Stats", systemImage: "chart.bar.fill")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.green)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
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
                // MARK: - Expanded Leading (Icon + Title)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: iconName)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(accentColor)
                        Text(context.state.title ?? (isRide ? "Ride Tracking" : "Activity"))
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
                        HStack(spacing: 8) {
                            if isRide {
                                Link(destination: URL(string: "flutteractivitykit://action/call_driver?activityId=\(context.activityID)")!) {
                                    Label("Call Driver", systemImage: "phone.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .tint(.yellow)

                                Link(destination: URL(string: "flutteractivitykit://action/share_eta?activityId=\(context.activityID)")!) {
                                    Label("Share ETA", systemImage: "square.and.arrow.up.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.white)
                            } else if isDelivery {
                                Link(destination: URL(string: "flutteractivitykit://action/call_driver?activityId=\(context.activityID)")!) {
                                    Label("Call Courier", systemImage: "phone.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .tint(.orange)

                                Link(destination: URL(string: "flutteractivitykit://action/cancel_order?activityId=\(context.activityID)")!) {
                                    Label("Cancel", systemImage: "xmark.circle.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(.white)
                            } else {
                                Link(destination: URL(string: "flutteractivitykit://action/match_stats?activityId=\(context.activityID)")!) {
                                    Label("Match Stats", systemImage: "chart.bar.fill")
                                        .font(.system(size: 11, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .tint(.green)
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
