// Better Player Swift implementation

import AVFoundation
import AVKit
#if canImport(Flutter)
import Flutter
#else
public protocol FlutterPlatformView {}
public class FlutterError: NSObject {
    @objc public var code: String
    @objc public var message: String?
    @objc public var details: Any?
    @objc public init(code: String, message: String?, details: Any?) {
        self.code = code
        self.message = message
        self.details = details
        super.init()
    }
}
public typealias FlutterResult = (Any?) -> Void

@objc public class BetterPlayerEzDrmAssetsLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    public init(_ certificateURL: URL, withLicenseURL licenseURL: URL?) { super.init() }
}
@objc public class CacheManager: NSObject {
    public func getCachingPlayerItemForNormalPlayback(_ url: URL, cacheKey: String?, videoExtension: String?, headers: [NSObject: AnyObject]) -> AVPlayerItem? { return nil }
}
public class BetterPlayerView: UIView {
    public var player: AVPlayer?
}
public class BetterPlayerTimeUtils {
    public static func cmTimeToMillis(_ time: CMTime) -> Int64 { return 0 }
    public static func timeIntervalToMillis(_ interval: TimeInterval) -> Int64 { return 0 }
}
#endif
import Foundation
import UIKit

private var timeRangeContext = 0
private var statusContext = 0
private var playbackLikelyToKeepUpContext = 0
private var playbackBufferEmptyContext = 0
private var playbackBufferFullContext = 0
private var presentationSizeContext = 0

/// A platform view implementation that wraps AVPlayer for video playback.
/// Handles player initialization, lifecycle, and event reporting to Flutter.
@objc public class BetterPlayer: NSObject, FlutterPlatformView, AVPictureInPictureControllerDelegate {

    private func sendError(_ error: FlutterError) {
        callback?.onError(error.code, errorMessage: error.message ?? "", errorDetails: (error.details as? String) ?? "")
    }


    // MARK: - Properties

    /// The underlying AVPlayer instance.
    public private(set) var player: AVPlayer

    /// The delegate for handling DRM asset loading.
    public private(set) var loaderDelegate: BetterPlayerEzDrmAssetsLoaderDelegate?

    /// The Flutter event channel for sending player events.
    

    /// The sink for emitting events to Flutter.
    @objc public var callback: BetterPlayerCallback?

    /// The preferred transform for the video.
    public var preferredTransform: CGAffineTransform = .identity

    /// Whether the player has been disposed.
    public private(set) var disposed: Bool = false

    /// Whether the player is currently playing.
    public private(set) var isPlaying: Bool = false

    /// Whether the player should loop playback.
    public var isLooping: Bool = false

    /// Whether the player has been initialized.
    public private(set) var isInitialized: Bool = false

    /// The unique key identifying the current data source.
    public private(set) var key: String? = nil

    /// The number of times playback failed.
    public private(set) var failedCount: Int = 0

    private var videoGravity: AVLayerVideoGravity = .resizeAspect
    private weak var playerView: UIView?

    /// Reference to the AVPlayerLayer used for Picture-in-Picture.
    public var playerLayerRef: AVPlayerLayer?

    /// Whether Picture-in-Picture is active.
    public var pictureInPicture: Bool = false

    /// Whether KVO observers have been added.
    public var observersAdded: Bool = false

    /// The number of times playback stalled.
    public var stalledCount: Int = 0

    /// Whether the stalled check is currently running.
    public var isStalledCheckStarted: Bool = false

    /// The current playback rate.
    public var playerRate: Float = 1.0

    /// The overridden duration of the video in milliseconds.
    public var overriddenDuration: Int = 0

    /// The last recorded time control status of the AVPlayer.
    public var lastAvPlayerTimeControlStatus: AVPlayer.TimeControlStatus? = nil

    private var pipController: AVPictureInPictureController?
    private var restoreUIOnPipStop: ((Bool) -> Void)?

    // MARK: - Lifecycle

    public override init() {
        self.player = AVPlayer()
        super.init()
        self.player.actionAtItemEnd = .none
        if #available(iOS 10.0, *) {
            self.player.automaticallyWaitsToMinimizeStalling = false
        }
        self.observersAdded = false
        self.isInitialized = false
        self.isPlaying = false
        self.disposed = false
    }

    public convenience init(frame: CGRect) {
        self.init()
    }

    /// Returns the view to be displayed in Flutter.
    @objc public func view() -> UIView {
        let playerView = BetterPlayerView(frame: .zero)
        playerView.player = player
        if let playerLayer = playerView.layer as? AVPlayerLayer {
            playerLayer.videoGravity = self.videoGravity
        }

        self.playerView = playerView
        return playerView
    }

    // MARK: - Aspect Ratio Handling

    /// Sets the video aspect ratio gravity.
    /// - Parameter gravity: The gravity to apply.
    @objc public func setAspectRatio(_ gravity: AVLayerVideoGravity) {
        self.videoGravity = gravity

        if let playerLayer = playerView?.layer as? AVPlayerLayer {
            playerLayer.videoGravity = gravity
        }

        if let pipLayer = playerLayerRef {
            pipLayer.videoGravity = gravity
        }
    }

    // MARK: - Observers

    private func addObservers(_ item: AVPlayerItem) {
        if !observersAdded {
            player.addObserver(self, forKeyPath: "rate", options: [], context: nil)
            item.addObserver(self, forKeyPath: "loadedTimeRanges", options: [], context: &timeRangeContext)
            item.addObserver(self, forKeyPath: "status", options: [], context: &statusContext)
            item.addObserver(self, forKeyPath: "presentationSize", options: [], context: &presentationSizeContext)
            item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [], context: &playbackLikelyToKeepUpContext)
            item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [], context: &playbackBufferEmptyContext)
            item.addObserver(self, forKeyPath: "playbackBufferFull", options: [], context: &playbackBufferFullContext)
            NotificationCenter.default.addObserver(self, selector: #selector(itemDidPlayToEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: item)
            observersAdded = true
        }
    }

    private func removeObservers() {
        if observersAdded {
            player.removeObserver(self, forKeyPath: "rate", context: nil)
            player.currentItem?.removeObserver(self, forKeyPath: "status", context: &statusContext)
            player.currentItem?.removeObserver(self, forKeyPath: "presentationSize", context: &presentationSizeContext)
            player.currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges", context: &timeRangeContext)
            player.currentItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp", context: &playbackLikelyToKeepUpContext)
            player.currentItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty", context: &playbackBufferEmptyContext)
            player.currentItem?.removeObserver(self, forKeyPath: "playbackBufferFull", context: &playbackBufferFullContext)
            NotificationCenter.default.removeObserver(self)
            observersAdded = false
        }
    }

    @objc private func itemDidPlayToEndTime(_ notification: Notification) {
        if isLooping {
            if let p = notification.object as? AVPlayerItem {
                p.seek(to: .zero, completionHandler: nil)
            }
        } else {
            if callback != nil {
                callback?.onCompleted(key: key)
                removeObservers()
            }
        }
    }

    // MARK: - Video Transformation

    private func radiansToDegrees(_ radians: CGFloat) -> CGFloat {
        var degrees = CGFloat(radians * 180.0 / .pi)
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    private func getVideoComposition(transform: CGAffineTransform, asset: AVAsset, videoTrack: AVAssetTrack) -> AVMutableVideoComposition {
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: asset.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(preferredTransform, at: .zero)

        let videoComposition = AVMutableVideoComposition()
        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        var width = videoTrack.naturalSize.width
        var height = videoTrack.naturalSize.height
        let rotationDegrees = Int(round(radiansToDegrees(atan2(preferredTransform.b, preferredTransform.a))))
        if rotationDegrees == 90 || rotationDegrees == 270 {
            width = videoTrack.naturalSize.height
            height = videoTrack.naturalSize.width
        }
        videoComposition.renderSize = CGSize(width: width, height: height)

        let nominalFrameRate = videoTrack.nominalFrameRate
        var fps: Int32 = 30
        if nominalFrameRate > 0 { fps = Int32(ceil(nominalFrameRate)) }
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: fps)
        return videoComposition
    }

    private func fixTransform(_ videoTrack: AVAssetTrack) -> CGAffineTransform {
        var transform = videoTrack.preferredTransform
        let rotationDegrees = Int(round(radiansToDegrees(atan2(transform.b, transform.a))))
        if rotationDegrees == 90 {
            transform.tx = videoTrack.naturalSize.height
            transform.ty = 0
        } else if rotationDegrees == 180 {
            transform.tx = videoTrack.naturalSize.width
            transform.ty = videoTrack.naturalSize.height
        } else if rotationDegrees == 270 {
            transform.tx = 0
            transform.ty = videoTrack.naturalSize.width
        }
        return transform
    }

    // MARK: - Data Source Handling

    /// Sets the data source from an asset path.
    @objc public func setDataSourceAsset(_ assetPath: String, key: String?, certificateUrl: String?, licenseUrl: String?, cacheKey: String?, cacheManager: CacheManager, overriddenDuration: Int) {
        if let path = Bundle.main.path(forResource: assetPath, ofType: nil) {
            let url = URL(fileURLWithPath: path)
            setDataSourceURL(url, key: key, certificateUrl: certificateUrl, licenseUrl: licenseUrl, headers: [:], useCache: false, cacheKey: cacheKey, cacheManager: cacheManager, overriddenDuration: overriddenDuration, videoExtension: nil)
        }
    }

    /// Sets the data source from a URL.
    @objc public func setDataSourceURL(_ url: URL, key: String?, certificateUrl: String?, licenseUrl: String?, headers: [AnyHashable: Any], useCache: Bool, cacheKey: String?, cacheManager: CacheManager, overriddenDuration: Int, videoExtension: String?) {
        self.overriddenDuration = 0

        let item: AVPlayerItem
        if useCache {
            let cacheKeyInternal = cacheKey
            let videoExtInternal = videoExtension
            item = cacheManager.getCachingPlayerItemForNormalPlayback(url, cacheKey: cacheKeyInternal, videoExtension: videoExtInternal, headers: headers as [NSObject: AnyObject]) ?? AVPlayerItem(url: url)
        } else {
            let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            if let certificateUrl = certificateUrl, !certificateUrl.isEmpty {
                let certURL = URL(string: certificateUrl)
                let licURL = licenseUrl.flatMap { URL(string: $0) }
                if let certURL = certURL {
                    let delegate = BetterPlayerEzDrmAssetsLoaderDelegate(certURL, withLicenseURL: licURL)
                    self.loaderDelegate = delegate
                    let qos = DispatchQoS.QoSClass.default
                    let streamQueue = DispatchQueue(label: "streamQueue", qos: DispatchQoS(qosClass: qos, relativePriority: -1), attributes: [])
                    asset.resourceLoader.setDelegate(delegate, queue: streamQueue)
                }
            }
            item = AVPlayerItem(asset: asset)
        }
        if #available(iOS 10.0, *), overriddenDuration > 0 {
            self.overriddenDuration = overriddenDuration
        }
        setDataSourcePlayerItem(item, key: key)
    }

    private func setDataSourcePlayerItem(_ item: AVPlayerItem, key: String?) {
        self.key = key
        self.stalledCount = 0
        self.isStalledCheckStarted = false
        self.playerRate = 1
        player.replaceCurrentItem(with: item)

        let asset = item.asset
        asset.loadValuesAsynchronously(forKeys: ["tracks"]) {
            if asset.statusOfValue(forKey: "tracks", error: nil) == .loaded {
                let tracks = asset.tracks(withMediaType: .video)
                if let videoTrack = tracks.first {
                    videoTrack.loadValuesAsynchronously(forKeys: ["preferredTransform"]) { [weak self] in
                        guard let self = self, !self.disposed else { return }
                        if videoTrack.statusOfValue(forKey: "preferredTransform", error: nil) == .loaded {
                            self.preferredTransform = self.fixTransform(videoTrack)
                            let videoComposition = self.getVideoComposition(transform: self.preferredTransform, asset: asset, videoTrack: videoTrack)
                            item.videoComposition = videoComposition
                        }
                    }
                }
            }
        }
        addObservers(item)
    }

    // MARK: - Stalling Handling

    private func handleStalled() {
        if isStalledCheckStarted { return }
        isStalledCheckStarted = true
        startStalledCheck()
    }

    private func startStalledCheck() {
        if let currentItem = player.currentItem {
            if currentItem.isPlaybackLikelyToKeepUp || (availableDuration() - CMTimeGetSeconds(currentItem.currentTime())) > 10.0 {
                play()
            } else {
                stalledCount += 1
                if stalledCount > 60 {
                    if callback != nil {
                        let error = FlutterError(code: "VideoError", message: "Failed to load video: playback stalled", details: nil)
                        sendError(error)
                    }
                    return
                }
                perform(#selector(startStalledCheckObjC), with: nil, afterDelay: 1)
            }
        }
    }

    @objc private func startStalledCheckObjC() { startStalledCheck() }

    private func availableDuration() -> TimeInterval {
        guard let timeRange = player.currentItem?.loadedTimeRanges.first?.timeRangeValue else { return 0 }
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        return startSeconds + durationSeconds
    }

    // MARK: - KVO observeValue

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            if #available(iOS 10.0, *), let pipController = pipController, pipController.isPictureInPictureActive {
                if let last = lastAvPlayerTimeControlStatus, last == player.timeControlStatus {
                    return
                }
                if player.timeControlStatus == .paused {
                    lastAvPlayerTimeControlStatus = player.timeControlStatus
                    callback?.onPause(key: key)
                    return
                }
                if player.timeControlStatus == .playing {
                    lastAvPlayerTimeControlStatus = player.timeControlStatus
                    callback?.onPlay(key: key)
                }
            }

            if isPlaying && playerRate > 0 && player.rate > 0 && abs(player.rate - playerRate) > 0.0001 {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, self.isPlaying, self.player.rate > 0,
                          abs(self.player.rate - self.playerRate) > 0.0001 else { return }
                    self.applyPlayerRate()
                }
            }

            if player.rate == 0 && CMTimeCompare(player.currentItem?.currentTime() ?? .zero, .zero) == 1 && (player.currentItem?.duration ?? .zero).isValid && CMTimeCompare(player.currentItem?.currentTime() ?? .zero, player.currentItem?.duration ?? .zero) == -1 && isPlaying {
                handleStalled()
            }
        }

        if context == &timeRangeContext {
            if callback != nil, let item = object as? AVPlayerItem {
                var values: [[NSNumber]] = []
                for rangeValue in item.loadedTimeRanges {
                    let range = rangeValue.timeRangeValue
                    let start = NSNumber(value: BetterPlayerTimeUtils.cmTimeToMillis(range.start))
                    var end = NSNumber(value: BetterPlayerTimeUtils.cmTimeToMillis(range.start) + BetterPlayerTimeUtils.cmTimeToMillis(range.duration))
                    if let endTime = player.currentItem?.forwardPlaybackEndTime, !CMTIME_IS_INVALID(endTime) {
                        let endTimeMs = BetterPlayerTimeUtils.cmTimeToMillis(endTime)
                        if end.int64Value > endTimeMs { end = NSNumber(value: endTimeMs) }
                    }
                    values.append([start, end])
                }
                if let jsonData = try? JSONSerialization.data(withJSONObject: values, options: []),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    callback?.onBufferingUpdate(jsonRanges: jsonString, key: key)
                }
            }
        } else if context == &presentationSizeContext {
            onReadyToPlay()
        } else if context == &statusContext {
            if let item = object as? AVPlayerItem {
                switch item.status {
                case .failed:
                    NSLog("Failed to load video: \(String(describing: item.error?.localizedDescription))")
                    if callback != nil {
                        let message = "Failed to load video: \(item.error?.localizedDescription ?? "unknown")"
                        let error = FlutterError(code: "VideoError", message: message, details: nil)
                        sendError(error)
                    }
                case .unknown:
                    break
                case .readyToPlay:
                    onReadyToPlay()
                @unknown default:
                    break
                }
            }
        } else if context == &playbackLikelyToKeepUpContext {
            if player.currentItem?.isPlaybackLikelyToKeepUp == true {
                updatePlayingState()
                callback?.onBufferingEnd(key: key)
            }
        } else if context == &playbackBufferEmptyContext {
            callback?.onBufferingStart(key: key)
        } else if context == &playbackBufferFullContext {
            callback?.onBufferingEnd(key: key)
        }
    }

    // MARK: - Playback Control

    /// Updates the player state to match current playing status.
    public func updatePlayingState() {
        guard isInitialized, key != nil else { return }
        if !observersAdded, let current = player.currentItem { addObservers(current) }
        if isPlaying {
            applyPlayerRate()
        } else {
            player.pause()
        }
    }

    private func applyPlayerRate() {
        if #available(iOS 16, *) {
            player.defaultRate = playerRate
        }
        if #available(iOS 10.0, *) {
            player.playImmediately(atRate: playerRate)
        } else {
            player.play()
            player.rate = playerRate
        }
    }

    /// Handles transition to ready-to-play state.
    public func onReadyToPlay() {
        guard callback != nil, !isInitialized, key != nil else { return }
        guard player.currentItem != nil else { return }
        guard player.status == .readyToPlay else { return }

        let size = player.currentItem?.presentationSize ?? .zero
        var width = size.width
        var height = size.height

        let asset = player.currentItem!.asset
        let onlyAudio = asset.tracks(withMediaType: .video).count == 0
        if !onlyAudio && height == .zero && width == .zero {
            return
        }
        let isLive = CMTIME_IS_INDEFINITE(player.currentItem!.duration)
        if !isLive && duration() == 0 { return }

        if let track = player.currentItem?.tracks.first?.assetTrack {
            let naturalSize = track.naturalSize
            let prefTrans = track.preferredTransform
            let realSize = naturalSize.applying(prefTrans)
            width = abs(realSize.width) != 0 ? abs(realSize.width) : width
            height = abs(realSize.height) != 0 ? abs(realSize.height) : height
        }

        let durMs = BetterPlayerTimeUtils.cmTimeToMillis(player.currentItem!.asset.duration)
        if overriddenDuration > 0 && durMs > Int64(overriddenDuration) {
            player.currentItem?.forwardPlaybackEndTime = CMTimeMake(value: Int64(overriddenDuration/1000), timescale: 1)
        }

        isInitialized = true
        updatePlayingState()
        callback?.onInitialized(
            durationMs: Int64(duration()),
            width: Double(width),
            height: Double(height),
            key: key
        )
    }

    /// Starts playback.
    @objc public func play() {
        stalledCount = 0
        isStalledCheckStarted = false
        isPlaying = true
        updatePlayingState()
    }

    /// Pauses playback.
    @objc public func pause() {
        isPlaying = false
        updatePlayingState()
    }

    /// Returns the current playback position in milliseconds.
    @objc public func position() -> Int64 {
        return BetterPlayerTimeUtils.cmTimeToMillis(player.currentTime())
    }

    /// Returns the absolute position in milliseconds for live streams.
    @objc public func absolutePosition() -> Int64 {
        let interval = player.currentItem?.currentDate()?.timeIntervalSince1970 ?? 0
        return BetterPlayerTimeUtils.timeIntervalToMillis(interval)
    }

    /// Returns the total duration of the media in milliseconds.
    @objc public func duration() -> Int64 {
        let time: CMTime
        if #available(iOS 13, *) {
            time = player.currentItem?.duration ?? .zero
        } else {
            time = player.currentItem?.asset.duration ?? .zero
        }
        if let endTime = player.currentItem?.forwardPlaybackEndTime, !CMTIME_IS_INVALID(endTime) {
            return BetterPlayerTimeUtils.cmTimeToMillis(endTime)
        }
        return BetterPlayerTimeUtils.cmTimeToMillis(time)
    }

    /// Seeks to the specified position in milliseconds.
    /// - Parameter location: The position to seek to.
    @objc public func seekTo(_ location: Int) {
        let wasPlaying = isPlaying
        if wasPlaying { player.pause() }
        player.seek(to: CMTimeMake(value: Int64(location), timescale: 1000), toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let self = self else { return }
            if wasPlaying { self.applyPlayerRate() }
        }
    }

    /// Sets the player volume.
    /// - Parameter volume: The volume level (0.0 to 1.0).
    @objc public func setVolume(_ volume: Double) {
        let v = max(0.0, min(1.0, volume))
        player.volume = Float(v)
    }

    /// Sets the playback speed.
    /// - Parameters:
    ///   - speed: The playback speed.
    @objc public func setSpeed(_ speed: Double) {
        guard speed >= 0, speed <= 2.0 else { return }
        playerRate = Float(speed == 0.0 ? 1.0 : speed)
        if isPlaying {
            applyPlayerRate()
        }
    }

    @objc public func setLooping(_ looping: Bool) {
        isLooping = looping
    }

    @objc public func setDataSourceURLString(_ urlString: String, key: String?, certificateUrl: String?, licenseUrl: String?, useCache: Bool, cacheKey: String?, cacheManager: CacheManager, overriddenDuration: Int, videoExtension: String?) {
        guard let url = URL(string: urlString) else { return }
        setDataSourceURL(url, key: key, certificateUrl: certificateUrl, licenseUrl: licenseUrl, headers: [:], useCache: useCache, cacheKey: cacheKey, cacheManager: cacheManager, overriddenDuration: overriddenDuration, videoExtension: videoExtension)
    }

    // MARK: - Track Parameters

    /// Sets track parameters like bitrate and resolution.
    @objc public func setTrackParameters(width: Int, height: Int, bitrate: Int) {
        player.currentItem?.preferredPeakBitRate = Double(bitrate)
        if #available(iOS 11.0, *) {
            if width == 0 && height == 0 {
                player.currentItem?.preferredMaximumResolution = .zero
            } else {
                player.currentItem?.preferredMaximumResolution = CGSize(width: width, height: height)
            }
        }
    }

    // MARK: - Picture-in-Picture

    /// Sets Picture-in-Picture state.
    /// - Parameter pictureInPicture: Whether PiP should be active.
    @objc public func setPictureInPicture(_ pictureInPicture: Bool) {
        self.pictureInPicture = pictureInPicture
        if #available(iOS 9.0, *) {
            if let pip = pipController, self.pictureInPicture && !pip.isPictureInPictureActive {
                DispatchQueue.main.async { pip.startPictureInPicture() }
            } else if let pip = pipController, !self.pictureInPicture && pip.isPictureInPictureActive {
                DispatchQueue.main.async { pip.stopPictureInPicture() }
            }
        }
    }

    /// Sets the completion handler for restoring UI after PiP stops.
    @objc public func setRestoreUserInterfaceForPIPStopCompletionHandler(_ restore: Bool) {
        restoreUIOnPipStop?(restore)
        restoreUIOnPipStop = nil
    }

    private func setupPipController() {
        if #available(iOS 9.0, *) {
            try? AVAudioSession.sharedInstance().setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            if pipController == nil, let layer = playerLayerRef, AVPictureInPictureController.isPictureInPictureSupported() {
                pipController = AVPictureInPictureController(playerLayer: layer)
                pipController?.delegate = self
            }
        }
    }

    /// Enables Picture-in-Picture for the given frame.
    /// - Parameter frame: The frame for PiP.
    @objc public func enablePictureInPicture(_ frame: CGRect) {
        disablePictureInPicture()
        usePlayerLayer(frame)
    }

    private func usePlayerLayer(_ frame: CGRect) {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = self.videoGravity
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                layer.frame = frame
                layer.needsDisplayOnBoundsChange = true
                rootVC.view.layer.addSublayer(layer)
                rootVC.view.layer.needsDisplayOnBoundsChange = true
                playerLayerRef = layer
                pipController = nil
                setupPipController()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.setPictureInPicture(true)
                }
            }
        } else {
            if let window = UIApplication.shared.keyWindow ?? UIApplication.shared.windows.first,
               let rootVC = window.rootViewController {
                layer.frame = frame
                layer.needsDisplayOnBoundsChange = true
                rootVC.view.layer.addSublayer(layer)
                rootVC.view.layer.needsDisplayOnBoundsChange = true
                playerLayerRef = layer
                pipController = nil
                setupPipController()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.setPictureInPicture(true)
                }
            }
        }
    }

    /// Disables Picture-in-Picture.
    @objc public func disablePictureInPicture() {
        setPictureInPicture(true)
        if let layer = playerLayerRef {
            layer.removeFromSuperlayer()
            playerLayerRef = nil
            callback?.onPipStop()
        }
    }

    // MARK: - AVPictureInPictureControllerDelegate

    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        disablePictureInPicture()
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        callback?.onPipStart()
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        restoreUIOnPipStop = completionHandler
        setRestoreUserInterfaceForPIPStopCompletionHandler(true)
    }

    // MARK: - Audio & Tracks

    /// Sets the audio track by name and index.
    /// - Parameters:
    ///   - name: The name of the track.
    ///   - index: The index of the track.
    @objc public func setAudioTrack(name: String, index: Int) {
        guard let group = player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else { return }
        let options = group.options
        for audioTrackIndex in 0..<options.count {
            let option = options[audioTrackIndex]
            let metas = AVMetadataItem.metadataItems(from: option.commonMetadata, withKey: "title" as (NSCopying & NSObjectProtocol), keySpace: AVMetadataKeySpace(rawValue: "comn"))
            if let title = metas.first?.stringValue, title == name && audioTrackIndex == index {
                player.currentItem?.select(option, in: group)
            }
        }
    }

    /// Sets whether the audio should mix with others.
    /// - Parameter mixWithOthers: Whether to mix audio.
    @objc public func setMixWithOthers(_ mixWithOthers: Bool) {
        if mixWithOthers {
            try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
        }
    }

    // MARK: - FlutterStreamHandler

    

    

    // MARK: - Disposal

    /// Clears the player state.
    @objc public func clear() {
        isInitialized = false
        isPlaying = false
        disposed = false
        failedCount = 0
        key = nil
        guard player.currentItem != nil else { return }
        removeObservers()
        player.currentItem?.asset.cancelLoading()
    }

    /// Disposes the player without affecting the event channel.
    @objc public func disposeSansEventChannel() {
        do {
            clear()
        }
    }

    /// Disposes the player and cleans up resources.
    @objc public func dispose() {
        pause()
        disposeSansEventChannel()
        disablePictureInPicture()
        setPictureInPicture(false)
        disposed = true
    }
}
