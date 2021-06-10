import AVKit
import Cache

class CacheHandler {

    let diskConfig = DiskConfig(name: "DiskCache")
    let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)

    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
    }()


    // MARK: - Logic

    /// Plays a track either from the network if it's not cached or from the cache.
    func getCachingPlayerItem(with url: URL, key: String?, headers: NSDictionary?) -> CachingPlayerItem {
        // Trying to retrieve a track from cache asynchronously.
        
        let _key: String
        if key != nil {
            _key = key
        } else {
            _key = url.absoluteString
        }
        storage?.async.entry(ofType: Data.self, forKey: _key, completion: { result in
            let playerItem: CachingPlayerItem
            switch result {
            case .error:
                // The track is not cached.
                playerItem = CachingPlayerItem(url: url, cacheKey: _key, headers: headers)
            case .value(let entry):
                // The track is cached.
                playerItem = CachingPlayerItem(data: entry.object, mimeType: "video/mpeg", fileExtension: "mp4")
            }
            playerItem.delegate = self
        })
    }
    
    // Remove all objects
    func clearCache(){
        try? storage.removeAll()
    }




// MARK: - CachingPlayerItemDelegate
extension CacheHandler: CachingPlayerItemDelegate {
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        // A track is downloaded. Saving it to the cache asynchronously.
        storage?.async.setObject(data, forKey: playerItem.cacheKey, completion: { _ in })
    }
}