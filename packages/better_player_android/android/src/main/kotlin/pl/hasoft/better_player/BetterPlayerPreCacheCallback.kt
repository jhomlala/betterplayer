package pl.hasoft.better_player

import androidx.annotation.Keep

@Keep
interface BetterPlayerPreCacheCallback {
    @Keep
    fun onProgress(url: String, cacheKey: String?, progress: Double, bytesDownloaded: Long, totalBytes: Long)
}
