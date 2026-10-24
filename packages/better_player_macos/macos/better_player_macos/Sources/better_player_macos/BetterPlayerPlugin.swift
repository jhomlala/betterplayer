import AVFoundation
import AVKit
import FlutterMacOS
import Foundation

@_silgen_name("better_player_macos_force_load_symbols")
func better_player_macos_force_load_symbols()

@objc(BetterPlayerPlugin)
public class BetterPlayerPlugin: NSObject, FlutterPlugin, FlutterPlatformViewFactory {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        better_player_macos_force_load_symbols()
        BetterPlayerApi.cleanUp()
        let instance = BetterPlayerPlugin()
        registrar.register(instance, withId: "better_player_view")

        let channel = FlutterMethodChannel(name: "better_player_macos", binaryMessenger: registrar.messenger)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setScreenCaptureProtection":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "enabled boolean expected", details: nil))
                return
            }
            DispatchQueue.main.async {
                for window in NSApplication.shared.windows {
                    window.sharingType = enabled ? .none : .readWrite
                }
                result(nil)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        guard let dict = args as? [String: Any],
              let textureId = (dict["textureId"] as? NSNumber)?.int64Value,
              let player = BetterPlayerApi.players[textureId] else {
            return NSView(frame: .zero)
        }
        return player.view()
    }
}
