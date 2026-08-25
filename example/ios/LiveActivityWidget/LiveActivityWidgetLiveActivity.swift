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
        }
    }

    public var activityType: String
    public var staticData: [String: String]

    public init(activityType: String, staticData: [String: String] = [:]) {
        self.activityType = activityType
        self.staticData = staticData
    }
}

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
                    if let status = context.state.status {
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
            }
            .padding(16)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
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
                    if let progress = context.state.progress {
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
                if let progress = context.state.progress {
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
