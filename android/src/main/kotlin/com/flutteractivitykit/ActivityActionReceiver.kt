package com.flutteractivitykit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ActivityActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null || context == null) return

        val activityId = intent.getStringExtra("activityId") ?: return
        val actionId = intent.getStringExtra("actionId") ?: return

        // If the action is an app-opening action, bring app to foreground
        if (actionId.contains("stats") || actionId.contains("open") || actionId.contains("details")) {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("activityId", activityId)
                putExtra("actionId", actionId)
            }
            if (launchIntent != null) {
                context.startActivity(launchIntent)
            }
        }

        FlutterActivityKitPlugin.sendActionEvent(
            activityId = activityId,
            actionId = actionId
        )
    }
}
