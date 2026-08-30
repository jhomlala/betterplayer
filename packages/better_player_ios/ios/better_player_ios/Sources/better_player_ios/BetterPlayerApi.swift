import Foundation
import AVKit

@objc(BetterPlayerCallback) public protocol BetterPlayerCallback {
    @objc(onInitializedWithDurationMs:width:height:key:)
    func onInitialized(durationMs: Int64, width: Double, height: Double, key: String?)
    @objc(onCompletedWithKey:)
    func onCompleted(key: String?)
    @objc(onPlayWithKey:)
    func onPlay(key: String?)
    @objc(onPauseWithKey:)
    func onPause(key: String?)
    @objc(onSeekWithPositionMs:key:)
    func onSeek(positionMs: Int64, key: String?)
    @objc(onBufferingStartWithKey:)
    func onBufferingStart(key: String?)
    @objc(onBufferingEndWithKey:)
    func onBufferingEnd(key: String?)
    @objc(onBufferingUpdateWithJsonRanges:key:)
    func onBufferingUpdate(jsonRanges: String, key: String?)
    @objc(onPipStart)
    func onPipStart()
    @objc(onPipStop)
    func onPipStop()
    @objc(onError:errorMessage:errorDetails:)
    func onError(_ errorCode: String, errorMessage: String, errorDetails: String)
}

@objc public class BetterPlayerApi: NSObject {
    @objc public static var players: [Int64: BetterPlayer] = [:]
    @objc public static var nextId: Int64 = 0
    @objc public static var logLevel: Int = 1 // 0=debug, 1=info, 2=warn, 3=error, 4=none

    @objc public static func setupLogger(level: Int) {
        logLevel = level
    }

    public static func log(_ level: Int, _ tag: String, _ msg: String) {
        guard logLevel < 4 && level >= logLevel else { return }
        let prefix = ["D", "I", "W", "E"][level]
        print("[\(prefix)] [BetterPlayer/\(tag)] \(msg)")
    }

    @objc public static func createPlayer(callback: BetterPlayerCallback) -> Int64 {
        // Prevent dead code elimination of the dummy class and protocol metadata
        let dummy = _DummyBetterPlayerCallbackImpl()
        let _ = dummy as BetterPlayerCallback
        
        let player = BetterPlayer()
        player.callback = callback
        nextId += 1
        players[nextId] = player
        return nextId
    }

    @objc public static func getPlayer(_ textureId: Int64) -> BetterPlayer? {
        let player = players[textureId]
        return player
    }

    @objc public static func createCacheManager() -> CacheManager {
        return CacheManager.shared
    }

    @objc public static func preCache(url: String, cacheKey: String?, videoExtension: String?, headers: [String: String]?) {
        guard let nsurl = URL(string: url) else { return }
        CacheManager.shared.preCacheURL(nsurl, cacheKey: cacheKey, videoExtension: videoExtension, withHeaders: (headers as [NSObject: AnyObject]?) ?? [:], completionHandler: nil as ((Bool) -> Void)?)
    }

    @objc public static func stopPreCache(url: String, cacheKey: String?) {
        guard let nsurl = URL(string: url) else { return }
        CacheManager.shared.stopPreCache(nsurl, cacheKey: cacheKey, completionHandler: nil as ((Bool) -> Void)?)
    }

    @objc public static func clearCache() {
        CacheManager.shared.clearCache()
    }

    @objc public static func isPictureInPictureSupported() -> Bool {
        return AVPictureInPictureController.isPictureInPictureSupported()
    }

    // Reference the dummy class to prevent the linker from stripping it out
    @objc public static let _dummyCallback: BetterPlayerCallback = _DummyBetterPlayerCallbackImpl()
}

// Dummy class to force the Swift compiler to emit the full Objective-C protocol metadata
// for BetterPlayerCallback into the runtime, preventing FailedToLoadProtocolMethodException in Dart.
@objc public class _DummyBetterPlayerCallbackImpl: NSObject, BetterPlayerCallback {
    @objc public func onInitialized(durationMs: Int64, width: Double, height: Double, key: String?) {}
    @objc public func onCompleted(key: String?) {}
    @objc public func onPlay(key: String?) {}
    @objc public func onPause(key: String?) {}
    @objc public func onSeek(positionMs: Int64, key: String?) {}
    @objc public func onBufferingStart(key: String?) {}
    @objc public func onBufferingEnd(key: String?) {}
    @objc public func onBufferingUpdate(jsonRanges: String, key: String?) {}
    @objc public func onPipStart() {}
    @objc public func onPipStop() {}
    @objc public func onError(_ errorCode: String, errorMessage: String, errorDetails: String) {}
}
