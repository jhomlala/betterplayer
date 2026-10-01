import AVFoundation
import AVKit
import AppKit

/// A custom NSView that hosts an AVPlayerLayer for macOS video playback.
public class BetterPlayerView: NSView {

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
        self.layer = AVPlayerLayer()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layer = AVPlayerLayer()
    }
}
