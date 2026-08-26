package com.flutteractivitykit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

data class TrackedActivity(
    val id: String,
    val activityType: String,
    var state: String,
    val attributes: Map<String, Any?>,
    var contentState: Map<String, Any?>,
    var androidOptions: Map<String, Any?>,
    val notificationId: Int
)

class OngoingNotificationManager(private val context: Context) {
    private val notificationManager = NotificationManagerCompat.from(context)
    private val trackedActivities = ConcurrentHashMap<String, TrackedActivity>()
    private var nextNotificationId = 1000

    fun areActivitiesEnabled(): Boolean {
        return notificationManager.areNotificationsEnabled()
    }

    private fun getOrCreateChannel(
        channelId: String,
        channelName: String,
        channelDescription: String?,
        priority: Int
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = when (priority) {
                2 -> NotificationManager.IMPORTANCE_HIGH
                1 -> NotificationManager.IMPORTANCE_DEFAULT
                0 -> NotificationManager.IMPORTANCE_LOW
                else -> NotificationManager.IMPORTANCE_DEFAULT
            }
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                if (channelDescription != null) {
                    description = channelDescription
                }
                setShowBadge(true)
            }
            val systemNotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            systemNotificationManager.createNotificationChannel(channel)
        }
    }

    private fun getIconResourceId(iconName: String?): Int {
        if (iconName != null) {
            val resId = context.resources.getIdentifier(iconName, "drawable", context.packageName)
            if (resId != 0) return resId
        }
        // Default system icon
        val defaultId = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)
        return if (defaultId != 0) defaultId else android.R.drawable.ic_dialog_info
    }

    fun startActivity(args: Map<String, Any?>): Map<String, Any?> {
        val activityId = UUID.randomUUID().toString()
        val activityType = args["activityType"] as? String ?: "GenericActivity"
        @Suppress("UNCHECKED_CAST")
        val rawAttributes = (args["attributes"] as? Map<String, Any?>) ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val rawContent = (args["content"] as? Map<String, Any?>) ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val rawState = (rawContent["state"] as? Map<String, Any?>) ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val androidOptions = (args["androidOptions"] as? Map<String, Any?>) ?: emptyMap()

        val notificationId = synchronized(this) { nextNotificationId++ }

        val tracked = TrackedActivity(
            id = activityId,
            activityType = activityType,
            state = "active",
            attributes = rawAttributes,
            contentState = rawState,
            androidOptions = androidOptions,
            notificationId = notificationId
        )
        trackedActivities[activityId] = tracked

        buildAndPostNotification(
            activityId = activityId,
            notificationId = notificationId,
            contentState = rawState,
            androidOptions = androidOptions
        )

        return mapOf(
            "id" to activityId,
            "activityType" to activityType,
            "state" to "active",
            "attributes" to rawAttributes,
            "contentState" to rawState,
            "pushToken" to null
        )
    }

    fun updateActivity(
        activityId: String,
        contentMap: Map<String, Any?>,
        alertMap: Map<String, Any?>?
    ) {
        val tracked = trackedActivities[activityId] ?: return
        @Suppress("UNCHECKED_CAST")
        val rawState = (contentMap["state"] as? Map<String, Any?>) ?: emptyMap()
        tracked.contentState = rawState

        // Update notification keeping androidOptions
        buildAndPostNotification(
            activityId = activityId,
            notificationId = tracked.notificationId,
            contentState = rawState,
            androidOptions = tracked.androidOptions
        )
    }

    fun endActivity(
        activityId: String,
        finalContentMap: Map<String, Any?>?,
        dismissalPolicyMap: Map<String, Any?>?
    ) {
        val tracked = trackedActivities[activityId] ?: return
        tracked.state = "ended"

        val type = dismissalPolicyMap?.get("type") as? String ?: "default"
        if (type == "immediate") {
            notificationManager.cancel(tracked.notificationId)
            trackedActivities.remove(activityId)
        } else {
            // If final content provided, post it once as non-ongoing
            if (finalContentMap != null) {
                @Suppress("UNCHECKED_CAST")
                val rawState = (finalContentMap["state"] as? Map<String, Any?>) ?: emptyMap()
                tracked.contentState = rawState
                buildAndPostNotification(
                    activityId = activityId,
                    notificationId = tracked.notificationId,
                    contentState = rawState,
                    androidOptions = mapOf("ongoing" to false)
                )
            } else {
                notificationManager.cancel(tracked.notificationId)
                trackedActivities.remove(activityId)
            }
        }
    }

    fun getAllActivities(): List<Map<String, Any?>> {
        return trackedActivities.values.map { activity ->
            mapOf(
                "id" to activity.id,
                "activityType" to activity.activityType,
                "state" to activity.state,
                "attributes" to activity.attributes,
                "contentState" to activity.contentState,
                "pushToken" to null
            )
        }
    }

    fun getActivity(activityId: String): Map<String, Any?>? {
        val activity = trackedActivities[activityId] ?: return null
        return mapOf(
            "id" to activity.id,
            "activityType" to activity.activityType,
            "state" to activity.state,
            "attributes" to activity.attributes,
            "contentState" to activity.contentState,
            "pushToken" to null
        )
    }

    private fun buildAndPostNotification(
        activityId: String,
        notificationId: Int,
        contentState: Map<String, Any?>,
        androidOptions: Map<String, Any?>
    ) {
        val channelId = (androidOptions["channelId"] as? String) ?: "flutter_activity_kit_channel"
        val channelName = (androidOptions["channelName"] as? String) ?: "Live Activities"
        val channelDescription = androidOptions["channelDescription"] as? String
        val priority = (androidOptions["priority"] as? Number)?.toInt() ?: 1
        val ongoing = (androidOptions["ongoing"] as? Boolean) ?: true

        getOrCreateChannel(channelId, channelName, channelDescription, priority)

        val smallIconRes = getIconResourceId(androidOptions["smallIcon"] as? String)
        val title = (contentState["title"] as? String) ?: (contentState["status"] as? String) ?: "Live Update"
        val message = (contentState["message"] as? String) ?: (contentState["body"] as? String) ?: ""
        val subText = (androidOptions["subText"] as? String) ?: (contentState["subText"] as? String)

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(smallIconRes)
            .setContentTitle(title)
            .setContentText(message)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setOnlyAlertOnce(true)

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        // Tap content intent to bring app to foreground
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("activityId", activityId)
        }
        if (launchIntent != null) {
            val contentPendingIntent = PendingIntent.getActivity(
                context,
                notificationId,
                launchIntent,
                flags
            )
            builder.setContentIntent(contentPendingIntent)
        }

        if (subText != null) {
            builder.setSubText(subText)
        }

        // Color accent
        if (androidOptions["color"] != null) {
            val colorInt = (androidOptions["color"] as Number).toInt()
            builder.color = colorInt
        }

        // Progress bar
        val progress = (contentState["progress"] as? Number)?.toDouble() ?: (androidOptions["progress"] as? Number)?.toDouble()
        val isIndeterminate = (androidOptions["isIndeterminate"] as? Boolean) ?: false
        if (progress != null || isIndeterminate) {
            val progressInt = ((progress ?: 0.0) * 100).toInt().coerceIn(0, 100)
            builder.setProgress(100, progressInt, isIndeterminate)
        }

        // Chronometer
        val isChronometer = (androidOptions["isChronometer"] as? Boolean) ?: false
        if (isChronometer) {
            builder.setUsesChronometer(true)
            if (androidOptions["chronometerBase"] != null) {
                val baseMs = (androidOptions["chronometerBase"] as Number).toLong()
                builder.setWhen(baseMs)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                val countDown = (androidOptions["chronometerCountDown"] as? Boolean) ?: false
                builder.setChronometerCountDown(countDown)
            }
        }

        // Action buttons
        @Suppress("UNCHECKED_CAST")
        val actionsList = (androidOptions["actions"] as? List<Map<String, Any?>>) ?: emptyList()
        for ((index, actionMap) in actionsList.withIndex()) {
            val actionId = (actionMap["id"] as? String) ?: "action_$index"
            val actionTitle = (actionMap["title"] as? String) ?: "Action"
            val actionIconRes = getIconResourceId(actionMap["icon"] as? String)

            val actionLaunchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("activityId", activityId)
                putExtra("actionId", actionId)
            }

            val pendingIntent = if (actionLaunchIntent != null) {
                PendingIntent.getActivity(
                    context,
                    (notificationId * 10 + index),
                    actionLaunchIntent,
                    flags
                )
            } else {
                val intent = Intent(context, ActivityActionReceiver::class.java).apply {
                    action = "com.flutteractivitykit.ACTION_CLICK"
                    putExtra("activityId", activityId)
                    putExtra("actionId", actionId)
                }
                PendingIntent.getBroadcast(
                    context,
                    (notificationId * 10 + index),
                    intent,
                    flags
                )
            }

            builder.addAction(actionIconRes, actionTitle, pendingIntent)
        }

        try {
            notificationManager.notify(notificationId, builder.build())
        } catch (_: SecurityException) {
            // Notification permission might be missing on Android 13+
        }
    }
}
