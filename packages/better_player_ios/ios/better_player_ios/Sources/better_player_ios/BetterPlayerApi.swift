import Foundation

@objc public protocol BetterPlayerCallback {
    @objc func onEvent(_ event: String, parameters: String)
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
