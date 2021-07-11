import UIKit
import Flutter
import GoogleCast

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate,GCKLoggerDelegate {
    let kReceiverAppID = kGCKDefaultMediaReceiverApplicationID
    let kDebugLoggingEnabled = true
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    /**
     Google cast shared classes which need to be initalized on app start.
     */
    let criteria = GCKDiscoveryCriteria(applicationID: kReceiverAppID)
    let options = GCKCastOptions(discoveryCriteria: criteria)
    GCKCastContext.setSharedInstanceWith(options)
    GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = true
    GCKLogger.sharedInstance().delegate = self
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    func logMessage(_ message: String,
                     at level: GCKLoggerLevel,
                     fromFunction function: String,
                     location: String) {
       if (kDebugLoggingEnabled) {
         print(function + " - " + message)
       }
     }}
