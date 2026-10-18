package pl.hasoft.better_player

import android.app.Activity
import android.content.Context
import androidx.annotation.Keep
import io.flutter.view.TextureRegistry

@Keep
class BetterPlayerApi {
    @Keep
    companion object {
        @Keep
        var textureRegistry: TextureRegistry? = null
        @Keep
        var activity: Activity? = null
        @Keep
        private var _logCallback: BetterPlayerLogCallback? = null
        @Keep
        private var _preCacheCallback: BetterPlayerPreCacheCallback? = null

        @Keep
        fun setLogCallback(callback: BetterPlayerLogCallback?) {
            _logCallback = callback
        }

        @Keep
        fun setPreCacheCallback(callback: BetterPlayerPreCacheCallback?) {
            _preCacheCallback = callback
        }

        internal fun reportPreCacheProgress(
            url: String,
            cacheKey: String?,
            progress: Double,
            bytesDownloaded: Long,
            totalBytes: Long
        ) {
            _preCacheCallback?.onProgress(url, cacheKey, progress, bytesDownloaded, totalBytes)
        }

        internal fun log(level: Int, msg: String) {
            val cb = _logCallback ?: return
            val safe = if (msg.length > 4000) msg.substring(0, 4000) + "…[truncated]" else msg
            cb.onLog(level, safe)
        }
        
        @Keep
        fun createPlayer(context: Context, callback: BetterPlayerCallback): BetterPlayer? {
            val texture = textureRegistry?.createSurfaceTexture() ?: return null
            return BetterPlayer(context, texture, callback)
        }
    }
}