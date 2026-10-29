import AVFoundation
import AVKit
import FlutterMacOS
import Foundation

@_silgen_name("better_player_macos_force_load_symbols")
func better_player_macos_force_load_symbols()

@objc(BetterPlayerPlugin)
public class BetterPlayerPlugin: NSObject, FlutterPlugin, FlutterPlatformViewFactory {
    private static var methodChannel: FlutterMethodChannel?
    private static var externalPlaybackEventChannel: FlutterEventChannel?
    private static let externalPlaybackStreamHandler = ExternalPlaybackStreamHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        better_player_macos_force_load_symbols()
        BetterPlayerApi.cleanUp()
        let instance = BetterPlayerPlugin()
        registrar.register(instance, withId: "better_player_view")

        let channel = FlutterMethodChannel(name: "better_player_macos", binaryMessenger: registrar.messenger)
        methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        let extChannel = FlutterEventChannel(name: "better_player_macos/external_playback_stream", binaryMessenger: registrar.messenger)
        externalPlaybackEventChannel = extChannel
        extChannel.setStreamHandler(externalPlaybackStreamHandler)
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
        case "showExternalPlaybackPicker":
            let textureId = ((call.arguments as? [String: Any])?["textureId"] as? NSNumber)?.int64Value
            let player = textureId != nil ? BetterPlayerApi.players[textureId!] : nil
            BetterPlayerPlugin.showRoutePicker(for: player)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public static func notifyExternalPlaybackChanged(_ isActive: Bool) {
        externalPlaybackStreamHandler.notify(isActive: isActive)
    }

    public static func isAnyExternalPlaybackActive() -> Bool {
        for (_, player) in BetterPlayerApi.players {
            if player.player.isExternalPlaybackActive {
                return true
            }
        }
        return false
    }

        private static func findButton(in view: NSView) -> NSButton? {
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }

    public static func showRoutePicker(for player: BetterPlayer?) {
        DispatchQueue.main.async {
            if let bpView = player?.playerView as? BetterPlayerView, bpView.window != nil {
                bpView.showRoutePicker()
                return
            }

            guard #available(macOS 10.15, *),
                  let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first,
                  let contentView = window.contentView else {
                return
            }
            let picker = AVRoutePickerView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
            picker.alphaValue = 0.01
            contentView.addSubview(picker)
            if let button = findButton(in: picker) {
                button.performClick(nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                picker.removeFromSuperview()
            }
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

class ExternalPlaybackStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        events(BetterPlayerPlugin.isAnyExternalPlaybackActive())
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func notify(isActive: Bool) {
        eventSink?(isActive)
    }
}
