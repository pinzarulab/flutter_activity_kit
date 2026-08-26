import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    let actionId = url.host ?? url.path.replacingOccurrences(of: "/", with: "")
    if !actionId.isEmpty {
      NotificationCenter.default.post(
        name: NSNotification.Name("FlutterActivityKitActionEvent"),
        object: nil,
        userInfo: ["activityId": "live_activity", "actionId": actionId]
      )
    }
    return super.application(app, open: url, options: options)
  }
}
