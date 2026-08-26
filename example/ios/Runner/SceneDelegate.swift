import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts {
      let url = context.url
      let actionId = url.host ?? url.path.replacingOccurrences(of: "/", with: "")
      if !actionId.isEmpty {
        NotificationCenter.default.post(
          name: NSNotification.Name("FlutterActivityKitActionEvent"),
          object: nil,
          userInfo: ["activityId": "live_activity", "actionId": actionId]
        )
      }
    }
  }
}
