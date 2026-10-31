// Better Player Swift implementation

import AVFoundation
import AVKit
import UIKit

/// A custom UIView that hosts an AVPlayerLayer for video playback.
public class BetterPlayerView: UIView {

    /// Callback invoked when the view moves to or from a window.
    public var onWindowChanged: ((BetterPlayerView) -> Void)?

    /// The player to be displayed in the view.
    public var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }

    /// The AVPlayerLayer used for video rendering.
    public var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    /// Returns the class used for the view's backing layer.
    public override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChanged?(self)
    }
}
