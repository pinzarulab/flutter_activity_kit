package com.flutteractivitykit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ActivityActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null) return

        val activityId = intent.getStringExtra("activityId") ?: return
        val actionId = intent.getStringExtra("actionId") ?: return

        FlutterActivityKitPlugin.sendActionEvent(
            activityId = activityId,
            actionId = actionId
        )
    }
}
