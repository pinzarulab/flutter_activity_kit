import Flutter
import UIKit
import UserNotifications
import CoreHaptics
import AudioToolbox
#if canImport(ActivityKit)
import ActivityKit
#endif

public class FlutterActivityKitPlugin: NSObject, FlutterPlugin, FlutterStreamHandler, UIWindowSceneDelegate {
    public static var instance: FlutterActivityKitPlugin?
    private static var pendingPreRegistrationActions: [(String, String, [String: Any]?)] = []

    private var pushTokenEventSink: FlutterEventSink?
    private var stateUpdateEventSink: FlutterEventSink?
    private var actionEventSink: FlutterEventSink?
    private var pendingPushTokenEvents: [[String: Any]] = []
    private var pendingStateEvents: [[String: Any]] = []
    private var pendingActionEvents: [[String: Any]] = []
    private var recentActionEvents: [String: Date] = [:]

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
        pendingPreRegistrationActions.forEach {
            instance.sendActionEvent(activityId: $0.0, actionId: $0.1, payload: $0.2)
        }
        pendingPreRegistrationActions.removeAll()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        registrar.addApplicationDelegate(instance)
        if #available(iOS 13.0, *) {
            registrar.addSceneDelegate(instance)
        }

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
                if let tokenData = Activity<FlutterActivityAttributes>.pushToStartToken {
                    let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
                    result(token)
                } else {
                    result(nil)
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

        if let rawActions = args["actions"] as? [[String: Any]] {
            stringAttributes["action_count"] = "\(rawActions.count)"
            for (idx, act) in rawActions.enumerated() {
                if let actId = act["id"] as? String {
                    stringAttributes["action_\(idx)_id"] = actId
                }
                if let actTitle = act["title"] as? String {
                    stringAttributes["action_\(idx)_title"] = actTitle
                }
                if let actIcon = act["icon"] as? String {
                    stringAttributes["action_\(idx)_icon"] = actIcon
                }
            }
        }

        let stringStateData = self.sanitizeStateData(from: rawState)

        let progress = (rawState["progress"] as? NSNumber)?.doubleValue
        let title = rawState["title"] as? String
        let message = rawState["message"] as? String
        let status = rawState["status"] as? String

        let timerConfig = self.parseTimer(from: rawContent, rawState)

        let attributes = FlutterActivityAttributes(activityType: activityType, staticData: stringAttributes)
        let initialContentState = FlutterActivityAttributes.ContentState(
            data: stringStateData,
            progress: progress,
            title: title,
            message: message,
            status: status,
            timerStartDate: timerConfig.startDate,
            timerTargetDate: timerConfig.targetDate,
            timerCountsDown: timerConfig.countsDown,
            timerIsPaused: timerConfig.isPaused
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

        if let alertMap = args["alert"] as? [String: Any],
           let haptic = alertMap["haptic"] as? String,
           !haptic.isEmpty, haptic != "none" {
            self.triggerIOSHaptic(haptic: haptic)
        } else if let haptic = rawContent["haptic"] as? String ?? rawState["haptic"] as? String,
                  !haptic.isEmpty, haptic != "none" {
            self.triggerIOSHaptic(haptic: haptic)
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
        let stringStateData = self.sanitizeStateData(from: rawState)

        let progress = (rawState["progress"] as? NSNumber)?.doubleValue
        let title = rawState["title"] as? String
        let message = rawState["message"] as? String
        let status = rawState["status"] as? String

        let timerConfig = self.parseTimer(from: contentMap, rawState)

        let updatedContentState = FlutterActivityAttributes.ContentState(
            data: stringStateData,
            progress: progress,
            title: title,
            message: message,
            status: status,
            timerStartDate: timerConfig.startDate,
            timerTargetDate: timerConfig.targetDate,
            timerCountsDown: timerConfig.countsDown,
            timerIsPaused: timerConfig.isPaused
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
            if let sound = alertSound {
                if sound == "none" || sound == "silent" {
                    alertConfig = AlertConfiguration(title: "\(alertTitle)", body: "\(alertBody)", sound: nil)
                } else if sound != "default" {
                    alertConfig = AlertConfiguration(title: "\(alertTitle)", body: "\(alertBody)", sound: .named(sound))
                } else {
                    alertConfig = AlertConfiguration(title: "\(alertTitle)", body: "\(alertBody)", sound: .default)
                }
            } else {
                // When sound is omitted/nil in Dart, avoid forcing iOS .default (which forces a long heavy generic buzz)
                alertConfig = AlertConfiguration(title: "\(alertTitle)", body: "\(alertBody)", sound: nil)
            }
            if let haptic = alertMap["haptic"] as? String, !haptic.isEmpty, haptic != "none" {
                self.triggerIOSHaptic(haptic: haptic)
            }
        } else if let haptic = contentMap["haptic"] as? String ?? rawState["haptic"] as? String, !haptic.isEmpty, haptic != "none" {
            self.triggerIOSHaptic(haptic: haptic)
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

    private func parseTimer(from dicts: [String: Any]?...) -> (startDate: Date?, targetDate: Date?, countsDown: Bool?, isPaused: Bool?) {
        for dict in dicts {
            guard let map = dict else { continue }
            let timerMap = map["timer"] as? [String: Any]
            if let timer = timerMap {
                var startDate: Date? = nil
                var targetDate: Date? = nil

                if let startMs = (timer["startDate"] as? NSNumber)?.doubleValue {
                    startDate = Date(timeIntervalSince1970: startMs / 1000.0)
                }
                if let targetMs = (timer["targetDate"] as? NSNumber)?.doubleValue {
                    targetDate = Date(timeIntervalSince1970: targetMs / 1000.0)
                }
                let countsDown = timer["countsDown"] as? Bool ?? true
                let isPaused = timer["isPaused"] as? Bool ?? false
                return (startDate, targetDate, countsDown, isPaused)
            }
        }
        return (nil, nil, nil, nil)
    }

    private func sanitizeStateData(from state: [String: Any]) -> [String: String] {
        var sanitized: [String: String] = [:]
        for (k, v) in state {
            sanitized[k] = "\(v)"
        }
        return sanitized
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
            let timerConfig = self.parseTimer(from: finalMap, rawState)
            finalContentState = FlutterActivityAttributes.ContentState(
                data: stringStateData,
                progress: (rawState["progress"] as? NSNumber)?.doubleValue,
                title: rawState["title"] as? String,
                message: rawState["message"] as? String,
                status: rawState["status"] as? String,
                timerStartDate: timerConfig.startDate,
                timerTargetDate: timerConfig.targetDate,
                timerCountsDown: timerConfig.countsDown,
                timerIsPaused: timerConfig.isPaused
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
                    guard let self = self else { return }
                    let event: [String: Any] = [
                        "activityId": activityId,
                        "pushToken": token
                    ]
                    if let sink = self.pushTokenEventSink {
                        sink(event)
                    } else {
                        self.pendingPushTokenEvents.append(event)
                    }
                }
            }
        }
        tasks.append(tokenTask)

        // State update observation task
        let stateTask = Task {
            for await state in activity.activityStateUpdates {
                let stateStr = self.stateToString(state)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let event: [String: Any] = [
                        "activityId": activityId,
                        "state": stateStr
                    ]
                    if let sink = self.stateUpdateEventSink {
                        sink(event)
                    } else {
                        self.pendingStateEvents.append(event)
                    }
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
        if let sink = sink, !pendingPushTokenEvents.isEmpty {
            pendingPushTokenEvents.forEach { sink($0) }
            pendingPushTokenEvents.removeAll()
        }
    }

    fileprivate func setStateUpdateSink(_ sink: FlutterEventSink?) {
        self.stateUpdateEventSink = sink
        if let sink = sink, !pendingStateEvents.isEmpty {
            pendingStateEvents.forEach { sink($0) }
            pendingStateEvents.removeAll()
        }
    }

    fileprivate func setActionEventSink(_ sink: FlutterEventSink?) {
        self.actionEventSink = sink
        if let sink = sink, !pendingActionEvents.isEmpty {
            pendingActionEvents.forEach { sink($0) }
            pendingActionEvents.removeAll()
        }
    }

    public func triggerIOSHaptic(haptic: String) {
        DispatchQueue.main.async {
            HapticEngineManager.shared.play(haptic: haptic)
        }
    }

    public func sendActionEvent(activityId: String, actionId: String, payload: [String: Any]? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if actionId.contains("success") {
                self.triggerIOSHaptic(haptic: "success")
            } else if actionId.contains("warning") {
                self.triggerIOSHaptic(haptic: "warning")
            } else if actionId.contains("error") {
                self.triggerIOSHaptic(haptic: "error")
            } else if actionId.contains("heavy") {
                self.triggerIOSHaptic(haptic: "impactHeavy")
            } else if actionId.contains("light") {
                self.triggerIOSHaptic(haptic: "impactLight")
            } else if actionId.contains("selection") {
                self.triggerIOSHaptic(haptic: "selection")
            } else {
                self.triggerIOSHaptic(haptic: "impactMedium")
            }

            let eventKey = "\(activityId)|\(actionId)"
            let now = Date()
            if let previous = self.recentActionEvents[eventKey],
               now.timeIntervalSince(previous) < 0.75 {
                return
            }
            self.recentActionEvents[eventKey] = now
            if self.recentActionEvents.count > 50 {
                self.recentActionEvents = self.recentActionEvents.filter {
                    now.timeIntervalSince($0.value) < 5
                }
            }
            let event: [String: Any] = [
                "activityId": activityId,
                "actionId": actionId,
                "payload": payload as Any
            ]
            if let sink = self.actionEventSink {
                sink(event)
            } else {
                self.pendingActionEvents.append(event)
            }
        }
    }

    // MARK: - UIScene Lifecycle Support (iOS 13+)
    @available(iOS 13.0, *)
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            _ = handleOpenURL(context.url)
        }
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return handleOpenURL(url)
    }

    private func handleOpenURL(_ url: URL) -> Bool {
        guard url.scheme == "flutteractivitykit" else { return false }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let actionId = url.host == "action"
            ? url.path.split(separator: "/").first.map(String.init)
            : url.host
        guard let actionId = actionId, !actionId.isEmpty else { return false }
        let activityId = components?.queryItems?
            .first(where: { $0.name == "activityId" })?.value ?? ""
        sendActionEvent(activityId: activityId, actionId: actionId)
        return true
    }

    public static func sendActionEvent(activityId: String, actionId: String, payload: [String: Any]? = nil) {
        DispatchQueue.main.async {
            if let instance = instance {
                instance.sendActionEvent(activityId: activityId, actionId: actionId, payload: payload)
            } else {
                pendingPreRegistrationActions.append((activityId, actionId, payload))
            }
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

// MARK: - CoreHaptics Advanced Vibration Engine
public class HapticEngineManager {
    public static let shared = HapticEngineManager()
    private var engine: CHHapticEngine?
    private var isEngineReady = false

    public init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    self?.isEngineReady = false
                }
            }
            engine?.stoppedHandler = { [weak self] reason in
                self?.isEngineReady = false
            }
            try engine?.start()
            isEngineReady = true
        } catch {
            isEngineReady = false
        }
    }

    public func play(haptic: String) {
        // Swift Default System Haptics for success, warning/alert, and error
        switch haptic {
        case "success":
            AudioServicesPlaySystemSound(1519)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
            return
        case "warning", "alert":
            AudioServicesPlaySystemSound(1519)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
            return
        case "error":
            AudioServicesPlaySystemSound(1521)
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
            return
        default:
            break
        }

        // Custom CoreHaptics for impactHeavy, impactMedium, impactLight, selection
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            fallbackHaptic(haptic: haptic)
            return
        }

        do {
            if engine == nil || !isEngineReady {
                setupEngine()
            }
            try engine?.start()
            isEngineReady = true

            var events: [CHHapticEvent] = []

            switch haptic {
            case "impactHeavy":
                // Custom Heavy: Deep sustained sub-bass impact thud
                let p1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let s1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.05)
                let event1 = CHHapticEvent(eventType: .hapticContinuous, parameters: [p1, s1], relativeTime: 0, duration: 0.10)

                let p2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
                let s2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [p2, s2], relativeTime: 0.04)
                events = [event1, event2]

            case "impactMedium":
                // Custom Medium: Crisp punchy click
                let p = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75)
                let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.55)
                let event = CHHapticEvent(eventType: .hapticTransient, parameters: [p, s], relativeTime: 0)
                events = [event]

            case "impactLight":
                // Custom Light: Subtle delicate tick
                let p = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.40)
                let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.90)
                let event = CHHapticEvent(eventType: .hapticTransient, parameters: [p, s], relativeTime: 0)
                events = [event]

            case "selection":
                // Custom Selection: Feather micro-tap
                let p = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25)
                let s = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.75)
                let event = CHHapticEvent(eventType: .hapticTransient, parameters: [p, s], relativeTime: 0)
                events = [event]

            default:
                fallbackHaptic(haptic: haptic)
                return
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            fallbackHaptic(haptic: haptic)
        }
    }

    private func fallbackHaptic(haptic: String) {
        switch haptic {
        case "success":
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case "warning":
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        case "error":
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        case "impactHeavy":
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        case "impactMedium":
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case "impactLight":
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case "selection":
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        default:
            AudioServicesPlaySystemSound(1519) // Peek
        }
    }
}
