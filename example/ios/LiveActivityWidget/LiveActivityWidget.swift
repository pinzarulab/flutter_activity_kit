//
//  LiveActivityWidget.swift
//  flutter_activity_kit_example
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
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
            self.status = status
        }
    }

    public var activityType: String
    public var staticData: [String: String]

    public init(activityType: String, staticData: [String: String] = [:]) {
        self.activityType = activityType
        self.staticData = staticData
    }
}

@available(iOS 16.1, *)
@main
public struct LiveActivityWidgetBundle: WidgetBundle {
    public var body: some Widget {
        LiveActivityWidget()
    }
}

@available(iOS 16.1, *)
public struct LiveActivityWidget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            // Lock Screen Banner
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(context.state.title ?? "Live Activity", systemImage: "bolt.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if let status = context.state.status {
                        Text(status)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.blue.opacity(0.3)))
                            .foregroundColor(.cyan)
                    }
                }

                if let message = context.state.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }

                if let progress = context.state.progress {
                    ProgressView(value: progress, total: 1.0)
                        .tint(.cyan)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.circle.fill")
                            .foregroundColor(.cyan)
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
                            .foregroundColor(.green)
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
                                .tint(.cyan)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.cyan)
                    Text(context.state.status ?? "")
                        .font(.caption2)
                }
            } compactTrailing: {
                if let progress = context.state.progress {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            } minimal: {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.cyan)
            }
        }
    }
}
