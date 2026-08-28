import Foundation

@objc public protocol BetterPlayerCallback {
    @objc func onInitialized(durationMs: Int64, width: Double, height: Double, key: String?)
    @objc func onCompleted(key: String?)
    @objc func onPlay(key: String?)
    @objc func onPause(key: String?)
    @objc func onSeek(positionMs: Int64, key: String?)
    @objc func onBufferingStart(key: String?)
    @objc func onBufferingEnd(key: String?)
    @objc func onBufferingUpdate(jsonRanges: String, key: String?)
    @objc func onPipStart()
    @objc func onPipStop()
    @objc func onError(_ errorCode: String, errorMessage: String, errorDetails: String)
}

@objc public class BetterPlayerApi: NSObject {
    @objc public static var players: [Int64: BetterPlayer] = [:]
    @objc public static var nextId: Int64 = 0
    
    @objc public static func createPlayer(callback: BetterPlayerCallback) -> Int64 {
        let player = BetterPlayer()
        player.callback = callback
        nextId += 1
        players[nextId] = player
        return nextId
    }

    @objc public static func getPlayer(_ textureId: Int64) -> BetterPlayer? {
        return players[textureId]
    }

    @objc public static func createCacheManager() -> CacheManager {
        return CacheManager()
    }
}
