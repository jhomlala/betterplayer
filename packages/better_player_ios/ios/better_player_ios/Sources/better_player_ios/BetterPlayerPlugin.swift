import AVFoundation
import AVKit
import Flutter
import Foundation
import MediaPlayer
import UIKit

@_silgen_name("better_player_ios_force_load_symbols")
func better_player_ios_force_load_symbols()

@objc(BetterPlayerPlugin)
public class BetterPlayerPlugin: NSObject, FlutterPlugin, FlutterPlatformViewFactory {
    private static var methodChannel: FlutterMethodChannel?
    private static var screenCaptureEventChannel: FlutterEventChannel?
    private static let screenCaptureStreamHandler = ScreenCaptureStreamHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        better_player_ios_force_load_symbols()
        BetterPlayerApi.cleanUp()
        let instance = BetterPlayerPlugin()
        registrar.register(instance, withId: "better_player_view")

        let channel = FlutterMethodChannel(name: "better_player_ios", binaryMessenger: registrar.messenger())
        methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "better_player_ios/screen_capture_stream", binaryMessenger: registrar.messenger())
        screenCaptureEventChannel = eventChannel
        eventChannel.setStreamHandler(screenCaptureStreamHandler)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setScreenCaptureProtection":
            result(nil)
        case "isScreenCaptured":
            result(UIScreen.main.isCaptured)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        guard let dict = args as? [String: Any],
              let textureId = (dict["textureId"] as? NSNumber)?.int64Value,
              let player = BetterPlayerApi.players[textureId] else {
            return BetterPlayerPlatformView(frame: frame, player: nil)
        }
        return BetterPlayerPlatformView(frame: frame, player: player)
    }
}

public final class BetterPlayerPlatformView: NSObject, FlutterPlatformView {
    private let playerView: BetterPlayerView

    public init(frame: CGRect, player: BetterPlayer?) {
        let view = BetterPlayerView(frame: frame)
        self.playerView = view
        super.init()
        player?.attachPlayerView(view)
    }

    public func view() -> UIView {
        return playerView
    }
}

class ScreenCaptureStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        events(UIScreen.main.isCaptured)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenCaptureChanged),
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(
            self,
            name: UIScreen.capturedDidChangeNotification,
            object: nil
        )
        self.eventSink = nil
        return nil
    }

    @objc private func screenCaptureChanged() {
        eventSink?(UIScreen.main.isCaptured)
    }
}
