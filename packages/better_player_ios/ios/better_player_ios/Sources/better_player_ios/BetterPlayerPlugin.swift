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
    private static var externalPlaybackEventChannel: FlutterEventChannel?
    private static let externalPlaybackStreamHandler = ExternalPlaybackStreamHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        better_player_ios_force_load_symbols()
        setScreenCaptureProtection(enabled: false)
        BetterPlayerApi.cleanUp()
        let instance = BetterPlayerPlugin()
        registrar.register(instance, withId: "better_player_view")

        let channel = FlutterMethodChannel(name: "better_player_ios", binaryMessenger: registrar.messenger())
        methodChannel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)

        let eventChannel = FlutterEventChannel(name: "better_player_ios/screen_capture_stream", binaryMessenger: registrar.messenger())
        screenCaptureEventChannel = eventChannel
        eventChannel.setStreamHandler(screenCaptureStreamHandler)

        let extChannel = FlutterEventChannel(name: "better_player_ios/external_playback_stream", binaryMessenger: registrar.messenger())
        externalPlaybackEventChannel = extChannel
        extChannel.setStreamHandler(externalPlaybackStreamHandler)
        BetterPlayerApi.onExternalPlaybackChanged = { isActive in
            externalPlaybackStreamHandler.notify(isActive: isActive)
        }
    }

    private static var secureTextField: UITextField?

    public static func setScreenCaptureProtection(enabled: Bool) {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first else {
                return
            }
            if enabled {
                guard secureTextField == nil else { return }
                let field = UITextField()
                field.isSecureTextEntry = true
                field.isUserInteractionEnabled = false
                window.addSubview(field)
                field.centerYAnchor.constraint(equalTo: window.centerYAnchor).isActive = true
                field.centerXAnchor.constraint(equalTo: window.centerXAnchor).isActive = true
                window.layer.superlayer?.addSublayer(field.layer)
                field.layer.sublayers?.first?.addSublayer(window.layer)
                secureTextField = field
            } else {
                guard let field = secureTextField else { return }
                field.isSecureTextEntry = false
                if let superlayer = field.layer.superlayer {
                    superlayer.addSublayer(window.layer)
                }
                field.layer.sublayers?.first?.sublayers?.removeAll(where: { $0 === window.layer })
                field.layer.removeFromSuperlayer()
                field.removeFromSuperview()
                secureTextField = nil
            }
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setScreenCaptureProtection":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "enabled boolean expected", details: nil))
                return
            }
            BetterPlayerPlugin.setScreenCaptureProtection(enabled: enabled)
            result(nil)
        case "isScreenCaptured":
            result(UIScreen.main.isCaptured)
        case "showExternalPlaybackPicker":
            let textureId = ((call.arguments as? [String: Any])?["textureId"] as? NSNumber)?.int64Value
            let player = textureId != nil ? BetterPlayerApi.players[textureId!] : nil
            BetterPlayerPlugin.showRoutePicker(for: player)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func findButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton { return button }
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

            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) ?? UIApplication.shared.windows.first,
                  let rootView = window.rootViewController?.view else {
                return
            }
            let picker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
            picker.alpha = 0.01
            rootView.addSubview(picker)
            if let button = findButton(in: picker) {
                button.sendActions(for: .touchUpInside)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                picker.removeFromSuperview()
            }
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

class ExternalPlaybackStreamHandler: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        events(BetterPlayerApi.isAnyExternalPlaybackActive())
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
