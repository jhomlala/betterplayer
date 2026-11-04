// Better Player Swift implementation

import AVFoundation
import Foundation

/// A delegate for AVAssetResourceLoader that handles FairPlay DRM license requests.
public class BetterPlayerEzDrmAssetsLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {

    /// The URL for the application's DRM certificate.
    public let certificateURL: URL

    /// The optional URL for the DRM license server.
    public let licenseURL: URL?

    private let defaultLicenseServerURL = URL(string: "https://fps.ezdrm.com/api/licenses/")!
    private let certificateLock = NSLock()
    private var cachedCertificate: Data?
    private var isFetchingCertificate = false
    private var pendingCertificateCompletions: [(Result<Data, Error>) -> Void] = []

    /// Initializes a new instance of the loader delegate.
    /// - Parameters:
    ///   - certificateURL: The URL for the DRM certificate.
    ///   - licenseURL: The optional URL for the license server.
    public init(_ certificateURL: URL, withLicenseURL licenseURL: URL?) {
        self.certificateURL = certificateURL
        self.licenseURL = licenseURL
        super.init()
    }

    // MARK: - Private Methods

    private func extractAssetId(from url: URL) -> String {
        let urlString = url.absoluteString

        // Preserve legacy EZDRM behavior for GUIDs (36 characters).
        if urlString.count >= 36 {
            let startIndex = urlString.index(urlString.endIndex, offsetBy: -36)
            return String(urlString[startIndex...])
        }

        // Check path components without lowercasing host.
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        if let last = pathComponents.last, !last.isEmpty {
            return last
        }

        // Fallback: strip skd:// scheme without host transformation.
        if urlString.hasPrefix("skd://") {
            return String(urlString.dropFirst(6))
        }

        return urlString
    }

    private func buildLicenseURL(assetId: String) -> URL? {
        let targetURL = licenseURL ?? defaultLicenseServerURL
        let isEzDrm = targetURL.host?.contains("ezdrm.com") ?? false
        if isEzDrm {
            var baseString = targetURL.absoluteString
            if !baseString.hasSuffix("/") {
                baseString += "/"
            }
            return URL(string: "\(baseString)\(assetId)?customdata=\(assetId)")
        }
        return targetURL
    }

    private func fetchCertificate(completion: @escaping (Result<Data, Error>) -> Void) {
        certificateLock.lock()
        if let cached = cachedCertificate {
            certificateLock.unlock()
            completion(.success(cached))
            return
        }

        pendingCertificateCompletions.append(completion)
        if isFetchingCertificate {
            certificateLock.unlock()
            return
        }
        isFetchingCertificate = true
        certificateLock.unlock()

        let completeAll: (Result<Data, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            self.certificateLock.lock()
            let callbacks = self.pendingCertificateCompletions
            self.pendingCertificateCompletions.removeAll()
            self.isFetchingCertificate = false
            if case .success(let data) = result {
                self.cachedCertificate = data
            }
            self.certificateLock.unlock()

            for callback in callbacks {
                callback(result)
            }
        }

        if certificateURL.isFileURL {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                do {
                    let data = try Data(contentsOf: self.certificateURL)
                    completeAll(.success(data))
                } catch {
                    completeAll(.failure(error))
                }
            }
            return
        }

        let task = URLSession.shared.dataTask(with: certificateURL) { data, response, error in
            if let error = error {
                completeAll(.failure(error))
                return
            }
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let statusError = NSError(
                    domain: "BetterPlayerFairPlay",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to download DRM certificate. HTTP status: \(httpResponse.statusCode)"
                    ]
                )
                completeAll(.failure(statusError))
                return
            }
            guard let data = data, !data.isEmpty else {
                let emptyError = NSError(
                    domain: "BetterPlayerFairPlay",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "DRM certificate data is empty"]
                )
                completeAll(.failure(emptyError))
                return
            }
            completeAll(.success(data))
        }
        task.resume()
    }

    private func fetchContentKey(
        ksmURL: URL,
        spc: Data,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        var request = URLRequest(url: ksmURL)
        request.httpMethod = "POST"
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = spc
        request.timeoutInterval = 30.0

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    let statusError = NSError(
                        domain: "BetterPlayerFairPlay",
                        code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "FairPlay license request failed with HTTP \(httpResponse.statusCode). Response: \(responseBody)"
                        ]
                    )
                    completion(.failure(statusError))
                    return
                }
            }

            guard let ckcData = data, !ckcData.isEmpty else {
                let emptyDataError = NSError(
                    domain: NSURLErrorDomain,
                    code: NSURLErrorBadServerResponse,
                    userInfo: [NSLocalizedDescriptionKey: "FairPlay license response was empty"]
                )
                completion(.failure(emptyDataError))
                return
            }

            completion(.success(ckcData))
        }
        task.resume()
    }

    private func handleContentKeyRequest(
        loadingRequest: AVAssetResourceLoadingRequest,
        certificate: Data,
        assetId: String
    ) {
        guard !loadingRequest.isCancelled else { return }

        guard let contentIdData = assetId.data(using: .utf8) else {
            loadingRequest.finishLoading(with: NSError(
                domain: "BetterPlayerFairPlay",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Unable to encode assetId to UTF-8: \(assetId)"]
            ))
            return
        }

        let spcData: Data
        do {
            spcData = try loadingRequest.streamingContentKeyRequestData(
                forApp: certificate,
                contentIdentifier: contentIdData,
                options: nil
            )
        } catch {
            loadingRequest.finishLoading(with: error)
            return
        }

        guard let ksmURL = buildLicenseURL(assetId: assetId) else {
            loadingRequest.finishLoading(with: NSError(
                domain: "BetterPlayerFairPlay",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid license server URL"]
            ))
            return
        }

        fetchContentKey(ksmURL: ksmURL, spc: spcData) { [loadingRequest] result in
            guard !loadingRequest.isCancelled else { return }

            switch result {
            case .failure(let error):
                loadingRequest.finishLoading(with: error)
            case .success(let ckcData):
                loadingRequest.dataRequest?.respond(with: ckcData)
                loadingRequest.finishLoading()
            }
        }
    }

    // MARK: - AVAssetResourceLoaderDelegate

    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let assetURI = loadingRequest.request.url, assetURI.scheme == "skd" else {
            return false
        }

        let assetId = extractAssetId(from: assetURI)

        fetchCertificate { [weak self, loadingRequest] certResult in
            guard !loadingRequest.isCancelled else { return }

            guard let self = self else {
                loadingRequest.finishLoading(with: NSError(
                    domain: "BetterPlayerFairPlay",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Resource loader delegate was deallocated before certificate could be loaded"]
                ))
                return
            }

            switch certResult {
            case .failure(let error):
                loadingRequest.finishLoading(with: error)
            case .success(let certificate):
                self.handleContentKeyRequest(
                    loadingRequest: loadingRequest,
                    certificate: certificate,
                    assetId: assetId
                )
            }
        }
        return true
    }

    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return self.resourceLoader(resourceLoader, shouldWaitForLoadingOfRequestedResource: renewalRequest)
    }

    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        // Handled via loadingRequest.isCancelled guards in completion callbacks.
    }
}
