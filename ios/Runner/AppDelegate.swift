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
    let channel = FlutterMethodChannel(
      name: "com.stormg.lumadrama/share",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "shareText",
            let arguments = call.arguments as? [String: Any],
            let text = arguments["text"] as? String,
            !text.isEmpty,
            let controller = self?.window?.rootViewController else {
        result(FlutterError(code: "share_unavailable", message: "Share sheet is unavailable", details: nil))
        return
      }
      let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
      activity.popoverPresentationController?.sourceView = controller.view
      activity.completionWithItemsHandler = { _, _, _, _ in result(nil) }
      controller.present(activity, animated: true)
    }
  }
}
