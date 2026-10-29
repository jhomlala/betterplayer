import AVFoundation
import AVKit
import AppKit

/// A custom NSView that hosts an AVPlayerLayer for macOS video playback.
@objc(BetterPlayerView)
public class BetterPlayerView: NSView {
    private var routePickerView: AVRoutePickerView?

    public override func makeBackingLayer() -> CALayer {
        return AVPlayerLayer()
    }

    /// The AVPlayerLayer used for video rendering.
    public var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    /// The player to be displayed in the view.
    public var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        setupRoutePicker()
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        setupRoutePicker()
    }

    private func setupRoutePicker() {
        if #available(macOS 10.15, *) {
            let picker = AVRoutePickerView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
            picker.alphaValue = 0.01
            picker.isHidden = false
            addSubview(picker)
            self.routePickerView = picker
        }
    }

    private func findButton(in view: NSView) -> NSButton? {
        if let button = view as? NSButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }

    public func showRoutePicker() {
        if #available(macOS 10.15, *), let picker = routePickerView, let button = findButton(in: picker) {
            button.performClick(nil)
        }
    }

    public override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
