//
//  NerdStatHelper.swift
//  better_player
//
//  Created by Ananda Rai on 21/04/2022.
//

import Foundation
import AVKit

@objc public class NerdStatHelper: NSObject {
    
    @objc public func getNerdStatText(player: AVPlayer?) -> String {
        
        guard let currentItem = player?.currentItem, let accessLogEvent = currentItem.accessLog()?.events.last else { return "" }
        
        let nerdsStatus = NerdsStats()
        
        if nerdsStatus.videoResolution == nil {
            nerdsStatus.videoResolution = currentItem.presentationSize
        }
        if nerdsStatus.videoFormat == nil {
            if let assetTrack = currentItem.tracks.first?.assetTrack, assetTrack.mediaType == .video {
                nerdsStatus.videoFormat = assetTrack.mediaFormat
            }
            if let assetTrack = currentItem.tracks.last?.assetTrack, assetTrack.mediaType == .audio {
                nerdsStatus.audioFormat = assetTrack.mediaFormat
            }
        }
        
        nerdsStatus.droppedFrames = accessLogEvent.numberOfDroppedVideoFrames
        nerdsStatus.bandwidthInBit = accessLogEvent.observedBitrate
        nerdsStatus.numberOfBytesTransferred = accessLogEvent.numberOfBytesTransferred
        nerdsStatus.bufferHealth = currentItem.bufferHealth()
        
        return self.getText(detail: nerdsStatus)
    }
    
    private func getText(detail: NerdsStats) -> String {
        let noDataText = "---"
        var str = ""
        
        let bufferHealthTitle = "Buffer Health:"
        if let bufferHealth = detail.bufferHealth {
            let bufferHealthDoubleValue = bufferHealth.doubleValue
            str = "\(bufferHealthTitle) \(bufferHealthDoubleValue.stringAfterLimitingPrecisions() ?? noDataText) s"
        } else {
            str = "\(bufferHealthTitle) \(noDataText)"
        }
        
        let bandWidthTitle = "Bandwidth:"
        if let bandwidthBit = detail.bandwidthInBit {
            if bandwidthBit < 1048576 {
                if let value = (bandwidthBit / 1024).stringAfterLimitingPrecisions() {
                    str += "\n\(bandWidthTitle) \(value) kbps"
                }
            } else if let value = (bandwidthBit / 1048576).stringAfterLimitingPrecisions() {
                str += "\n\(bandWidthTitle) \(value) mbps"
            }
        } else {
            str += "\n\(bandWidthTitle) \(noDataText)"
        }
        
        let videoFormatTitle = "Video:"
        if let videoFormat = detail.videoFormat {
            var text = videoFormat
            if let resolution = detail.videoResolution {
                text += " (\(Int(resolution.width)) x \(Int(resolution.height)))"
            }
            str += "\n\(videoFormatTitle) \(text)"
        } else {
            str += "\n\(videoFormatTitle) \(noDataText)"
        }
        
        str += "\nAudio: \(detail.audioFormat ?? noDataText)"
        
        let networkActivityTitle = "Network Activity:"
        if let bytesTransferred = detail.numberOfBytesTransferred {
            str += "\n\(networkActivityTitle) \(bytesTransferred / 1048576) MB"
        } else {
            str += "\n\(networkActivityTitle) \(noDataText)"
        }
        
        let framesDroppedTitle = "Framedrop:"
        if let totalFramesDropped = detail.droppedFrames {
            str += "\n\(framesDroppedTitle) \(totalFramesDropped)"
        } else {
            str += "\n\(framesDroppedTitle) \(noDataText)"
        }
        
        return str
    }
}

class NerdsStats: NSObject {
    var videoFormat: String?
    var audioFormat: String?
    var videoResolution: CGSize?
    
    var droppedFrames: Int?
    var bandwidthInBit: Double?
    var numberOfBytesTransferred: Int64?
    var bufferHealth: NSNumber?
    
    func clearVideoPropertiesRelatedData() {
        self.videoFormat = nil
        self.audioFormat = nil
        self.videoResolution = nil
    }
}

extension AVAssetTrack {
    var mediaFormat: String {
        var format = ""
        let descriptions = self.formatDescriptions as! [CMFormatDescription]
        for (index, formatDesc) in descriptions.enumerated() {
            // Get String representation of media type (vide, soun, sbtl, etc.)
            let type =
                CMFormatDescriptionGetMediaType(formatDesc).toString()
            // Get String representation media subtype (avc1, aac, tx3g, etc.)
            let subType =
                CMFormatDescriptionGetMediaSubType(formatDesc).toString()
            // Format string as type/subType
            format += "\(type)/\(subType)"
            // Comma separate if more than one format description
            if index < descriptions.count - 1 {
                format += ","
            }
        }
        return format
    }
}

extension AVPlayerItem {
    func bufferHealth() -> NSNumber? {
        // Get player time ranges. If not, return nil
        let timeRanges: [NSValue] = self.loadedTimeRanges
        if timeRanges.count < 1 {
            return nil
        }
        let currentTime = self.currentTime()
        // Get the valid time range from time ranges, return nil if not valid one.
        guard let timeRange = getTimeRange(timeRanges: timeRanges, forCurrentTime: currentTime) else {
            return nil
        }
        return max(timeRange.end.seconds - timeRange.start.seconds, 0) as NSNumber
    }
    
    func getTimeRange(timeRanges: [NSValue], forCurrentTime time: CMTime) -> CMTimeRange? {
        let timeRange = timeRanges.first(where: { (value) -> Bool in
            CMTimeRangeContainsTime(value.timeRangeValue, time: time)
        })
        // Workaround: When pause the player, the item loaded ranges moves whereas the current time
        // remains equal. In time, the current time is out of the range, so the buffer health cannot
        // be calculated. For this reason, when there is not range for current item, the first range
        // is returned to calculate the buffer with it.
        if timeRange == nil && timeRanges.count > 0 {
            return timeRanges.first!.timeRangeValue
        }
        return timeRange?.timeRangeValue
    }
}

extension FourCharCode {
    // Create a String representation of a FourCC
    func toString() -> String {
        let bytes: [CChar] = [
            CChar((self >> 24) & 0xff),
            CChar((self >> 16) & 0xff),
            CChar((self >> 8) & 0xff),
            CChar(self & 0xff),
            0
        ]
        let result = String(cString: bytes)
        let characterSet = CharacterSet.whitespaces
        return result.trimmingCharacters(in: characterSet)
    }
}

extension Double {
    func stringAfterLimitingPrecisions(minFractionDigits: Int = 0, maxFractionDigits: Int = 2) -> String? {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = minFractionDigits
        formatter.maximumFractionDigits = maxFractionDigits
        return (formatter.string(from: NSNumber(value: self)))
    }
}
