import AVFoundation
import AVKit
import AppKit

/// A custom NSView that hosts an AVPlayerLayer for macOS video playback.
@objc(BetterPlayerView)
public class BetterPlayerView: NSView {

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
    }

    public convenience init() {
        self.init(frame: .zero)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }

    public override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
}
