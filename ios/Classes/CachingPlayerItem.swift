//  Based on https://github.com/neekeetab/CachingPlayerItem.
<<<<<<< HEAD
=======

>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
import Foundation
import AVFoundation

fileprivate extension URL {
<<<<<<< HEAD

=======
    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
    func withScheme(_ scheme: String) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components?.url
    }
<<<<<<< HEAD

}

@objc protocol CachingPlayerItemDelegate {

    /// Is called when the media file is fully downloaded.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)

    /// Is called every time a new portion of data is received.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)

    /// Is called after initial prebuffering is finished, means
    /// we are ready to play.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)

    /// Is called when the data being downloaded did not arrive in time to
    /// continue playback.
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)

    /// Is called on downloading error.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)

}

open class CachingPlayerItem: AVPlayerItem {

    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

=======
    
}

@objc protocol CachingPlayerItemDelegate {
    
    /// Is called when the media file is fully downloaded.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingData data: Data)
    
    /// Is called every time a new portion of data is received.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int)
    
    /// Is called after initial prebuffering is finished, means
    /// we are ready to play.
    @objc optional func playerItemReadyToPlay(_ playerItem: CachingPlayerItem)
    
    /// Is called when the data being downloaded did not arrive in time to
    /// continue playback.
    @objc optional func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem)
    
    /// Is called on downloading error.
    @objc optional func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error)
    
}

open class CachingPlayerItem: AVPlayerItem {
    
    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
        var playingFromData = false
        var mimeType: String? // is required when playing from Data
        var session: URLSession?
        var headers: Dictionary<NSObject,AnyObject>?
        var mediaData: Data?
        var response: URLResponse?
        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
        weak var owner: CachingPlayerItem?
<<<<<<< HEAD

=======
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
            if playingFromData {
                // Nothing to load.
            } else if session == nil {
                // If we're playing from a url, we need to download the file.
                // We start loading the file on first request only.
                guard let initialUrl = owner?.url else {
                    fatalError("internal inconsistency")
                }
                startDataRequest( url: initialUrl)
            }
            pendingRequests.insert(loadingRequest)
            processPendingRequests()
            return true
        }
<<<<<<< HEAD

=======
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
        func startDataRequest(url: URL) {
            let configuration = URLSessionConfiguration.default
            configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            let headersString = self.headers as? [String:AnyObject]
            if let unwrappedDict = headersString {
                for (headerKey,headerValue) in  unwrappedDict{
                    guard let headerValueString = headerValue as? String
                    else {
                        continue
                    }
                    request.setValue(headerValueString, forHTTPHeaderField: headerKey)
<<<<<<< HEAD

=======
                    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
                }
            }
            session?.dataTask(with: request).resume()
        }
<<<<<<< HEAD

        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
            pendingRequests.remove(loadingRequest)
        }

        // MARK: URLSession delegate

=======
        
        func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
            pendingRequests.remove(loadingRequest)
        }
        
        // MARK: URLSession delegate
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
            mediaData?.append(data)
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didDownloadBytesSoFar: mediaData!.count, outOf: Int(dataTask.countOfBytesExpectedToReceive))
        }
<<<<<<< HEAD

=======
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
        func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            completionHandler(Foundation.URLSession.ResponseDisposition.allow)
            mediaData = Data()
            self.response = response
            processPendingRequests()
        }
<<<<<<< HEAD

=======
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
        func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
            if let errorUnwrapped = error {
                owner?.delegate?.playerItem?(owner!, downloadingFailedWith: errorUnwrapped)
                return
            }
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didFinishDownloadingData: mediaData!)
        }
<<<<<<< HEAD

        // MARK: -

        func processPendingRequests() {

=======
        
        // MARK: -
        
        func processPendingRequests() {
            
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
            // get all fullfilled requests
            let requestsFulfilled = Set<AVAssetResourceLoadingRequest>(pendingRequests.compactMap {
                self.fillInContentInformationRequest($0.contentInformationRequest)
                if self.haveEnoughDataToFulfillRequest($0.dataRequest!) {
                    $0.finishLoading()
                    return $0
                }
                return nil
            })
<<<<<<< HEAD

=======
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
            // remove fulfilled requests from pending requests
            _ = requestsFulfilled.map { self.pendingRequests.remove($0) }

        }
<<<<<<< HEAD

        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {

=======
        
        func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
            
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
            // if we play from Data we make no url requests, therefore we have no responses, so we need to fill in contentInformationRequest manually
            if playingFromData {
                contentInformationRequest?.contentType = self.mimeType
                contentInformationRequest?.contentLength = Int64(mediaData!.count)
                contentInformationRequest?.isByteRangeAccessSupported = true
                return
            }
<<<<<<< HEAD

=======
            
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
            guard let responseUnwrapped = response else {
                // have no response from the server yet
                return
            }
<<<<<<< HEAD

            contentInformationRequest?.contentType = responseUnwrapped.mimeType
            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
            contentInformationRequest?.isByteRangeAccessSupported = true

        }

        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {

            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let currentOffset = Int(dataRequest.currentOffset)

=======
            
            contentInformationRequest?.contentType = responseUnwrapped.mimeType
            contentInformationRequest?.contentLength = responseUnwrapped.expectedContentLength
            contentInformationRequest?.isByteRangeAccessSupported = true
            
        }
        
        func haveEnoughDataToFulfillRequest(_ dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
            
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let currentOffset = Int(dataRequest.currentOffset)
            
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
            guard let songDataUnwrapped = mediaData,
                songDataUnwrapped.count > currentOffset else {
                // Don't have any data at all for this request.
                return false
            }
<<<<<<< HEAD

            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
            let dataToRespond = songDataUnwrapped.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
            dataRequest.respond(with: dataToRespond)

            return songDataUnwrapped.count >= requestedLength + requestedOffset

        }

        deinit {
            session?.invalidateAndCancel()
        }

    }

=======
            
            let bytesToRespond = min(songDataUnwrapped.count - currentOffset, requestedLength)
            let dataToRespond = songDataUnwrapped.subdata(in: Range(uncheckedBounds: (currentOffset, currentOffset + bytesToRespond)))
            dataRequest.respond(with: dataToRespond)
            
            return songDataUnwrapped.count >= requestedLength + requestedOffset
            
        }
        
        deinit {
            session?.invalidateAndCancel()
        }
        
    }
    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
    fileprivate let resourceLoaderDelegate = ResourceLoaderDelegate()
    let url: URL
    var cacheKey: String? = nil
    fileprivate let initialScheme: String?
    fileprivate var customFileExtension: String?
<<<<<<< HEAD

    weak var delegate: CachingPlayerItemDelegate?

=======
    
    weak var delegate: CachingPlayerItemDelegate?
    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
    ///Starts current download.
    open func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(url: url)
        }
    }
    ///Stops current download.
    open func stopDownload(){
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
<<<<<<< HEAD

    private let cachingPlayerItemScheme = "cachingPlayerItemScheme"

=======
    
    private let cachingPlayerItemScheme = "cachingPlayerItemScheme"
    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
    /// Is used for playing remote files.
    convenience init(url: URL, cacheKey: String?, headers: Dictionary<NSObject,AnyObject>) {
        self.init(url: url, customFileExtension: nil, cacheKey: cacheKey, headers: headers)
    }
<<<<<<< HEAD

=======
    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
    /// Override/append custom file extension to URL path.
    /// This is required for the player to work correctly with the intended file type.
    init(url: URL, customFileExtension: String?, cacheKey: String?, headers: Dictionary<NSObject,AnyObject>) {
        self.cacheKey = cacheKey
        self.url = url
        self.resourceLoaderDelegate.headers = headers
<<<<<<< HEAD

=======
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
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
<<<<<<< HEAD

        let asset = AVURLAsset(url: urlWithCustomScheme)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)

        resourceLoaderDelegate.owner = self

        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
    }

    /// Is used for playing from Data.
    init(data: Data, mimeType: String, fileExtension: String) {

        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }

        self.url = fakeUrl
        self.initialScheme = nil

        resourceLoaderDelegate.mediaData = data
        resourceLoaderDelegate.playingFromData = true
        resourceLoaderDelegate.mimeType = mimeType

=======
        
        let asset = AVURLAsset(url: urlWithCustomScheme)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        
        resourceLoaderDelegate.owner = self
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
    }
    
    /// Is used for playing from Data.
    init(data: Data, mimeType: String, fileExtension: String) {
        
        guard let fakeUrl = URL(string: cachingPlayerItemScheme + "://whatever/file.\(fileExtension)") else {
            fatalError("internal inconsistency")
        }
        
        self.url = fakeUrl
        self.initialScheme = nil
        
        resourceLoaderDelegate.mediaData = data
        resourceLoaderDelegate.playingFromData = true
        resourceLoaderDelegate.mimeType = mimeType
        
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
        let asset = AVURLAsset(url: fakeUrl)
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: DispatchQueue.main)
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderDelegate.owner = self
<<<<<<< HEAD

        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
    }

    // MARK: KVO

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        delegate?.playerItemReadyToPlay?(self)
    }

    // MARK: Notification hanlers

=======
        
        addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playbackStalledHandler), name:NSNotification.Name.AVPlayerItemPlaybackStalled, object: self)
    }
    
    // MARK: KVO
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        delegate?.playerItemReadyToPlay?(self)
    }
    
    // MARK: Notification hanlers
    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
    @objc func playbackStalledHandler() {
        delegate?.playerItemPlaybackStalled?(self)
    }

    // MARK: -
<<<<<<< HEAD

    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }

=======
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }
    
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
<<<<<<< HEAD

}
=======
    
}
>>>>>>> fe7e10acef1b8edb4c660eeb1a3abb8952839b58
