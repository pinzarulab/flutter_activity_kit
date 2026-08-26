package com.flutteractivitykit

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import android.content.Intent

/** FlutterActivityKitPlugin */
class FlutterActivityKitPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener, PluginRegistry.NewIntentListener {
    private lateinit var methodChannel: MethodChannel
    private lateinit var pushTokensChannel: EventChannel
    private lateinit var stateUpdatesChannel: EventChannel
    private lateinit var actionEventsChannel: EventChannel

    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var notificationManager: OngoingNotificationManager? = null

    private var pendingPermissionResult: Result? = null
    private val PERMISSION_REQUEST_CODE = 49120

    companion object {
        private val mainHandler = Handler(Looper.getMainLooper())
        private var pushTokenSink: EventChannel.EventSink? = null
        private var stateUpdateSink: EventChannel.EventSink? = null
        private var actionEventSink: EventChannel.EventSink? = null

        fun sendActionEvent(activityId: String, actionId: String, payload: Map<String, Any?>? = null) {
            mainHandler.post {
                val data = mapOf(
                    "activityId" to activityId,
                    "actionId" to actionId,
                    "payload" to payload
                )
                actionEventSink?.success(data)
            }
        }

        fun sendStateUpdate(activityId: String, state: String, dismissalDate: Long? = null) {
            mainHandler.post {
                val data = mapOf(
                    "activityId" to activityId,
                    "state" to state,
                    "dismissalDate" to dismissalDate
                )
                stateUpdateSink?.success(data)
            }
        }

        fun sendPushToken(activityId: String, pushToken: String) {
            mainHandler.post {
                val data = mapOf(
                    "activityId" to activityId,
                    "pushToken" to pushToken
                )
                pushTokenSink?.success(data)
            }
        }
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        notificationManager = OngoingNotificationManager(flutterPluginBinding.applicationContext)

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_activity_kit/methods")
        methodChannel.setMethodCallHandler(this)

        pushTokensChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_activity_kit/push_tokens")
        pushTokensChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                pushTokenSink = events
            }

            override fun onCancel(arguments: Any?) {
                pushTokenSink = null
            }
        })

        stateUpdatesChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_activity_kit/state_updates")
        stateUpdatesChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                stateUpdateSink = events
            }

            override fun onCancel(arguments: Any?) {
                stateUpdateSink = null
            }
        })

        actionEventsChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_activity_kit/action_events")
        actionEventsChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                actionEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                actionEventSink = null
            }
        })
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val manager = notificationManager ?: run {
            result.error("NOT_INITIALIZED", "Plugin context not initialized", null)
            return
        }

        when (call.method) {
            "isSupported" -> {
                result.success(true)
            }

            "areActivitiesEnabled" -> {
                result.success(manager.areActivitiesEnabled())
            }

            "requestPermissions" -> {
                requestNotificationPermission(result)
            }

            "getPushToStartToken" -> {
                result.success(null)
            }

            "startActivity" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?>
                if (args == null) {
                    result.error("INVALID_ARGS", "Arguments must be a Map", null)
                    return
                }
                try {
                    val response = manager.startActivity(args)
                    result.success(response)
                } catch (e: Exception) {
                    result.error("START_ACTIVITY_FAILED", e.message, null)
                }
            }

            "updateActivity" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?>
                val activityId = args?.get("activityId") as? String
                @Suppress("UNCHECKED_CAST")
                val contentMap = args?.get("content") as? Map<String, Any?>
                @Suppress("UNCHECKED_CAST")
                val alertMap = args?.get("alert") as? Map<String, Any?>

                if (activityId == null || contentMap == null) {
                    result.error("INVALID_ARGS", "activityId and content are required", null)
                    return
                }

                try {
                    manager.updateActivity(activityId, contentMap, alertMap)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("UPDATE_ACTIVITY_FAILED", e.message, null)
                }
            }

            "endActivity" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?>
                val activityId = args?.get("activityId") as? String
                @Suppress("UNCHECKED_CAST")
                val finalContentMap = args?.get("finalContent") as? Map<String, Any?>
                @Suppress("UNCHECKED_CAST")
                val dismissalPolicyMap = args?.get("dismissalPolicy") as? Map<String, Any?>

                if (activityId == null) {
                    result.error("INVALID_ARGS", "activityId is required", null)
                    return
                }

                try {
                    manager.endActivity(activityId, finalContentMap, dismissalPolicyMap)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("END_ACTIVITY_FAILED", e.message, null)
                }
            }

            "getAllActivities" -> {
                result.success(manager.getAllActivities())
            }

            "getActivity" -> {
                @Suppress("UNCHECKED_CAST")
                val args = call.arguments as? Map<String, Any?>
                val activityId = args?.get("activityId") as? String
                if (activityId == null) {
                    result.error("INVALID_ARGS", "activityId is required", null)
                    return
                }
                result.success(manager.getActivity(activityId))
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    private fun requestNotificationPermission(result: Result) {
        val currentActivity = activity
        val currentContext = context ?: currentActivity

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (currentContext != null &&
                ContextCompat.checkSelfPermission(currentContext, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
            ) {
                result.success(true)
                return
            }

            if (currentActivity != null) {
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    currentActivity,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    PERMISSION_REQUEST_CODE
                )
            } else {
                result.success(notificationManager?.areActivitiesEnabled() ?: false)
            }
        } else {
            result.success(notificationManager?.areActivitiesEnabled() ?: true)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
            return true
        }
        return false
    }

    override fun onNewIntent(intent: Intent): Boolean {
        handleIntent(intent)
        return false
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) return
        val activityId = intent.getStringExtra("activityId")
        val actionId = intent.getStringExtra("actionId")
        if (activityId != null && actionId != null) {
            sendActionEvent(activityId, actionId)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
        handleIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addOnNewIntentListener(this)
        handleIntent(binding.activity.intent)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeOnNewIntentListener(this)
        activity = null
        activityBinding = null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        pushTokensChannel.setStreamHandler(null)
        stateUpdatesChannel.setStreamHandler(null)
        actionEventsChannel.setStreamHandler(null)
        context = null
        notificationManager = null
    }
}
