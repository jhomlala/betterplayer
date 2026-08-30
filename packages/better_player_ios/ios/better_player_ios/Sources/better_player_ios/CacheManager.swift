// Better Player Swift implementation

import AVKit
import Cache

/// Manages caching of media files for `BetterPlayer`.
@objc public class CacheManager: NSObject {
    @objc public static let shared = CacheManager()

    /// Stores the last pre-cached `CachingPlayerItem` objects.
    private var preCachedURLs = [String: CachingPlayerItem]()

    /// Callback for pre-caching completion.
    private var completionHandler: ((_ success: Bool) -> Void)? = nil

    /// Configuration for disk cache.
    private var diskConfig = DiskConfig(
        name: "BetterPlayerCache",
        expiry: .date(Date().addingTimeInterval(3600 * 24 * 30)),
        maxSize: 100 * 1024 * 1024
    )

    /// Flag indicating if the item already exists in storage.
    private var existsInStorage: Bool = false

    /// Configuration for memory cache.
    private let memoryConfig = MemoryConfig(
        expiry: .never,
        countLimit: 0,
        totalCostLimit: 0
    )

    /// The underlying storage for the cache.
    lazy var storage: Cache.Storage<String, Data>? = {
        return try? Cache.Storage<String, Data>(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: Data.self)
        )
    }()

    // MARK: - Lifecycle

    /// Setups cache server for HLS streams.
    /// - Note: No setup is required for iOS HLS playback as it is routed directly through AVURLAsset.
    @available(*, deprecated, message: "No setup is required for iOS HLS playback.")
    @objc public func setup() {
        // Intentionally left blank. HLS playback is routed directly through AVURLAsset
        // to keep compatibility with modern fMP4/CMAF playlists.
    }

    // MARK: - Configuration

    /// Sets the maximum cache size in bytes.
    /// - Parameter maxCacheSize: The maximum size of the cache.
    @objc public func setMaxCacheSize(_ maxCacheSize: NSNumber?) {
        if let unsigned = maxCacheSize {
            let size = unsigned.uintValue
            diskConfig = DiskConfig(
                name: "BetterPlayerCache",
                expiry: .date(Date().addingTimeInterval(3600 * 24 * 30)),
                maxSize: size
            )
        }
    }

    // MARK: - Logic

    /// Pre-caches a URL for later playback.
    /// - Parameters:
    ///   - url: The URL to pre-cache.
    ///   - cacheKey: The key for the cache.
    ///   - videoExtension: The video file extension.
    ///   - headers: The HTTP headers for the request.
    ///   - completionHandler: Callback when pre-caching finishes.
    @objc public func preCacheURL(_ url: URL, cacheKey: String?, videoExtension: String?, withHeaders headers: [NSObject: AnyObject], completionHandler: ((_ success: Bool) -> Void)?) {
        self.completionHandler = completionHandler

        let key: String = cacheKey ?? url.absoluteString
        // Make sure the item is not already being downloaded
        if self.preCachedURLs[key] == nil {
            if let item = self.getCachingPlayerItem(url, cacheKey: key, videoExtension: videoExtension, headers: headers) {
                if !self.existsInStorage {
                    self.preCachedURLs[key] = item
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

    /// Stops an ongoing pre-caching process.
    /// - Parameters:
    ///   - url: The URL to stop pre-caching.
    ///   - cacheKey: The key for the cache.
    ///   - completionHandler: Callback when stopping finishes.
    @objc public func stopPreCache(_ url: URL, cacheKey: String?, completionHandler: ((_ success: Bool) -> Void)?) {
        let key: String = cacheKey ?? url.absoluteString
        if let playerItem = self.preCachedURLs[key] {
            playerItem.stopDownload()
            self.preCachedURLs.removeValue(forKey: key)
            completionHandler?(true)
            return
        }
        completionHandler?(false)
    }

    /// Gets a caching player item for normal playback.
    /// - Parameters:
    ///   - url: The URL of the media.
    ///   - cacheKey: The key for the cache.
    ///   - videoExtension: The video file extension.
    ///   - headers: The HTTP headers for the request.
    /// - Returns: An `AVPlayerItem` configured for playback with caching.
    @objc public func getCachingPlayerItemForNormalPlayback(_ url: URL, cacheKey: String?, videoExtension: String?, headers: [NSObject: AnyObject]) -> AVPlayerItem? {
        let mimeTypeResult = getMimeType(url: url, explicitVideoExtension: videoExtension)
        if mimeTypeResult.1 == "application/vnd.apple.mpegurl" {
            var httpHeaders = [String: String]()
            headers.forEach { key, value in
                let convertedKey: String? = key as? String
                let convertedValue: String? = (value as? String)
                    ?? (value as? NSNumber).map { $0.stringValue }
                if let convertedKey = convertedKey, let convertedValue = convertedValue {
                    httpHeaders[convertedKey] = convertedValue
                }
            }
            let playerItem = AVPlayerItem(asset: AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": httpHeaders]))
            return playerItem
        } else {
            return getCachingPlayerItem(url, cacheKey: cacheKey, videoExtension: videoExtension, headers: headers)
        }
    }

    /// Get a `CachingPlayerItem` either from the network or from the cache.
    /// - Parameters:
    ///   - url: The URL of the media.
    ///   - cacheKey: The key for the cache.
    ///   - videoExtension: The video file extension.
    ///   - headers: The HTTP headers for the request.
    /// - Returns: A `CachingPlayerItem` if possible.
    @objc public func getCachingPlayerItem(_ url: URL, cacheKey: String?, videoExtension: String?, headers: [NSObject: AnyObject]) -> CachingPlayerItem? {
        let playerItem: CachingPlayerItem
        let key: String = cacheKey ?? url.absoluteString
        // Fetch ongoing pre-cached url if it exists
        if let cachedItem = self.preCachedURLs[key] {
            playerItem = cachedItem
            self.preCachedURLs.removeValue(forKey: key)
        } else {
            // Trying to retrieve a track from cache synchronously
            let data = try? storage?.object(forKey: key)
            if let data = data {
                // The file is cached.
                self.existsInStorage = true
                let mimeTypeResult = getMimeType(url: url, explicitVideoExtension: videoExtension)
                if mimeTypeResult.1.isEmpty {
                    NSLog("Cache error: couldn't find mime type for url: \(url.absoluteURL). Video will be played without cache.")
                    playerItem = CachingPlayerItem(url: url, cacheKey: key, headers: headers)
                } else {
                    playerItem = CachingPlayerItem(data: data, mimeType: mimeTypeResult.1, fileExtension: mimeTypeResult.0)
                }
            } else {
                // The file is not cached.
                playerItem = CachingPlayerItem(url: url, cacheKey: key, headers: headers)
                self.existsInStorage = false
            }
        }
        playerItem.delegate = self
        return playerItem
    }

    /// Removes all objects from the cache.
    @objc public func clearCache() {
        try? storage?.removeAll()
        self.preCachedURLs = [String: CachingPlayerItem]()
    }

    // MARK: - Private Helper Methods

    private func getMimeType(url: URL, explicitVideoExtension: String?) -> (String, String) {
        var videoExtension = url.pathExtension
        if let explicit = explicitVideoExtension {
            videoExtension = explicit
        }
        var mimeType = ""
        switch videoExtension.lowercased() {
        case "m3u", "m3u8":
            mimeType = "application/vnd.apple.mpegurl"
        case "3gp":
            mimeType = "video/3gpp"
        case "mp4", "m4a", "m4p", "m4b", "m4r", "m4v":
            mimeType = "video/mp4"
        case "m1v", "mpg", "mp2", "mpeg", "mpe", "mpv":
            mimeType = "video/mpeg"
        case "ogg":
            mimeType = "video/ogg"
        case "mov", "qt":
            mimeType = "video/quicktime"
        case "webm":
            mimeType = "video/webm"
        case "asf", "wma", "wmv":
            mimeType = "video/ms-asf"
        case "avi":
            mimeType = "video/x-msvideo"
        default:
            mimeType = ""
        }

        return (videoExtension, mimeType)
    }

    /// Checks whether pre-caching is supported for a given URL.
    /// - Parameters:
    ///   - url: The URL to check.
    ///   - videoExtension: The video file extension.
    /// - Returns: True if pre-caching is supported.
    @objc public func isPreCacheSupported(url: URL, videoExtension: String?) -> Bool {
        let mimeTypeResult = getMimeType(url: url, explicitVideoExtension: videoExtension)
        return !mimeTypeResult.1.isEmpty && mimeTypeResult.1 != "application/vnd.apple.mpegurl"
    }
}

// MARK: - CachingPlayerItemDelegate
extension CacheManager: CachingPlayerItemDelegate {

    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data) {
        // A track is downloaded. Saving it to the cache asynchronously.
        storage?.async.setObject(data, forKey: playerItem.cacheKey ?? playerItem.url.absoluteString, completion: { _ in })
        self.completionHandler?(true)
    }

    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        // Optional: track download progress
    }

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        NSLog("Error when downloading the file %@", error as NSError)
        self.completionHandler?(false)
    }
}
