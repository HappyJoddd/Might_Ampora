import Flutter
import UIKit
import GoogleSignIn
import flutter_background_service_ios

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    SwiftFlutterBackgroundServicePlugin.taskIdentifier = "dev.flutter.background.refresh"
    GeneratedPluginRegistrant.register(with: self)
    // If you initialize Firebase on iOS, call FirebaseApp.configure() here.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle URL opens so Google Sign-In (and other auth SDKs) can process the callback
  override func application(_ app: UIApplication, open url: URL,
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
}
