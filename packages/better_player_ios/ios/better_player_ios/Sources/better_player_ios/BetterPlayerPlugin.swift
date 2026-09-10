import AVFoundation
import AVKit
import Flutter
import Foundation
import MediaPlayer
import UIKit

@objc(BetterPlayerPlugin)
public class BetterPlayerPlugin: NSObject, FlutterPlugin, FlutterPlatformViewFactory {
    
    @_silgen_name("better_player_ios_force_load_symbols")
    private static func better_player_ios_force_load_symbols()

    public static func register(with registrar: FlutterPluginRegistrar) {
        better_player_ios_force_load_symbols()
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
