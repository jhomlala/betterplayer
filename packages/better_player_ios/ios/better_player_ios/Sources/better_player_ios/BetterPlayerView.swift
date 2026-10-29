// Better Player Swift implementation

import AVFoundation
import AVKit
import UIKit

/// A custom UIView that hosts an AVPlayerLayer for video playback.
public class BetterPlayerView: UIView {
    private var routePickerView: AVRoutePickerView?

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

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupRoutePicker()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupRoutePicker()
    }

    private func setupRoutePicker() {
        let picker = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        picker.alpha = 0.01
        picker.isHidden = false
        addSubview(picker)
        self.routePickerView = picker
    }

    private func findButton(in view: UIView) -> UIButton? {
        if let button = view as? UIButton { return button }
        for subview in view.subviews {
            if let button = findButton(in: subview) { return button }
        }
        return nil
    }

    public func showRoutePicker() {
        if let picker = routePickerView, let button = findButton(in: picker) {
            button.sendActions(for: .touchUpInside)
        }
    }
}
