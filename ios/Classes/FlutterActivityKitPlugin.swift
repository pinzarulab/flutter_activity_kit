import Flutter
import UIKit
import UserNotifications
#if canImport(ActivityKit)
import ActivityKit
#endif

public class FlutterActivityKitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    public static var instance: FlutterActivityKitPlugin?

    private var pushTokenEventSink: FlutterEventSink?
    private var stateUpdateEventSink: FlutterEventSink?
    private var actionEventSink: FlutterEventSink?

    #if canImport(ActivityKit)
    private var activeTasks: [String: [Task<Void, Never>]] = [:]
    #endif

    override init() {
        super.init()
        FlutterActivityKitPlugin.instance = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleActionNotification(_:)),
            name: NSNotification.Name("FlutterActivityKitActionEvent"),
            object: nil
        )
    }

    @objc private func handleActionNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let activityId = userInfo["activityId"] as? String,
              let actionId = userInfo["actionId"] as? String else { return }
        let payload = userInfo["payload"] as? [String: Any]
        DispatchQueue.main.async { [weak self] in
            self?.sendActionEvent(activityId: activityId, actionId: actionId, payload: payload)
        }
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "flutter_activity_kit/methods", binaryMessenger: registrar.messenger())
        let pushTokensChannel = FlutterEventChannel(name: "flutter_activity_kit/push_tokens", binaryMessenger: registrar.messenger())
        let stateUpdatesChannel = FlutterEventChannel(name: "flutter_activity_kit/state_updates", binaryMessenger: registrar.messenger())
        let actionEventsChannel = FlutterEventChannel(name: "flutter_activity_kit/action_events", binaryMessenger: registrar.messenger())

        let instance = FlutterActivityKitPlugin()
        FlutterActivityKitPlugin.instance = instance
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        registrar.addApplicationDelegate(instance)

        pushTokensChannel.setStreamHandler(PushTokenStreamHandler(plugin: instance))
        stateUpdatesChannel.setStreamHandler(StateUpdateStreamHandler(plugin: instance))
        actionEventsChannel.setStreamHandler(ActionEventStreamHandler(plugin: instance))
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isSupported":
            if #available(iOS 16.1, *) {
                #if canImport(ActivityKit)
                let isPhone = UIDevice.current.userInterfaceIdiom == .phone
                result(isPhone)
                #else
                result(false)
                #endif
            } else {
                result(false)
            }

        case "areActivitiesEnabled":
            if #available(iOS 16.1, *) {
                #if canImport(ActivityKit)
                result(ActivityAuthorizationInfo().areActivitiesEnabled)
                #else
                result(false)
                #endif
            } else {
                result(false)
            }

        case "requestPermissions":
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        result(granted)
                    }
                }
            } else {
                result(true)
            }

        case "getPushToStartToken":
            if #available(iOS 17.2, *) {
                #if canImport(ActivityKit)
                Task {
                    for await tokenData in Activity<FlutterActivityAttributes>.pushToStartTokenUpdates {
                        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
                        DispatchQueue.main.async {
                            result(token)
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        result(nil)
                    }
                }
                #else
                result(nil)
                #endif
            } else {
                result(nil)
            }

        case "startActivity":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Arguments must be a Map", details: nil))
                return
            }
            startActivity(args: args, result: result)

        case "updateActivity":
            guard let args = call.arguments as? [String: Any],
                  let activityId = args["activityId"] as? String,
                  let contentMap = args["content"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "activityId and content are required", details: nil))
                return
            }
            let alertMap = args["alert"] as? [String: Any]
            updateActivity(activityId: activityId, contentMap: contentMap, alertMap: alertMap, result: result)

        case "endActivity":
            guard let args = call.arguments as? [String: Any],
                  let activityId = args["activityId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "activityId is required", details: nil))
                return
            }
            let finalContentMap = args["finalContent"] as? [String: Any]
            let dismissalPolicyMap = args["dismissalPolicy"] as? [String: Any]
            endActivity(activityId: activityId, finalContentMap: finalContentMap, dismissalPolicyMap: dismissalPolicyMap, result: result)

        case "getAllActivities":
            getAllActivities(result: result)

        case "getActivity":
            guard let args = call.arguments as? [String: Any],
                  let activityId = args["activityId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "activityId is required", details: nil))
                return
            }
            getActivity(activityId: activityId, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func startActivity(args: [String: Any], result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result(FlutterError(code: "UNSUPPORTED_OS", message: "Live Activities require iOS 16.1+", details: nil))
            return
        }

        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            result(FlutterError(code: "ACTIVITIES_DISABLED", message: "Live Activities are disabled by user or system", details: nil))
            return
        }

        let activityType = args["activityType"] as? String ?? "GenericActivityAttributes"
        let rawAttributes = args["attributes"] as? [String: Any] ?? [:]
        let rawContent = args["content"] as? [String: Any] ?? [:]
        let rawState = rawContent["state"] as? [String: Any] ?? [:]
        let iosOptions = args["iosOptions"] as? [String: Any] ?? [:]

        var stringAttributes: [String: String] = [:]
        for (k, v) in rawAttributes {
            stringAttributes[k] = "\(v)"
        }

        var stringStateData: [String: String] = [:]
        for (k, v) in rawState {
            stringStateData[k] = "\(v)"
        }

        let progress = (rawState["progress"] as? NSNumber)?.doubleValue
        let title = rawState["title"] as? String
        let message = rawState["message"] as? String
        let status = rawState["status"] as? String

        let attributes = FlutterActivityAttributes(activityType: activityType, staticData: stringAttributes)
        let initialContentState = FlutterActivityAttributes.ContentState(
            data: stringStateData,
            progress: progress,
            title: title,
            message: message,
            status: status
        )

        var staleDate: Date? = nil
        if let staleMs = (rawContent["staleDate"] as? NSNumber)?.int64Value ?? (iosOptions["staleDate"] as? NSNumber)?.int64Value {
            staleDate = Date(timeIntervalSince1970: Double(staleMs) / 1000.0)
        }

        let relevanceScore = (rawContent["relevanceScore"] as? NSNumber)?.doubleValue ?? (iosOptions["relevanceScore"] as? NSNumber)?.doubleValue ?? 0.0

        var pushType: ActivityKit.PushType? = nil
        if let pushTypeStr = iosOptions["pushType"] as? String, pushTypeStr == "token" {
            pushType = .token
        }

        do {
            let activity: Activity<FlutterActivityAttributes>
            if #available(iOS 16.2, *) {
                let activityContent = ActivityContent(
                    state: initialContentState,
                    staleDate: staleDate,
                    relevanceScore: relevanceScore
                )
                activity = try Activity.request(
                    attributes: attributes,
                    content: activityContent,
                    pushType: pushType
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: initialContentState,
                    pushType: pushType
                )
            }

            self.observeActivity(activity)

            var pushTokenHex: String? = nil
            if let tokenData = activity.pushToken {
                pushTokenHex = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            }

            let response: [String: Any] = [
                "id": activity.id,
                "activityType": activity.attributes.activityType,
                "state": self.stateToString(activity.activityState),
                "attributes": rawAttributes,
                "contentState": rawState,
                "pushToken": pushTokenHex as Any
            ]

            result(response)
        } catch {
            result(FlutterError(code: "START_ACTIVITY_FAILED", message: error.localizedDescription, details: nil))
        }
        #else
        result(FlutterError(code: "UNSUPPORTED_PLATFORM", message: "ActivityKit is not available", details: nil))
        #endif
    }

    private func updateActivity(activityId: String, contentMap: [String: Any], alertMap: [String: Any]?, result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result(FlutterError(code: "UNSUPPORTED_OS", message: "Live Activities require iOS 16.1+", details: nil))
            return
        }

        #if canImport(ActivityKit)
        guard let activity = Activity<FlutterActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            result(FlutterError(code: "ACTIVITY_NOT_FOUND", message: "Activity with ID \(activityId) was not found", details: nil))
            return
        }

        let rawState = contentMap["state"] as? [String: Any] ?? [:]
        var stringStateData: [String: String] = [:]
        for (k, v) in rawState {
            stringStateData[k] = "\(v)"
        }

        let progress = (rawState["progress"] as? NSNumber)?.doubleValue
        let title = rawState["title"] as? String
        let message = rawState["message"] as? String
        let status = rawState["status"] as? String

        let updatedContentState = FlutterActivityAttributes.ContentState(
            data: stringStateData,
            progress: progress,
            title: title,
            message: message,
            status: status
        )

        var staleDate: Date? = nil
        if let staleMs = (contentMap["staleDate"] as? NSNumber)?.int64Value {
            staleDate = Date(timeIntervalSince1970: Double(staleMs) / 1000.0)
        }

        let relevanceScore = (contentMap["relevanceScore"] as? NSNumber)?.doubleValue ?? 0.0

        var alertConfig: AlertConfiguration? = nil
        if let alertMap = alertMap {
            let alertTitle = alertMap["title"] as? String ?? ""
            let alertBody = alertMap["body"] as? String ?? ""
            let alertSound = alertMap["sound"] as? String
            if let sound = alertSound, sound != "default" {
                alertConfig = AlertConfiguration(title: "\(alertTitle)", body: "\(alertBody)", sound: .named(sound))
            } else {
                alertConfig = AlertConfiguration(title: "\(alertTitle)", body: "\(alertBody)", sound: .default)
            }
        }

        Task {
            if #available(iOS 16.2, *) {
                let activityContent = ActivityContent(
                    state: updatedContentState,
                    staleDate: staleDate,
                    relevanceScore: relevanceScore
                )
                await activity.update(activityContent, alertConfiguration: alertConfig)
            } else {
                await activity.update(using: updatedContentState, alertConfiguration: alertConfig)
            }

            DispatchQueue.main.async {
                result(nil)
            }
        }
        #else
        result(FlutterError(code: "UNSUPPORTED_PLATFORM", message: "ActivityKit is not available", details: nil))
        #endif
    }

    private func endActivity(activityId: String, finalContentMap: [String: Any]?, dismissalPolicyMap: [String: Any]?, result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result(FlutterError(code: "UNSUPPORTED_OS", message: "Live Activities require iOS 16.1+", details: nil))
            return
        }

        #if canImport(ActivityKit)
        guard let activity = Activity<FlutterActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            result(FlutterError(code: "ACTIVITY_NOT_FOUND", message: "Activity with ID \(activityId) was not found", details: nil))
            return
        }

        var finalContentState: FlutterActivityAttributes.ContentState? = nil
        var staleDate: Date? = nil
        var relevanceScore: Double = 0.0

        if let finalMap = finalContentMap {
            let rawState = finalMap["state"] as? [String: Any] ?? [:]
            var stringStateData: [String: String] = [:]
            for (k, v) in rawState {
                stringStateData[k] = "\(v)"
            }
            finalContentState = FlutterActivityAttributes.ContentState(
                data: stringStateData,
                progress: (rawState["progress"] as? NSNumber)?.doubleValue,
                title: rawState["title"] as? String,
                message: rawState["message"] as? String,
                status: rawState["status"] as? String
            )
            if let ms = (finalMap["staleDate"] as? NSNumber)?.int64Value {
                staleDate = Date(timeIntervalSince1970: Double(ms) / 1000.0)
            }
            relevanceScore = (finalMap["relevanceScore"] as? NSNumber)?.doubleValue ?? 0.0
        }

        var dismissalPolicy: ActivityUIDismissalPolicy = .default
        if let policyMap = dismissalPolicyMap {
            let type = policyMap["type"] as? String ?? "default"
            if type == "immediate" {
                dismissalPolicy = .immediate
            } else if type == "after", let afterMs = (policyMap["afterDate"] as? NSNumber)?.int64Value {
                dismissalPolicy = .after(Date(timeIntervalSince1970: Double(afterMs) / 1000.0))
            }
        }

        Task {
            if #available(iOS 16.2, *) {
                if let state = finalContentState {
                    let content = ActivityContent(state: state, staleDate: staleDate, relevanceScore: relevanceScore)
                    await activity.end(content, dismissalPolicy: dismissalPolicy)
                } else {
                    await activity.end(nil, dismissalPolicy: dismissalPolicy)
                }
            } else {
                if let state = finalContentState {
                    await activity.end(using: state, dismissalPolicy: dismissalPolicy)
                } else {
                    await activity.end(using: activity.contentState, dismissalPolicy: dismissalPolicy)
                }
            }

            self.cancelTasks(for: activityId)

            DispatchQueue.main.async {
                result(nil)
            }
        }
        #else
        result(FlutterError(code: "UNSUPPORTED_PLATFORM", message: "ActivityKit is not available", details: nil))
        #endif
    }

    private func getAllActivities(result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result([])
            return
        }

        #if canImport(ActivityKit)
        let list = Activity<FlutterActivityAttributes>.activities.map { activity -> [String: Any] in
            var tokenHex: String? = nil
            if let tokenData = activity.pushToken {
                tokenHex = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            }

            let contentStateData: [String: String]
            if #available(iOS 16.2, *) {
                contentStateData = activity.content.state.data
            } else {
                contentStateData = activity.contentState.data
            }

            return [
                "id": activity.id,
                "activityType": activity.attributes.activityType,
                "state": self.stateToString(activity.activityState),
                "attributes": activity.attributes.staticData,
                "contentState": contentStateData,
                "pushToken": tokenHex as Any
            ]
        }
        result(list)
        #else
        result([])
        #endif
    }

    private func getActivity(activityId: String, result: @escaping FlutterResult) {
        guard #available(iOS 16.1, *) else {
            result(nil)
            return
        }

        #if canImport(ActivityKit)
        guard let activity = Activity<FlutterActivityAttributes>.activities.first(where: { $0.id == activityId }) else {
            result(nil)
            return
        }

        var tokenHex: String? = nil
        if let tokenData = activity.pushToken {
            tokenHex = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        }

        let contentStateData: [String: String]
        if #available(iOS 16.2, *) {
            contentStateData = activity.content.state.data
        } else {
            contentStateData = activity.contentState.data
        }

        let response: [String: Any] = [
            "id": activity.id,
            "activityType": activity.attributes.activityType,
            "state": self.stateToString(activity.activityState),
            "attributes": activity.attributes.staticData,
            "contentState": contentStateData,
            "pushToken": tokenHex as Any
        ]
        result(response)
        #else
        result(nil)
        #endif
    }

    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func observeActivity(_ activity: Activity<FlutterActivityAttributes>) {
        let activityId = activity.id
        var tasks: [Task<Void, Never>] = []

        // Token observation task
        let tokenTask = Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
                DispatchQueue.main.async { [weak self] in
                    self?.pushTokenEventSink?([
                        "activityId": activityId,
                        "pushToken": token
                    ])
                }
            }
        }
        tasks.append(tokenTask)

        // State update observation task
        let stateTask = Task {
            for await state in activity.activityStateUpdates {
                let stateStr = self.stateToString(state)
                DispatchQueue.main.async { [weak self] in
                    self?.stateUpdateEventSink?([
                        "activityId": activityId,
                        "state": stateStr
                    ])
                }
            }
        }
        tasks.append(stateTask)

        activeTasks[activityId] = tasks
    }

    @available(iOS 16.1, *)
    private func cancelTasks(for activityId: String) {
        if let tasks = activeTasks[activityId] {
            for task in tasks {
                task.cancel()
            }
            activeTasks.removeValue(forKey: activityId)
        }
    }

    @available(iOS 16.1, *)
    private func stateToString(_ state: ActivityState) -> String {
        switch state {
        case .active:
            return "active"
        case .stale:
            return "stale"
        case .ended:
            return "ended"
        case .dismissed:
            return "dismissed"
        @unknown default:
            return "unknown"
        }
    }
    #endif

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }

    // Handlers for individual event streams
    fileprivate func setPushTokenSink(_ sink: FlutterEventSink?) {
        self.pushTokenEventSink = sink
    }

    fileprivate func setStateUpdateSink(_ sink: FlutterEventSink?) {
        self.stateUpdateEventSink = sink
    }

    fileprivate func setActionEventSink(_ sink: FlutterEventSink?) {
        self.actionEventSink = sink
    }

    public func sendActionEvent(activityId: String, actionId: String, payload: [String: Any]? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.actionEventSink?([
                "activityId": activityId,
                "actionId": actionId,
                "payload": payload as Any
            ])
        }
    }

    public static func sendActionEvent(activityId: String, actionId: String, payload: [String: Any]? = nil) {
        DispatchQueue.main.async {
            instance?.sendActionEvent(activityId: activityId, actionId: actionId, payload: payload)
        }
    }
}

private class PushTokenStreamHandler: NSObject, FlutterStreamHandler {
    private weak var plugin: FlutterActivityKitPlugin?
    init(plugin: FlutterActivityKitPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setPushTokenSink(events)
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setPushTokenSink(nil)
        return nil
    }
}

private class StateUpdateStreamHandler: NSObject, FlutterStreamHandler {
    private weak var plugin: FlutterActivityKitPlugin?
    init(plugin: FlutterActivityKitPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setStateUpdateSink(events)
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setStateUpdateSink(nil)
        return nil
    }
}

private class ActionEventStreamHandler: NSObject, FlutterStreamHandler {
    private weak var plugin: FlutterActivityKitPlugin?
    init(plugin: FlutterActivityKitPlugin) { self.plugin = plugin }
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        plugin?.setActionEventSink(events)
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        plugin?.setActionEventSink(nil)
        return nil
    }
}
