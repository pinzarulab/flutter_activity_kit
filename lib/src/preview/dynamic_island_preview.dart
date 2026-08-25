import 'package:flutter/material.dart';

/// Dynamic Island view presentation style.
enum DynamicIslandStyle {
  /// Expanded full Dynamic Island view.
  expanded,

  /// Compact view split into leading and trailing pills.
  compact,

  /// Minimal single circle or pill bubble.
  minimal,

  /// Lock Screen Live Activity banner card.
  lockScreenBanner,
}

/// A Flutter widget that simulates iOS Dynamic Island and Lock Screen Live Activity rendering.
///
/// Useful for testing, visual debugging, and cross-platform UI prototyping.
class DynamicIslandPreview extends StatelessWidget {
  /// Display style to preview.
  final DynamicIslandStyle style;

  /// Leading widget (e.g. app icon, status avatar).
  final Widget? leading;

  /// Trailing widget (e.g. ETA, timer, counter).
  final Widget? trailing;

  /// Center content widget (for expanded island).
  final Widget? center;

  /// Bottom content widget (for expanded island or lock screen banner).
  final Widget? bottom;

  /// Title string (used in lock screen banner).
  final String? title;

  /// Subtitle string (used in lock screen banner).
  final String? subtitle;

  /// Background color (defaults to Apple Dynamic Island deep black).
  final Color backgroundColor;

  /// Text color.
  final Color foregroundColor;

  /// Action buttons list for interactive controls.
  final List<Widget>? actions;

  const DynamicIslandPreview({
    super.key,
    this.style = DynamicIslandStyle.expanded,
    this.leading,
    this.trailing,
    this.center,
    this.bottom,
    this.title,
    this.subtitle,
    this.backgroundColor = const Color(0xFF000000),
    this.foregroundColor = const Color(0xFFFFFFFF),
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case DynamicIslandStyle.expanded:
        return _buildExpandedIsland();
      case DynamicIslandStyle.compact:
        return _buildCompactIsland();
      case DynamicIslandStyle.minimal:
        return _buildMinimalIsland();
      case DynamicIslandStyle.lockScreenBanner:
        return _buildLockScreenBanner();
    }
  }

  Widget _buildExpandedIsland() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leading != null) leading!,
              if (trailing != null) trailing!,
            ],
          ),
          if (center != null) ...[
            const SizedBox(height: 12),
            center!,
          ],
          if (bottom != null) ...[
            const SizedBox(height: 12),
            bottom!,
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactIsland() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220, minHeight: 38),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (leading != null) leading!,
          if (trailing != null) trailing!,
        ],
      ),
    );
  }

  Widget _buildMinimalIsland() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: leading ?? trailing ?? const SizedBox.shrink(),
    );
  }

  Widget _buildLockScreenBanner() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: TextStyle(
                          color: foregroundColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: foregroundColor.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (center != null) ...[
            const SizedBox(height: 12),
            center!,
          ],
          if (bottom != null) ...[
            const SizedBox(height: 12),
            bottom!,
          ],
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions!,
            ),
          ],
        ],
      ),
    );
  }
}
