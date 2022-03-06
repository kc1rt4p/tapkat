import UIKit
import Firebase
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    GMSServices.provideAPIKey("AIzaSyAH4fWM5IbEO0X-Txkm6HNsFAQ3KOfW20I")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
