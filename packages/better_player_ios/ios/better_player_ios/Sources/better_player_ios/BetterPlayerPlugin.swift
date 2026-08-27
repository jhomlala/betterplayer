import AVFoundation
import AVKit
import Flutter
import Foundation
import MediaPlayer
import UIKit

@objc(BetterPlayerPlugin)
public class BetterPlayerPlugin: NSObject, FlutterPlugin, FlutterPlatformViewFactory {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = BetterPlayerPlugin()
        registrar.register(instance, withId: "better_player_view")
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        guard let dict = args as? [String: Any],
              let textureId = (dict["textureId"] as? NSNumber)?.int64Value,
              let player = BetterPlayerApi.players[textureId] else {
            return BetterPlayer()
        }
        return player
    }
}
