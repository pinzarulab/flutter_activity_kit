import 'package:flutter/material.dart';

/// A Flutter widget that simulates an Android Ongoing Notification banner.
class OngoingNotificationPreview extends StatelessWidget {
  /// App name displayed in the notification header.
  final String appName;

  /// Sub-text displayed in header (e.g. 'Active Session', 'Live Tracking').
  final String? subText;

  /// Time indicator or timestamp text.
  final String time;

  /// Notification title text.
  final String title;

  /// Notification body / content text.
  final String? body;

  /// Progress value between 0.0 and 1.0 (or null if no progress bar).
  final double? progress;

  /// Leading app icon or avatar.
  final Widget? icon;

  /// Large icon or badge on the right.
  final Widget? largeIcon;

  /// Action buttons list (e.g. TextButton or OutlinedButton).
  final List<Widget>? actions;

  /// Background color (defaults to Android dark theme notification card).
  final Color backgroundColor;

  /// Text color.
  final Color textColor;

  const OngoingNotificationPreview({
    super.key,
    this.appName = 'Activity App',
    this.subText,
    this.time = 'now',
    required this.title,
    this.body,
    this.progress,
    this.icon,
    this.largeIcon,
    this.actions,
    this.backgroundColor = const Color(0xFF2C2C2E),
    this.textColor = const Color(0xFFE5E5EA),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + App Name + dot + subText + dot + Time
          Row(
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ] else ...[
                const Icon(
                  Icons.notifications_active_rounded,
                  size: 16,
                  color: Color(0xFF64B5F6),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                appName,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subText != null) ...[
                Text(
                  ' • $subText',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                time,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Content Row: Title + Body, and optional LargeIcon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        body!,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (largeIcon != null) ...[
                const SizedBox(width: 12),
                largeIcon!,
              ],
            ],
          ),
          // Progress bar if present
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: textColor.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF64B5F6),
                ),
                minHeight: 5,
              ),
            ),
          ],
          // Action Buttons
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 10),
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
