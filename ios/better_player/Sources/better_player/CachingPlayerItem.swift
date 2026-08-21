// Better Player Swift implementation
// Based on https://github.com/neekeetab/CachingPlayerItem.

import AVFoundation
import Foundation

fileprivate extension URL {
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
}

/// A delegate protocol for `CachingPlayerItem` to communicate download and playback status.
@objc protocol CachingPlayerItemDelegate {

    /// Is called when the media file is fully downloaded.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)

    /// Is called every time a new portion of data is received.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)

    /// Is called after initial prebuffering is finished, means we are ready to play.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)

    /// Is called when the data being downloaded did not arrive in time to continue playback.
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)

    /// Is called on downloading error.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
}

/// A specialized `AVPlayerItem` that supports caching media data to disk or memory.
open class CachingPlayerItem: AVPlayerItem {

    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

        var playingFromData = false
        var mimeType: String? // is required when playing from Data
        var session: URLSession?
        var headers: [NSObject: AnyObject]?
        var mediaData: Data?
        var response: URLResponse?
        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
        weak var owner: CachingPlayerItem?

        // MARK: - AVAssetResourceLoaderDelegate

        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
            if playingFromData {
                // Nothing to load.
            } else if session == nil {
                // If we're playing from a url, we need to download the file.
                // We start loading the file on first request only.
                guard let initialUrl = owner?.url else {
                    fatalError("internal inconsistency")
                }
                startDataRequest(url: initialUrl)
            }
            pendingRequests.insert(loadingRequest)
            processPendingRequests()
            return true
        }

        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
            pendingRequests.remove(loadingRequest)
        }

        // MARK: - Data Request

        func startDataRequest(url: URL) {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            if let unwrappedDict = self.headers as? [String: AnyObject] {
                for (headerKey, headerValue) in unwrappedDict {
                    guard let headerValueString = headerValue as? String else {
                        continue
                    }
                    request.setValue(headerValueString, forHTTPHeaderField: headerKey)
                }
            }
            session?.dataTask(with: request).resume()
        }

        // MARK: - URLSessionDelegate

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            mediaData?.append(data)
            processPendingRequests()
            if let owner = owner, let mediaData = mediaData {
                owner.delegate?.playerItem?(owner, didDownloadBytesSoFar: mediaData.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
            }
        }

        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            completionHandler(.allow)
            mediaData = Data()
            self.response = response
            processPendingRequests()
        }

        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let errorUnwrapped = error {
                if let owner = owner {
                    owner.delegate?.playerItem?(owner, downloadingFailedWith: errorUnwrapped)
                }
                return
            }
            processPendingRequests()
            if let owner = owner, let mediaData = mediaData {
                owner.delegate?.playerItem?(owner, didFinishDownloadingData: mediaData)
            }
        }

        // MARK: - Request Processing

        func processPendingRequests() {
            // get all fulfilled requests
            let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
                self.fillInContentInformationRequest($0.contentInformationRequest)
                if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
                    $0.finishLoading()
                    return $0
                }
                return nil
            })

            // remove fulfilled requests from pending requests
            for request in requestsFulfilled {
                pendingRequests.remove(request)
            }
        }

        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
            // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
            if playingFromData {
                contentInformationRequest?.contentType = self.mimeType
                contentInformationRequest?.contentLength = Int64(mediaData?.count ?? 0)
                contentInformationRequest?.isByteRangeAccessSupported = true
                return
            }

            guard let responseUnwrapped = response else {
                // have no response from the server yet
                return
            }

            contentInformationRequest?.contentType = responseUnwrapped.mimeType
            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
            contentInformationRequest?.isByteRangeAccessSupported = true
        }

        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let currentOffset = Int(dataRequest.currentOffset)

            guard let songDataUnwrapped = mediaData, songDataUnwrapped.count > currentOffset else {
                // Don't have any data at all for this request.
                return false
            }

            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
            let dataToRespond = songDataUnwrapped.subdata(in: currentOffset..<(currentOffset + bytesToRespond))
            dataRequest.respond(with: dataToRespond)

            return songDataUnwrapped.count >= requestedLength + requestedOffset
        }

        deinit {
            session?.invalidateAndCancel()
        }
    }

    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()

    /// The original URL of the media content.
    public let url: URL

    /// The key used for identifying the cached content.
    public var cacheKey: String? = nil

    fileprivate let initialScheme: String?
    fileprivate var customFileExtension: String?

    /// The delegate to receive updates about the caching process.
    weak var delegate: CachingPlayerItemDelegate?

    /// Starts the current download process.
    open func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(url: url)
        }
    }

    /// Stops the current download process.
    open func stopDownload() {
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }

    private let cachingPlayerItemScheme = "cachingPlayerItemScheme"

    // MARK: - Initialization

    /// Initializes a new instance for playing remote files with caching.
    /// - Parameters:
    ///   - url: The remote URL.
    ///   - cacheKey: The key for the cache.
    ///   - headers: The HTTP headers to use for the request.
    public convenience init(url: URL, cacheKey: String?, headers: [NSObject: AnyObject]) {
        self.init(url: url, customFileExtension: nil, cacheKey: cacheKey, headers: headers)
    }

    /// Initializes a new instance for playing remote files with a custom file extension and caching.
    /// - Parameters:
    ///   - url: The remote URL.
    ///   - customFileExtension: A custom file extension to append to the URL.
    ///   - cacheKey: The key for the cache.
    ///   - headers: The HTTP headers to use for the request.
    public init(url: URL, customFileExtension: String?, cacheKey: String?, headers: [NSObject: AnyObject]) {
        self.cacheKey = cacheKey
        self.url = url
        self.resourceLoaderDelegate.headers = headers

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = components.scheme,
            var urlWithCustomScheme = url.withScheme(cachingPlayerItemScheme) else {
            fatalError("Urls without a scheme are not supported")
        }
        self.initialScheme = scheme

        if let ext = customFileExtension {
            urlWithCustomScheme.deletePathExtension()
            urlWithCustomScheme.appendPathExtension(ext)
            self.customFileExtension = ext
        }

        let asset = AVURLAsset(url: urlWithCustomScheme)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)

        resourceLoaderDelegate.owner = self

        addObserver(self, forKeyPath: "status", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name: .AVPlayerItemPlaybackStalled, object: self)
    }

    /// Initializes a new instance for playing media from local `Data`.
    /// - Parameters:
    ///   - data: The media data.
    ///   - mimeType: The MIME type of the media.
    ///   - fileExtension: The file extension associated with the media.
    public init(data: Data, mimeType: String, fileExtension: String) {
        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }

        self.url = fakeUrl
        self.initialScheme = nil

        resourceLoaderDelegate.mediaData = data
        resourceLoaderDelegate.playingFromData = true
        resourceLoaderDelegate.mimeType = mimeType

        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: .main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderDelegate.owner = self

        addObserver(self, forKeyPath: "status", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name: .AVPlayerItemPlaybackStalled, object: self)
    }

    // MARK: - KVO

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        delegate?.playerItemReadyToPlay?(self)
    }

    // MARK: - Notification Handlers

    @objc func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }

    // MARK: - Overrides

    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
}
