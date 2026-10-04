package pl.hasoft.better_player

import android.app.Activity
import android.content.Context
import androidx.annotation.Keep
import io.flutter.view.TextureRegistry
import java.util.concurrent.atomic.AtomicLong

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
        fun setLogCallback(callback: BetterPlayerLogCallback?) {
            _logCallback = callback
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

        // Ids of players without a texture come from this counter, never from
        // the TextureRegistry. The base keeps them clear of texture ids, which
        // Dart uses as keys in the same map.
        private const val SURFACE_PLAYER_ID_BASE = 1L shl 40
        private val nextSurfacePlayerId = AtomicLong(SURFACE_PLAYER_ID_BASE)

        /**
         * Creates a player with no Flutter texture behind it. The caller
         * (better_player_android_surfaceview) supplies the video surface later
         * through [BetterPlayer.setVideoSurface].
         */
        @Keep
        fun createSurfacePlayer(context: Context, callback: BetterPlayerCallback): BetterPlayer {
            return BetterPlayer(
                context,
                null,
                callback,
                surfacelessPlayerId = nextSurfacePlayerId.getAndIncrement(),
            )
        }
    }
}