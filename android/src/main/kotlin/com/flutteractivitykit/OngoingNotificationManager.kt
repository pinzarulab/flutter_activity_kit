package com.flutteractivitykit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

internal class ActivityNotFoundException(activityId: String) :
    IllegalStateException("Activity with ID $activityId was not found")

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
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    private var nextNotificationId = preferences.getInt(NEXT_NOTIFICATION_ID_KEY, 1000)

    init {
        restoreActivities()
    }

    fun areActivitiesEnabled(): Boolean = notificationManager.areNotificationsEnabled()

    private fun getOrCreateChannel(
        channelId: String,
        channelName: String,
        channelDescription: String?,
        priority: Int,
        sound: String?
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val importance = when (priority) {
            2 -> NotificationManager.IMPORTANCE_HIGH
            0 -> NotificationManager.IMPORTANCE_LOW
            else -> NotificationManager.IMPORTANCE_DEFAULT
        }
        val channel = NotificationChannel(channelId, channelName, importance).apply {
            description = channelDescription
            setShowBadge(true)
            if (sound != null && sound != "default") {
                setSound(
                    resolveSoundUri(sound),
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build()
                )
            }
        }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun getIconResourceId(iconName: String?): Int {
        if (iconName != null) {
            val drawable = context.resources.getIdentifier(iconName, "drawable", context.packageName)
            if (drawable != 0) return drawable
            val mipmap = context.resources.getIdentifier(iconName, "mipmap", context.packageName)
            if (mipmap != 0) return mipmap
        }
        val launcher = context.resources.getIdentifier("ic_launcher", "mipmap", context.packageName)
        return if (launcher != 0) launcher else android.R.drawable.ic_dialog_info
    }

    private fun resolveSoundUri(sound: String): Uri {
        val resourceId = context.resources.getIdentifier(
            sound.substringBeforeLast('.'),
            "raw",
            context.packageName
        )
        return if (resourceId != 0) {
            Uri.parse("android.resource://${context.packageName}/$resourceId")
        } else {
            Uri.parse(sound)
        }
    }

    fun startActivity(args: Map<String, Any?>): Map<String, Any?> {
        val activityId = UUID.randomUUID().toString()
        val activityType = args["activityType"] as? String ?: "GenericActivity"
        @Suppress("UNCHECKED_CAST")
        val attributes = args["attributes"] as? Map<String, Any?> ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val content = args["content"] as? Map<String, Any?> ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val state = content["state"] as? Map<String, Any?> ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        val options = args["androidOptions"] as? Map<String, Any?> ?: emptyMap()

        val notificationId = synchronized(this) {
            val value = nextNotificationId++
            preferences.edit().putInt(NEXT_NOTIFICATION_ID_KEY, nextNotificationId).apply()
            value
        }

        @Suppress("UNCHECKED_CAST")
        buildAndPostNotification(
            activityId,
            notificationId,
            state,
            options,
            content["alert"] as? Map<String, Any?>
        )

        val tracked = TrackedActivity(
            activityId,
            activityType,
            "active",
            attributes,
            state,
            options,
            notificationId
        )
        trackedActivities[activityId] = tracked
        persistActivities()
        FlutterActivityKitPlugin.sendStateUpdate(activityId, "active")
        return tracked.toMap()
    }

    fun updateActivity(
        activityId: String,
        contentMap: Map<String, Any?>,
        alertMap: Map<String, Any?>?
    ) {
        val tracked = trackedActivities[activityId] ?: throw ActivityNotFoundException(activityId)
        @Suppress("UNCHECKED_CAST")
        val state = contentMap["state"] as? Map<String, Any?> ?: emptyMap()
        @Suppress("UNCHECKED_CAST")
        buildAndPostNotification(
            activityId,
            tracked.notificationId,
            state,
            tracked.androidOptions,
            alertMap ?: contentMap["alert"] as? Map<String, Any?>
        )
        tracked.contentState = state
        persistActivities()
    }

    fun endActivity(
        activityId: String,
        finalContentMap: Map<String, Any?>?,
        dismissalPolicyMap: Map<String, Any?>?
    ) {
        val tracked = trackedActivities[activityId] ?: throw ActivityNotFoundException(activityId)
        val policy = dismissalPolicyMap?.get("type") as? String ?: "default"
        if (policy == "immediate" || finalContentMap == null) {
            notificationManager.cancel(tracked.notificationId)
        } else {
            @Suppress("UNCHECKED_CAST")
            val finalState = finalContentMap["state"] as? Map<String, Any?> ?: emptyMap()
            val options = tracked.androidOptions.toMutableMap().apply {
                put("ongoing", false)
                if (policy == "after") {
                    val afterDate = (dismissalPolicyMap?.get("afterDate") as? Number)?.toLong()
                    if (afterDate != null) {
                        put("timeoutAfterMs", (afterDate - System.currentTimeMillis()).coerceAtLeast(1L))
                    }
                }
            }
            @Suppress("UNCHECKED_CAST")
            buildAndPostNotification(
                activityId,
                tracked.notificationId,
                finalState,
                options,
                finalContentMap["alert"] as? Map<String, Any?>
            )
        }
        trackedActivities.remove(activityId)
        persistActivities()
        FlutterActivityKitPlugin.sendStateUpdate(activityId, "ended")
    }

    fun getAllActivities(): List<Map<String, Any?>> =
        trackedActivities.values.map { it.toMap() }

    fun getActivity(activityId: String): Map<String, Any?>? = trackedActivities[activityId]?.toMap()

    private fun TrackedActivity.toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "activityType" to activityType,
        "state" to state,
        "attributes" to attributes,
        "contentState" to contentState,
        "pushToken" to null
    )

    private fun buildAndPostNotification(
        activityId: String,
        notificationId: Int,
        contentState: Map<String, Any?>,
        androidOptions: Map<String, Any?>,
        alertMap: Map<String, Any?>? = null
    ) {
        val channelId = androidOptions["channelId"] as? String ?: "flutter_activity_kit_channel"
        val channelName = androidOptions["channelName"] as? String ?: "Live Activities"
        val priority = (androidOptions["priority"] as? Number)?.toInt() ?: 1
        getOrCreateChannel(
            channelId,
            channelName,
            androidOptions["channelDescription"] as? String,
            priority,
            androidOptions["sound"] as? String
        )

        val title = contentState["title"] as? String
            ?: contentState["status"] as? String
            ?: "Live Update"
        val message = contentState["message"] as? String
            ?: contentState["body"] as? String
            ?: ""
        val ongoing = androidOptions["ongoing"] as? Boolean ?: true
        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(getIconResourceId(androidOptions["smallIcon"] as? String))
            .setContentTitle(title)
            .setContentText(message)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setOnlyAlertOnce(alertMap == null)
            .setShowWhen(androidOptions["showWhen"] as? Boolean ?: true)
            .setCategory(androidOptions["category"] as? String ?: NotificationCompat.CATEGORY_STATUS)
            .setPriority(
                when (priority) {
                    2 -> NotificationCompat.PRIORITY_HIGH
                    0 -> NotificationCompat.PRIORITY_LOW
                    else -> NotificationCompat.PRIORITY_DEFAULT
                }
            )

        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

        context.packageManager.getLaunchIntentForPackage(context.packageName)?.let { launchIntent ->
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            launchIntent.putExtra("activityId", activityId)
            builder.setContentIntent(PendingIntent.getActivity(context, notificationId, launchIntent, flags))
        }

        (androidOptions["subText"] as? String ?: contentState["subText"] as? String)?.let(builder::setSubText)
        (androidOptions["color"] as? Number)?.toInt()?.let(builder::setColor)
        (androidOptions["largeIcon"] as? String)?.let { name ->
            builder.setLargeIcon(
                BitmapFactory.decodeResource(context.resources, getIconResourceId(name))
            )
        }
        (androidOptions["timeoutAfterMs"] as? Number)?.toLong()?.let(builder::setTimeoutAfter)

        val sound = alertMap?.get("sound") as? String ?: androidOptions["sound"] as? String
        if (sound != null) {
            if (sound == "default") {
                builder.setDefaults(NotificationCompat.DEFAULT_SOUND)
            } else {
                builder.setSound(resolveSoundUri(sound))
            }
        }

        val progress = (contentState["progress"] as? Number)?.toDouble()
            ?: (androidOptions["progress"] as? Number)?.toDouble()
        val indeterminate = androidOptions["isIndeterminate"] as? Boolean ?: false
        if (progress != null || indeterminate) {
            builder.setProgress(
                100,
                ((progress ?: 0.0) * 100).toInt().coerceIn(0, 100),
                indeterminate
            )
        }

        @Suppress("UNCHECKED_CAST")
        val timer = contentState["timer"] as? Map<String, Any?>
            ?: androidOptions["timer"] as? Map<String, Any?>
        if (timer != null) {
            val countsDown = timer["countsDown"] as? Boolean ?: true
            val target = (timer["targetDate"] as? Number)?.toLong()
            val start = (timer["startDate"] as? Number)?.toLong() ?: System.currentTimeMillis()
            builder.setUsesChronometer(true)
            builder.setWhen(if (countsDown && target != null) target else start)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder.setChronometerCountDown(countsDown)
            }
        } else if (androidOptions["isChronometer"] as? Boolean ?: false) {
            builder.setUsesChronometer(true)
            (androidOptions["chronometerBase"] as? Number)?.toLong()?.let(builder::setWhen)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder.setChronometerCountDown(
                    androidOptions["chronometerCountDown"] as? Boolean ?: false
                )
            }
        }

        @Suppress("UNCHECKED_CAST")
        val actions = androidOptions["actions"] as? List<Map<String, Any?>> ?: emptyList()
        actions.forEachIndexed { index, action ->
            val actionId = action["id"] as? String ?: "action_$index"
            val titleText = action["title"] as? String ?: "Action"
            val behavior = if (action["authenticationRequired"] as? Boolean == true) {
                "opensApp"
            } else {
                action["behavior"] as? String ?: "opensApp"
            }
            val requestCode = notificationId * 10 + index
            val payloadJson = (action["payload"] as? Map<*, *>)?.let { JSONObject(it).toString() }
            val pendingIntent = when (behavior) {
                "background" -> actionBroadcastIntent(
                    activityId,
                    actionId,
                    payloadJson,
                    requestCode,
                    flags
                )
                "deepLink" -> {
                    val uri = action["uri"] as? String
                        ?: throw IllegalArgumentException("Action $actionId requires a URI")
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(uri)).apply {
                        this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra("activityId", activityId)
                        putExtra("actionId", actionId)
                        putExtra("payloadJson", payloadJson)
                    }
                    PendingIntent.getActivity(context, requestCode, intent, flags)
                }
                else -> {
                    val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                        this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                        putExtra("activityId", activityId)
                        putExtra("actionId", actionId)
                        putExtra("payloadJson", payloadJson)
                    }
                    if (intent == null) {
                        actionBroadcastIntent(activityId, actionId, payloadJson, requestCode, flags)
                    } else {
                        PendingIntent.getActivity(context, requestCode, intent, flags)
                    }
                }
            }
            builder.addAction(
                getIconResourceId(action["icon"] as? String),
                titleText,
                pendingIntent
            )
        }

        notificationManager.notify(notificationId, builder.build())
    }

    private fun actionBroadcastIntent(
        activityId: String,
        actionId: String,
        payloadJson: String?,
        requestCode: Int,
        flags: Int
    ): PendingIntent {
        val intent = Intent(context, ActivityActionReceiver::class.java).apply {
            action = ACTION_CLICK
            putExtra("activityId", activityId)
            putExtra("actionId", actionId)
            putExtra("payloadJson", payloadJson)
        }
        return PendingIntent.getBroadcast(context, requestCode, intent, flags)
    }

    private fun persistActivities() {
        val array = JSONArray()
        trackedActivities.values.forEach { activity ->
            array.put(JSONObject().apply {
                put("id", activity.id)
                put("activityType", activity.activityType)
                put("state", activity.state)
                put("attributes", toJson(activity.attributes))
                put("contentState", toJson(activity.contentState))
                put("androidOptions", toJson(activity.androidOptions))
                put("notificationId", activity.notificationId)
            })
        }
        preferences.edit().putString(ACTIVITIES_KEY, array.toString()).apply()
    }

    private fun restoreActivities() {
        val encoded = preferences.getString(ACTIVITIES_KEY, null) ?: return
        runCatching {
            val array = JSONArray(encoded)
            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                val activity = TrackedActivity(
                    item.getString("id"),
                    item.getString("activityType"),
                    item.optString("state", "active"),
                    fromJsonObject(item.getJSONObject("attributes")),
                    fromJsonObject(item.getJSONObject("contentState")),
                    fromJsonObject(item.getJSONObject("androidOptions")),
                    item.getInt("notificationId")
                )
                trackedActivities[activity.id] = activity
            }
        }.onFailure {
            preferences.edit().remove(ACTIVITIES_KEY).apply()
        }
    }

    private fun toJson(value: Any?): Any = when (value) {
        null -> JSONObject.NULL
        is Map<*, *> -> JSONObject().apply {
            value.forEach { (key, nested) -> put(key.toString(), toJson(nested)) }
        }
        is Iterable<*> -> JSONArray().apply { value.forEach { put(toJson(it)) } }
        else -> value
    }

    private fun fromJsonObject(json: JSONObject): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()
        json.keys().forEach { key -> result[key] = fromJson(json.get(key)) }
        return result
    }

    private fun fromJson(value: Any): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> fromJsonObject(value)
        is JSONArray -> List(value.length()) { index -> fromJson(value.get(index)) }
        else -> value
    }

    companion object {
        const val ACTION_CLICK = "com.flutteractivitykit.ACTION_CLICK"
        private const val PREFERENCES_NAME = "flutter_activity_kit"
        private const val ACTIVITIES_KEY = "tracked_activities"
        private const val NEXT_NOTIFICATION_ID_KEY = "next_notification_id"
    }
}
