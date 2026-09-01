package com.flutteractivitykit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import org.json.JSONObject
import org.json.JSONArray

class ActivityActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null || context == null) return

        val activityId = intent.getStringExtra("activityId") ?: return
        val actionId = intent.getStringExtra("actionId") ?: return

        val payload = intent.getStringExtra("payloadJson")?.let { encoded ->
            val json = JSONObject(encoded)
            jsonValueToDart(json) as Map<String, Any?>
        }

        FlutterActivityKitPlugin.sendActionEvent(
            activityId = activityId,
            actionId = actionId,
            payload = payload,
            sourceContext = context
        )
    }
}

internal fun jsonValueToDart(value: Any?): Any? = when (value) {
    null, JSONObject.NULL -> null
    is JSONObject -> value.keys().asSequence().associateWith { jsonValueToDart(value.get(it)) }
    is JSONArray -> List(value.length()) { jsonValueToDart(value.get(it)) }
    else -> value
}

internal object PendingActionStore {
    private const val PREFERENCES = "flutter_activity_kit"
    private const val KEY = "pending_action_events"

    @Synchronized
    fun add(
        context: Context,
        activityId: String,
        actionId: String,
        payload: Map<String, Any?>?
    ) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val events = runCatching {
            JSONArray(preferences.getString(KEY, "[]"))
        }.getOrElse { JSONArray() }
        events.put(JSONObject().apply {
            put("activityId", activityId)
            put("actionId", actionId)
            put("payload", payload?.let(::toJson) ?: JSONObject.NULL)
        })
        preferences.edit().putString(KEY, events.toString()).apply()
    }

    @Synchronized
    fun drain(context: Context): List<Map<String, Any?>> {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        val events = runCatching {
            JSONArray(preferences.getString(KEY, "[]"))
        }.getOrElse { JSONArray() }
        val result = List(events.length()) { index ->
            val event = events.getJSONObject(index)
            mapOf(
                "activityId" to event.getString("activityId"),
                "actionId" to event.getString("actionId"),
                "payload" to jsonValueToDart(event.opt("payload"))
            )
        }
        preferences.edit().remove(KEY).apply()
        return result
    }

    private fun toJson(value: Any?): Any = when (value) {
        null -> JSONObject.NULL
        is Map<*, *> -> JSONObject().apply {
            value.forEach { (key, nested) -> put(key.toString(), toJson(nested)) }
        }
        is Iterable<*> -> JSONArray().apply { value.forEach { put(toJson(it)) } }
        else -> value
    }

}
