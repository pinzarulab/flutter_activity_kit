import 'dart:io';

/// CLI tool to generate Swift ActivityKit and WidgetKit boilerplate from Dart definitions or templates.
///
/// Usage:
///   # Generate from template:
///   dart run flutter_activity_kit:generate_swift --name RideTracking --template navigation
///   dart run flutter_activity_kit:generate_swift --name FoodDelivery --template delivery
///   dart run flutter_activity_kit:generate_swift --name MatchScore --template sports
///   dart run flutter_activity_kit:generate_swift --name OutdoorRun --template workout
///
///   # Automatically scan Dart files in lib/live_activity_widgets/:
///   dart run flutter_activity_kit:generate_swift
void main(List<String> args) {
  String activityName = 'LiveActivity';
  String targetDir = 'ios/LiveActivityWidget';
  String template = 'generic';

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--name' && i + 1 < args.length) {
      activityName = args[i + 1];
    } else if (args[i] == '--output' && i + 1 < args.length) {
      targetDir = args[i + 1];
    } else if (args[i] == '--template' && i + 1 < args.length) {
      template = args[i + 1].toLowerCase();
    }
  }

  // Check if Dart widget definitions exist in lib/live_activity_widgets/
  final widgetsDir = Directory('lib/live_activity_widgets');
  if (widgetsDir.existsSync()) {
    final dartFiles = widgetsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    if (dartFiles.isNotEmpty) {
      // ignore: avoid_print
      print('🔍 Detected ${dartFiles.length} Live Activity definition(s) in lib/live_activity_widgets/');
      for (final dartFile in dartFiles) {
        final parsed = parseDartWidgetFile(dartFile);
        final name = parsed['name'] ?? activityName;
        final tpl = parsed['template'] ?? template;
        generateFile(name, tpl, targetDir);
      }
      return;
    }
  }

  if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(activityName)) {
    stderr.writeln('--name must be a valid PascalCase Swift type prefix (e.g. RideTracking, FoodDelivery).');
    exitCode = 64;
    return;
  }

  generateFile(activityName, template, targetDir);
}

void generateFile(String activityName, String template, String targetDir) {
  final swiftContent = generateSwiftTemplate(activityName, template);

  final outDir = Directory(targetDir);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final outFile = File('${outDir.path}/${activityName}Widget.swift');
  outFile.writeAsStringSync(swiftContent);

  // ignore: avoid_print
  print('================================================================');
  // ignore: avoid_print
  print('  🎉 Successfully generated Swift Live Activity Widget!');
  // ignore: avoid_print
  print('  Widget Name: ${activityName}Widget');
  // ignore: avoid_print
  print('  Template:    $template');
  // ignore: avoid_print
  print('  File:        ${outFile.path}');
  // ignore: avoid_print
  print('================================================================');
}

Map<String, String> parseDartWidgetFile(File file) {
  final content = file.readAsStringSync();
  String name = 'LiveActivity';
  String template = 'generic';

  // Extract name: '...'
  final nameMatch = RegExp(r"name\s*:\s*['\x22]([A-Za-z0-9]+)['\x22]").firstMatch(content);
  if (nameMatch != null) {
    name = nameMatch.group(1)!;
  } else {
    // Infer from filename e.g. ride_live_activity_widget.dart -> RideLiveActivity
    final basename = file.uri.pathSegments.last.replaceAll('.dart', '');
    name = basename
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join();
  }

  // Extract template: LiveActivityTemplate.navigation / delivery / sports / workout / generic
  if (content.contains('LiveActivityTemplate.navigation') || content.contains('type: LiveActivityTemplateType.navigation')) {
    template = 'navigation';
  } else if (content.contains('LiveActivityTemplate.delivery') || content.contains('type: LiveActivityTemplateType.delivery')) {
    template = 'delivery';
  } else if (content.contains('LiveActivityTemplate.sports') || content.contains('type: LiveActivityTemplateType.sports')) {
    template = 'sports';
  } else if (content.contains('LiveActivityTemplate.workout') || content.contains('type: LiveActivityTemplateType.workout')) {
    template = 'workout';
  }

  return {'name': name, 'template': template};
}

String generateSwiftTemplate(String name, [String template = 'generic']) {
  switch (template) {
    case 'navigation':
    case 'ride':
      return _generateNavigationTemplate(name);
    case 'delivery':
    case 'food':
      return _generateDeliveryTemplate(name);
    case 'sports':
    case 'match':
      return _generateSportsTemplate(name);
    case 'workout':
    case 'fitness':
      return _generateWorkoutTemplate(name);
    default:
      return _generateGenericTemplate(name);
  }
}

String _generateNavigationTemplate(String name) {
  return '''//
//  ${name}Widget.swift
//  Generated by flutter_activity_kit (Navigation & Ride Template)
//

import ActivityKit
import WidgetKit
import SwiftUI
import Charts

// MARK: - Flutter Activity Attributes (Matches Flutter ActivityKit Bridge)
public struct FlutterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var data: [String: String]
        public var progress: Double?
        public var title: String?
        public var message: String?
        public var status: String?
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

// MARK: - Compact Route Mini-Map View (Zero clipping in Lock Screen & Dynamic Island)
struct MiniMapView: View {
    let progress: Double
    let eta: String
    let accentColor: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(white: 0.14))
                    .frame(height: 30)
                    .overlay(
                        HStack(spacing: 5) {
                            ForEach(0..<14) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 8, height: 1.5)
                            }
                        }
                    )

                GeometryReader { geo in
                    let totalWidth = geo.size.width - 32
                    let currentX = 16 + (totalWidth * CGFloat(min(max(progress, 0.0), 1.0)))

                    Path { path in
                        path.move(to: CGPoint(x: 16, y: 15))
                        path.addLine(to: CGPoint(x: currentX, y: 15))
                    }
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))

                    Circle()
                        .fill(Color.blue)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .position(x: 16, y: 15)

                    ZStack {
                        Circle().fill(Color.green).frame(width: 11, height: 11)
                        Image(systemName: "flag.fill").font(.system(size: 6)).foregroundColor(.white)
                    }
                    .position(x: geo.size.width - 16, y: 15)

                    ZStack {
                        Circle().fill(accentColor).frame(width: 19, height: 19)
                        Image(systemName: "car.fill").font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                    }
                    .position(x: currentX, y: 15)
                }
                .frame(height: 30)
            }

            HStack {
                HStack(spacing: 3) {
                    Circle().fill(Color.blue).frame(width: 4, height: 4)
                    Text(eta.isEmpty ? "Pickup" : "Pickup (Market St)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                HStack(spacing: 3) {
                    Text("ETA: \\(eta)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(accentColor)
                    Image(systemName: "arrow.right").font(.system(size: 6)).foregroundColor(.gray)
                    Circle().fill(Color.green).frame(width: 4, height: 4)
                    Text("Drop-off")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}

@available(iOS 16.1, *)
public struct ${name}Widget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            let accentColor: Color = .yellow
            let progress = context.state.progress ?? 0.0
            let eta = context.state.data["eta"] ?? "5 mins"

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(context.state.title ?? "Ride Tracking", systemImage: "car.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text(context.state.status ?? "\\(eta) 🚕")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(accentColor.opacity(0.25)))
                        .foregroundColor(accentColor)
                }

                if let message = context.state.message {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                }

                MiniMapView(progress: progress, eta: eta, accentColor: accentColor)

                HStack(spacing: 8) {
                    Link(destination: URL(string: "flutteractivitykit://action/call_driver?activityId=\\(context.activityID)")!) {
                        Label("Call Driver", systemImage: "phone.fill")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.yellow)

                    Link(destination: URL(string: "flutteractivitykit://action/share_eta?activityId=\\(context.activityID)")!) {
                        Label("Share ETA", systemImage: "square.and.arrow.up.fill")
                            .font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .activitySystemActionForegroundColor(Color.white)
            .widgetURL(URL(string: "flutteractivitykit://action/view_ride?activityId=\\(context.activityID)"))
        } dynamicIsland: { context in
            let accentColor: Color = .yellow
            let progress = context.state.progress ?? 0.0
            let eta = context.state.data["eta"] ?? "5 mins"

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "car.fill").foregroundColor(accentColor)
                        Text(context.state.status ?? "").font(.caption2).foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(eta)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(accentColor)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title ?? "").font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                        Text(context.state.message ?? "").font(.caption2).foregroundColor(.gray).lineLimit(1)
                        MiniMapView(progress: progress, eta: eta, accentColor: accentColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "car.fill").foregroundColor(accentColor)
                    Text(context.state.status ?? "").font(.caption2)
                }
            } compactTrailing: {
                Text(eta).font(.caption2).fontWeight(.bold).foregroundColor(accentColor)
            } minimal: {
                Image(systemName: "car.fill").foregroundColor(accentColor)
            }
            .widgetURL(URL(string: "flutteractivitykit://action/view_ride?activityId=\\(context.activityID)"))
        }
    }
}
''';
}

String _generateDeliveryTemplate(String name) {
  return '''//
//  ${name}Widget.swift
//  Generated by flutter_activity_kit (Delivery Template)
//

import ActivityKit
import WidgetKit
import SwiftUI
import Charts

public struct FlutterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var data: [String: String]
        public var progress: Double?
        public var title: String?
        public var message: String?
        public var status: String?
        public var timerStartDate: Date?
        public var timerTargetDate: Date?
        public var timerCountsDown: Bool?
        public var timerIsPaused: Bool?
    }

    public var activityType: String
    public var staticData: [String: String]
}

@available(iOS 16.1, *)
public struct ${name}Widget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            let accentColor: Color = .orange
            let progress = context.state.progress ?? 0.0

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(context.state.title ?? "Food Delivery", systemImage: "bag.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Text(context.state.status ?? "Preparing")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(accentColor.opacity(0.25)))
                        .foregroundColor(accentColor)
                }

                if let message = context.state.message {
                    Text(message).font(.caption).foregroundColor(.white.opacity(0.85))
                }

                ProgressView(value: progress, total: 1.0).tint(accentColor)

                HStack(spacing: 8) {
                    Link(destination: URL(string: "flutteractivitykit://action/call_courier?activityId=\\(context.activityID)")!) {
                        Label("Call Courier", systemImage: "phone.fill").font(.caption2).fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.orange)

                    Link(destination: URL(string: "flutteractivitykit://action/cancel_order?activityId=\\(context.activityID)")!) {
                        Label("Cancel", systemImage: "xmark.circle.fill").font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .widgetURL(URL(string: "flutteractivitykit://action/open_delivery?activityId=\\(context.activityID)"))
        } dynamicIsland: { context in
            let accentColor: Color = .orange
            let progress = context.state.progress ?? 0.0

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "bag.fill").foregroundColor(accentColor)
                        Text(context.state.status ?? "").font(.caption2).foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\\(Int(progress * 100))%").font(.caption).fontWeight(.bold).foregroundColor(accentColor)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title ?? "").font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                        Text(context.state.message ?? "").font(.caption2).foregroundColor(.gray)
                        ProgressView(value: progress, total: 1.0).tint(accentColor)
                    }
                }
            } compactLeading: {
                Image(systemName: "bag.fill").foregroundColor(accentColor)
            } compactTrailing: {
                Text("\\(Int(progress * 100))%").font(.caption2).fontWeight(.bold).foregroundColor(accentColor)
            } minimal: {
                Image(systemName: "bag.fill").foregroundColor(accentColor)
            }
        }
    }
}
''';
}

String _generateSportsTemplate(String name) {
  return '''//
//  ${name}Widget.swift
//  Generated by flutter_activity_kit (Sports Template)
//

import ActivityKit
import WidgetKit
import SwiftUI
import Charts

public struct FlutterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var data: [String: String]
        public var progress: Double?
        public var title: String?
        public var message: String?
        public var status: String?
        public var timerStartDate: Date?
        public var timerTargetDate: Date?
        public var timerCountsDown: Bool?
        public var timerIsPaused: Bool?
    }

    public var activityType: String
    public var staticData: [String: String]
}

@available(iOS 16.1, *)
public struct ${name}Widget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            let accentColor: Color = .green

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(context.state.title ?? "Match Scoreboard", systemImage: "sportscourt.fill")
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Text(context.state.status ?? "Live")
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(accentColor.opacity(0.25)))
                        .foregroundColor(accentColor)
                }

                if let message = context.state.message {
                    Text(message).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                }

                HStack(spacing: 8) {
                    Link(destination: URL(string: "flutteractivitykit://action/match_stats?activityId=\\(context.activityID)")!) {
                        Label("Match Stats", systemImage: "chart.bar.fill").font(.caption2).fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.green)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .widgetURL(URL(string: "flutteractivitykit://action/open_match?activityId=\\(context.activityID)"))
        } dynamicIsland: { context in
            let accentColor: Color = .green

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "sportscourt.fill").foregroundColor(accentColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status ?? "Live").font(.caption).fontWeight(.bold).foregroundColor(accentColor)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.title ?? "").font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                        Text(context.state.message ?? "").font(.caption2).foregroundColor(.gray)
                    }
                }
            } compactLeading: {
                Image(systemName: "sportscourt.fill").foregroundColor(accentColor)
            } compactTrailing: {
                Text(context.state.status ?? "Live").font(.caption2).fontWeight(.bold).foregroundColor(accentColor)
            } minimal: {
                Image(systemName: "sportscourt.fill").foregroundColor(accentColor)
            }
        }
    }
}
''';
}

String _generateWorkoutTemplate(String name) {
  return '''//
//  ${name}Widget.swift
//  Generated by flutter_activity_kit (Workout Template)
//

import ActivityKit
import WidgetKit
import SwiftUI
import Charts

public struct FlutterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var data: [String: String]
        public var progress: Double?
        public var title: String?
        public var message: String?
        public var status: String?
        public var timerStartDate: Date?
        public var timerTargetDate: Date?
        public var timerCountsDown: Bool?
        public var timerIsPaused: Bool?
    }

    public var activityType: String
    public var staticData: [String: String]
}

@available(iOS 16.1, *)
public struct ${name}Widget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            let accentColor: Color = .cyan

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(context.state.title ?? "Workout", systemImage: "figure.run")
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Text(context.state.status ?? "Running")
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(accentColor.opacity(0.25)))
                        .foregroundColor(accentColor)
                }

                if let message = context.state.message {
                    Text(message).font(.caption).foregroundColor(.white.opacity(0.85))
                }

                if let progress = context.state.progress {
                    ProgressView(value: progress, total: 1.0).tint(accentColor)
                }

                HStack(spacing: 8) {
                    Link(destination: URL(string: "flutteractivitykit://action/pause_workout?activityId=\\(context.activityID)")!) {
                        Label("Pause", systemImage: "pause.fill").font(.caption2).fontWeight(.bold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.cyan)

                    Link(destination: URL(string: "flutteractivitykit://action/finish_workout?activityId=\\(context.activityID)")!) {
                        Label("Finish", systemImage: "stop.fill").font(.caption2)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.white)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
            .widgetURL(URL(string: "flutteractivitykit://action/open_workout?activityId=\\(context.activityID)"))
        } dynamicIsland: { context in
            let accentColor: Color = .cyan

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.run").foregroundColor(accentColor)
                        Text(context.state.status ?? "").font(.caption2).foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let progress = context.state.progress {
                        Text("\\(Int(progress * 100))%").font(.caption).fontWeight(.bold).foregroundColor(accentColor)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title ?? "").font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                        Text(context.state.message ?? "").font(.caption2).foregroundColor(.gray)
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.run").foregroundColor(accentColor)
            } compactTrailing: {
                Text(context.state.status ?? "Run").font(.caption2).fontWeight(.bold).foregroundColor(accentColor)
            } minimal: {
                Image(systemName: "figure.run").foregroundColor(accentColor)
            }
        }
    }
}
''';
}

String _generateGenericTemplate(String name) {
  return '''//
//  ${name}Widget.swift
//  Generated by flutter_activity_kit
//

import ActivityKit
import WidgetKit
import SwiftUI
import Charts

public struct FlutterActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var data: [String: String]
        public var progress: Double?
        public var title: String?
        public var message: String?
        public var status: String?
        public var timerStartDate: Date?
        public var timerTargetDate: Date?
        public var timerCountsDown: Bool?
        public var timerIsPaused: Bool?
    }

    public var activityType: String
    public var staticData: [String: String]
}

@available(iOS 16.1, *)
public struct ${name}Widget: Widget {
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlutterActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(context.state.title ?? "Live Activity", systemImage: "sparkles")
                        .font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Text(context.state.status ?? "Active")
                        .font(.caption2).fontWeight(.semibold)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue.opacity(0.25)))
                        .foregroundColor(.blue)
                }

                if let message = context.state.message {
                    Text(message).font(.caption).foregroundColor(.white.opacity(0.85))
                }

                if let progress = context.state.progress {
                    ProgressView(value: progress, total: 1.0).tint(.blue)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.85))
            .activityBackgroundTint(Color.black.opacity(0.85))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bolt.fill").foregroundColor(.cyan)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status ?? "Active").font(.caption).fontWeight(.bold).foregroundColor(.cyan)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.title ?? "").font(.subheadline).fontWeight(.bold).foregroundColor(.white)
                        Text(context.state.message ?? "").font(.caption2).foregroundColor(.gray)
                    }
                }
            } compactLeading: {
                Image(systemName: "bolt.fill").foregroundColor(.cyan)
            } compactTrailing: {
                Text(context.state.status ?? "Active").font(.caption2).fontWeight(.bold).foregroundColor(.cyan)
            } minimal: {
                Image(systemName: "bolt.fill").foregroundColor(.cyan)
            }
        }
    }
}
''';
}
