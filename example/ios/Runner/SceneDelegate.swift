import Flutter
import UIKit
import flutter_activity_kit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    for context in connectionOptions.urlContexts {
      _ = handleActivityURL(context.url)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      _ = handleActivityURL(context.url)
    }

    let remainingContexts = Set(URLContexts.filter {
      $0.url.scheme != "flutteractivitykit"
    })
    if !remainingContexts.isEmpty {
      super.scene(scene, openURLContexts: remainingContexts)
    }
  }

  private func handleActivityURL(_ url: URL) -> Bool {
    guard url.scheme == "flutteractivitykit" else { return false }
    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let actionId = url.host == "action"
      ? url.path.split(separator: "/").first.map(String.init)
      : url.host
    let activityId = components?.queryItems?
      .first(where: { $0.name == "activityId" })?.value ?? ""
    guard let actionId = actionId, !actionId.isEmpty else { return false }
    FlutterActivityKitPlugin.sendActionEvent(
      activityId: activityId,
      actionId: actionId
    )
    return true
  }
}
