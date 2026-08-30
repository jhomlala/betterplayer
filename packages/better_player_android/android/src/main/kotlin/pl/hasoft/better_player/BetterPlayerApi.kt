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
        var logCallback: BetterPlayerLogCallback? = null

        @Keep
        fun setLogCallback(callback: BetterPlayerLogCallback?) {
            logCallback = callback
        }

        internal fun log(level: Int, tag: String, msg: String) {
            val cb = logCallback ?: return
            val safe = if (msg.length > 4000) msg.substring(0, 4000) + "…[truncated]" else msg
            cb.onLog(level, tag, safe)
        }
        
        @Keep
        fun createPlayer(context: Context, callback: BetterPlayerCallback): BetterPlayer? {
            val texture = textureRegistry?.createSurfaceTexture() ?: return null
            return BetterPlayer(context, texture, callback)
        }
    }
}

