// Better Player Swift implementation

import AVFoundation
import Foundation

/// Utility class for time-related calculations and conversions.
public enum BetterPlayerTimeUtils {

    /// Converts CMTime to milliseconds.
    /// - Parameter time: The CMTime to convert.
    /// - Returns: The time in milliseconds.
    public static func cmTimeToMillis(_ time: CMTime) -> Int64 {
        guard time.timescale != 0 else { return 0 }
        return Int64(time.value) * 1000 / Int64(time.timescale)
    }

    /// Converts TimeInterval to milliseconds.
    /// - Parameter interval: The TimeInterval to convert.
    /// - Returns: The time in milliseconds.
    public static func timeIntervalToMillis(_ interval: TimeInterval) -> Int64 {
        return Int64(interval * 1000.0)
    }
}
