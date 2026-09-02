/// Dart DSL components for building custom Live Activity layouts in 100% Dart.
///
/// These components are automatically translated to native SwiftUI (WidgetKit)
/// when running `dart run flutter_activity_kit:generate_swift`.
library;

/// Context providing access to Live Activity state values during rendering.
class LAContext {
  const LAContext();

  /// References `context.state.title`
  String get title => '__STATE_TITLE__';

  /// References `context.state.message`
  String get message => '__STATE_MESSAGE__';

  /// References `context.state.status`
  String get status => '__STATE_STATUS__';

  /// References `context.state.progress`
  double get progress => -1.0;

  /// References a dynamic data key in `context.state.data[key]`
  String state(String key) => '__STATE_DATA_${key}__';

  /// References a static attribute key in `context.attributes.staticData[key]`
  String attribute(String key) => '__ATTR_DATA_${key}__';

  /// References the Live Activity ID for deep linking
  String get activityId => '__ACTIVITY_ID__';
}

/// Base class for all Dart Live Activity UI elements.
abstract class LAWidget {
  const LAWidget();

  /// Converts the widget to native SwiftUI code.
  String toSwift(int indent);
}

/// Font style presets for Live Activity text.
enum LAFont {
  largeTitle,
  title,
  title2,
  title3,
  headline,
  subheadline,
  body,
  callout,
  footnote,
  caption,
  caption2,
}

/// Color definitions for Live Activity widgets.
class LAColor {
  final String swiftRepresentation;

  const LAColor._(this.swiftRepresentation);

  static const LAColor white = LAColor._('.white');
  static const LAColor black = LAColor._('.black');
  static const LAColor gray = LAColor._('.gray');
  static const LAColor red = LAColor._('.red');
  static const LAColor green = LAColor._('.green');
  static const LAColor blue = LAColor._('.blue');
  static const LAColor orange = LAColor._('.orange');
  static const LAColor yellow = LAColor._('.yellow');
  static const LAColor pink = LAColor._('.pink');
  static const LAColor purple = LAColor._('.purple');
  static const LAColor cyan = LAColor._('.cyan');
  static const LAColor indigo = LAColor._('.indigo');
  static const LAColor mint = LAColor._('.mint');
  static const LAColor teal = LAColor._('.teal');

  /// Hex color code e.g. `LAColor.hex('#007AFF')`
  factory LAColor.hex(String hex) {
    final clean = hex.replaceAll('#', '');
    return LAColor._('Color(red: ${(int.parse(clean.substring(0, 2), radix: 16) / 255).toStringAsFixed(2)}, green: ${(int.parse(clean.substring(2, 4), radix: 16) / 255).toStringAsFixed(2)}, blue: ${(int.parse(clean.substring(4, 6), radix: 16) / 255).toStringAsFixed(2)})');
  }

  /// Color with opacity e.g. `LAColor.white.withOpacity(0.8)`
  LAColor withOpacity(double opacity) {
    return LAColor._('$swiftRepresentation.opacity(${opacity.toStringAsFixed(2)})');
  }
}

/// Alignment along the cross axis for columns.
enum LACrossAxisAlignment {
  start,
  center,
  end,
}

/// Vertical stack of widgets (translates to SwiftUI `VStack`).
class LAColumn extends LAWidget {
  final List<LAWidget> children;
  final double spacing;
  final LACrossAxisAlignment crossAxisAlignment;

  const LAColumn({
    required this.children,
    this.spacing = 6.0,
    this.crossAxisAlignment = LACrossAxisAlignment.start,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final align = switch (crossAxisAlignment) {
      LACrossAxisAlignment.start => '.leading',
      LACrossAxisAlignment.center => '.center',
      LACrossAxisAlignment.end => '.trailing',
    };
    final buffer = StringBuffer('$sp' 'VStack(alignment: $align, spacing: $spacing) {\n');
    for (final child in children) {
      buffer.writeln(child.toSwift(indent + 4));
    }
    buffer.write('$sp}');
    return buffer.toString();
  }
}

/// Horizontal stack of widgets (translates to SwiftUI `HStack`).
class LARow extends LAWidget {
  final List<LAWidget> children;
  final double spacing;

  const LARow({
    required this.children,
    this.spacing = 8.0,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final buffer = StringBuffer('$sp' 'HStack(spacing: $spacing) {\n');
    for (final child in children) {
      buffer.writeln(child.toSwift(indent + 4));
    }
    buffer.write('$sp}');
    return buffer.toString();
  }
}

/// Text label (translates to SwiftUI `Text(...)`).
class LAText extends LAWidget {
  final String text;
  final LAFont font;
  final bool bold;
  final bool monospaced;
  final LAColor? color;
  final int? maxLines;

  const LAText(
    this.text, {
    this.font = LAFont.body,
    this.bold = false,
    this.monospaced = false,
    this.color,
    this.maxLines,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final raw = _resolveTextExpression(text);
    final modifiers = <String>[];
    modifiers.add('.font(.${font.name})');
    if (bold) modifiers.add('.fontWeight(.bold)');
    if (monospaced) modifiers.add('.monospacedDigit()');
    if (color != null) modifiers.add('.foregroundColor(${color!.swiftRepresentation})');
    if (maxLines != null) modifiers.add('.lineLimit($maxLines)');

    return '$sp' 'Text($raw)${modifiers.join()}';
  }

  String _resolveTextExpression(String val) {
    if (val == '__STATE_TITLE__') return 'context.state.title ?? ""';
    if (val == '__STATE_MESSAGE__') return 'context.state.message ?? ""';
    if (val == '__STATE_STATUS__') return 'context.state.status ?? ""';
    if (val.startsWith('__STATE_DATA_') && val.endsWith('__')) {
      final key = val.substring(13, val.length - 2);
      return 'context.state.data["$key"] ?? ""';
    }
    if (val.startsWith('__ATTR_DATA_') && val.endsWith('__')) {
      final key = val.substring(12, val.length - 2);
      return 'context.attributes.staticData["$key"] ?? ""';
    }
    return '"$val"';
  }
}

/// SF Symbol or custom asset icon (translates to SwiftUI `Image(systemName:)`).
class LAImage extends LAWidget {
  final String systemName;
  final LAColor? color;
  final double? size;

  const LAImage.system(
    this.systemName, {
    this.color,
    this.size,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final modifiers = <String>[];
    if (size != null) modifiers.add('.font(.system(size: $size))');
    if (color != null) modifiers.add('.foregroundColor(${color!.swiftRepresentation})');
    return '$sp' 'Image(systemName: "$systemName")${modifiers.join()}';
  }
}

/// Progress bar (translates to SwiftUI `ProgressView(value:total:)`).
class LAProgressBar extends LAWidget {
  final double? value;
  final LAColor tint;

  const LAProgressBar({
    this.value,
    this.tint = LAColor.orange,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final valStr = value != null ? '$value' : 'context.state.progress ?? 0.0';
    return '$sp' 'ProgressView(value: $valStr, total: 1.0).tint(${tint.swiftRepresentation})';
  }
}

/// Flexible spacer (translates to SwiftUI `Spacer()`).
class LASpacer extends LAWidget {
  const LASpacer();

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    return '$sp' 'Spacer()';
  }
}

/// Interactive Action Button with deep-linking (translates to SwiftUI `Link(destination:)`).
class LAButton extends LAWidget {
  final String title;
  final String actionId;
  final String? systemIcon;
  final bool isProminent;
  final bool isDestructive;
  final LAColor? tint;

  const LAButton({
    required this.title,
    required this.actionId,
    this.systemIcon,
    this.isProminent = false,
    this.isDestructive = false,
    this.tint,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final iconPart = systemIcon != null
        ? 'Label("$title", systemImage: "$systemIcon")'
        : 'Text("$title")';

    final style = isProminent ? '.borderedProminent' : '.bordered';
    final tintPart = tint != null
        ? '.tint(${tint!.swiftRepresentation})'
        : (isDestructive ? '.tint(.red)' : (isProminent ? '.tint(.orange)' : '.tint(.white)'));

    return '$sp' 'Link(destination: URL(string: "flutteractivitykit://action/$actionId?activityId=\\(context.activityID)")!) {\n'
        '$sp    $iconPart\n'
        '$sp        .font(.caption2)\n'
        '${isProminent ? "$sp        .fontWeight(.bold)\n" : ""}'
        '$sp}\n'
        '$sp.buttonStyle($style)\n'
        '$sp.controlSize(.small)\n'
        '$sp$tintPart';
  }
}

/// Real-time hardware countdown / chronometer timer (translates to SwiftUI `Text(timerInterval:)`).
class LATimer extends LAWidget {
  final LAFont font;
  final LAColor color;

  const LATimer({
    this.font = LAFont.caption,
    this.color = LAColor.orange,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    return '$sp' 'if let targetDate = context.state.timerTargetDate {\n'
        '$sp    let startDate = context.state.timerStartDate ?? Date()\n'
        '$sp    let countsDown = context.state.timerCountsDown ?? true\n'
        '$sp    let lower = min(startDate, targetDate)\n'
        '$sp    let upper = max(startDate, targetDate)\n'
        '$sp    let safeRange = (lower == upper) ? lower...upper.addingTimeInterval(1) : lower...upper\n'
        '$sp    Text(timerInterval: safeRange, pauseTime: nil, countsDown: countsDown)\n'
        '$sp        .font(.${font.name})\n'
        '$sp        .fontWeight(.bold)\n'
        '$sp        .monospacedDigit()\n'
        '$sp        .foregroundColor(${color.swiftRepresentation})\n'
        '$sp}';
  }
}

/// Container wrapper with padding, background, and corner radius.
class LAContainer extends LAWidget {
  final LAWidget child;
  final double paddingHorizontal;
  final double paddingVertical;
  final LAColor? background;
  final double cornerRadius;

  const LAContainer({
    required this.child,
    this.paddingHorizontal = 14.0,
    this.paddingVertical = 10.0,
    this.background,
    this.cornerRadius = 12.0,
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final childCode = child.toSwift(indent);
    final bgPart = background != null
        ? '\n$sp.background(RoundedRectangle(cornerRadius: $cornerRadius).fill(${background!.swiftRepresentation}))'
        : '';
    return '$childCode\n'
        '$sp.padding(.horizontal, $paddingHorizontal)\n'
        '$sp.padding(.vertical, $paddingVertical)'
        '$bgPart';
  }
}

/// Dynamic Island definition for iOS 16.1+ Live Activities.
class LADynamicIsland {
  final LAWidget compactLeading;
  final LAWidget compactTrailing;
  final LAWidget? expandedLeading;
  final LAWidget? expandedTrailing;
  final LAWidget? expandedBottom;
  final LAWidget? minimal;

  const LADynamicIsland({
    required this.compactLeading,
    required this.compactTrailing,
    this.expandedLeading,
    this.expandedTrailing,
    this.expandedBottom,
    this.minimal,
  });
}

/// A circular gauge representing a value within a range (translates to SwiftUI `Gauge`).
class LAGauge extends LAWidget {
  final String? label;
  final String currentValue;
  final double minValue;
  final double maxValue;
  final LAColor tint;
  final String style;

  const LAGauge({
    this.label,
    this.currentValue = '__STATE_PROGRESS__',
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.tint = LAColor.green,
    this.style = '.accessoryCircular',
  });

  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final valStr = _resolveTextExpression(currentValue);
    
    final buffer = StringBuffer();
    buffer.writeln('$sp' 'Gauge(value: $valStr, in: $minValue...$maxValue) {');
    if (label != null) {
      buffer.writeln('$sp    Text("${label!}")');
    } else {
      buffer.writeln('$sp    EmptyView()');
    }
    buffer.writeln('$sp}');
    buffer.writeln('$sp.gaugeStyle($style)');
    buffer.write('$sp.tint(${tint.swiftRepresentation})');
    return buffer.toString();
  }
  
  String _resolveTextExpression(String val) {
    if (val == '__STATE_PROGRESS__') return 'context.state.progress ?? 0.0';
    if (val.startsWith('__STATE_DATA_') && val.endsWith('__')) {
      final key = val.substring(13, val.length - 2);
      return 'Double(context.state.data["$key"] ?? "0") ?? 0.0';
    }
    return val;
  }
}

/// A beautiful native chart (translates to SwiftUI `Chart` with `BarMark` or `LineMark`).
class LAChart extends LAWidget {
  final String dataKey;
  final LAColor tint;
  final String chartType; // 'bar' or 'line'
  
  const LAChart({
    required this.dataKey,
    this.tint = LAColor.blue,
    this.chartType = 'bar',
  });
  
  @override
  String toSwift(int indent) {
    final sp = ' ' * indent;
    final buffer = StringBuffer();
    
    // Parse comma-separated double values directly inline to ensure ViewBuilder compatibility
    final inlineData = 'Array((context.state.data["$dataKey"] ?? "").split(separator: ",").compactMap { Double(\$0) }.enumerated())';
    
    buffer.writeln('$sp' 'Chart($inlineData, id: \\.offset) { index, value in');
    if (chartType == 'line') {
      buffer.writeln('$sp    LineMark(');
    } else {
      buffer.writeln('$sp    BarMark(');
    }
    buffer.writeln('$sp        x: .value("Index", index),');
    buffer.writeln('$sp        y: .value("Value", value)');
    buffer.writeln('$sp    )');
    buffer.writeln('$sp    .foregroundStyle(${tint.swiftRepresentation})');
    buffer.writeln('$sp}');
    buffer.writeln('$sp.chartXAxis(.hidden)');
    buffer.write('$sp.chartYAxis(.hidden)');
    return buffer.toString();
  }
}
