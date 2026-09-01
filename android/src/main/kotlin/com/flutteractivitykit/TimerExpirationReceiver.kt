package com.flutteractivitykit

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class TimerExpirationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != OngoingNotificationManager.ACTION_TIMER_EXPIRED) return
        val activityId = intent.getStringExtra("activityId") ?: return
        OngoingNotificationManager(context.applicationContext).completeCountdown(activityId)
    }
}
