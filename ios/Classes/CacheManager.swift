//
//  CacheManager.swift
//  betterplayer
//  Created by mrj on 11/06/2021.
//
import AVKit
import Cache
import Swime


@objc public class CacheManager: NSObject {

    // We store the last pre-cached CachingPlayerItem objects to be able to play even if the download
    // has not finished.
    var _preCachedURLs = Dictionary<String, CachingPlayerItem>()

    var completionHandler: ((_ success:Bool) -> Void)? = nil

    var diskConfig = DiskConfig(name: "BetterPlayerCache", expiry: .date(Date().addingTimeInterval(3600*24*30)), maxSize: 100*1024*1024)
    let memoryConfig = MemoryConfig(
      // Expiry date that will be applied by default for every added object
      // if it's not overridden in the `setObject(forKey:expiry:)` method
      expiry: .never,
      // The maximum number of objects in memory the cache should hold
      countLimit: 0,
      // The maximum total cost that the cache can hold before it starts evicting objects, 0 for no limit
      totalCostLimit: 0
    )

    lazy var storage: Cache.Storage? = {
        return try? Cache.Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: Data.self))
    }()

    @objc public func setMaxCacheSize(_ maxCacheSize: NSNumber?){
        if let unsigned = maxCacheSize {
            let _maxCacheSize = unsigned.uintValue
            diskConfig = DiskConfig(name: "BetterPlayerCache", expiry: .date(Date().addingTimeInterval(3600*24*30)), maxSize: _maxCacheSize)
        }        
    }

    // MARK: - Logic
    @objc public func preCacheURL(_ url: URL, cacheKey: String?, withHeaders headers: Dictionary<NSObject,AnyObject>, completionHandler: ((_ success:Bool) -> Void)?) {
        self.completionHandler = completionHandler
        
        let _key: String = cacheKey ?? url.absoluteString
        // Make sure the item is not already being downloaded
        if self._preCachedURLs[_key] == nil {            
            if let item = self.getCachingPlayerItem(url, cacheKey: _key, headers: headers){
                if !self._existsInStorage {
                    self._preCachedURLs[_key] = item
                    item.download()
                } else {
                    self.completionHandler?(true)
                }
            } else {
                self.completionHandler?(false)
            }
        } else {
            self.completionHandler?(true)
        }
    }

    // Flag whether the CachingPlayerItem was already cached.
    var _existsInStorage: Bool = false

    // Get a CachingPlayerItem either from the network if it's not cached or from the cache.
    @objc public func getCachingPlayerItem(_ url: URL, cacheKey: String?, headers: Dictionary<NSObject,AnyObject>) -> CachingPlayerItem? {
        let playerItem: CachingPlayerItem
        let _key: String = cacheKey ?? url.absoluteString
        // Fetch ongoing pre-cached url if it exists
        if self._preCachedURLs[_key] != nil {
            playerItem = self._preCachedURLs[_key]!
            self._preCachedURLs.removeValue(forKey: _key)
        } else {
            // Trying to retrieve a track from cache syncronously
            let data = try? storage?.object(forKey: _key)
            if data != nil {
                // The file is cached.
                // We need to retrieve mimeType from Data
                self._existsInStorage = true
                guard let mimeType = Swime.mimeType(data: data!) else {
                    NSLog("Error: could not retrieve mimeType from Data")
                    return nil
                }
                playerItem = CachingPlayerItem(data: data!, mimeType: mimeType.mime, fileExtension: mimeType.ext)
            } else {
                // The file is not cached.
                playerItem = CachingPlayerItem(url: url, cacheKey: _key, headers: headers)
                self._existsInStorage = false
            }
        }
        playerItem.delegate = self
        return playerItem
    }
    
    // Remove all objects
    @objc public func clearCache(){
        try? storage?.removeAll()
        self._preCachedURLs = Dictionary<String,CachingPlayerItem>()
    }
}

// MARK: - CachingPlayerItemDelegate
extension CacheManager: CachingPlayerItemDelegate {
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        // A track is downloaded. Saving it to the cache asynchronously.
        storage?.async.setObject(data, forKey: playerItem.cacheKey ?? playerItem.url.absoluteString, completion: { _ in })
        self.completionHandler?(true)
    }

/*     func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int){
        /// Is called every time a new portion of data is received.
        let percentage = Double(bytesDownloaded)/Double(bytesExpected)*100.0
        let str = String(format: "%.1f%%", percentage)
        NSLog("Downloading... %@", str)
    } */

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error){
        /// Is called on downloading error.
        NSLog("Error when downloading the file %@", error as NSError);
        self.completionHandler?(false)
    }
}
