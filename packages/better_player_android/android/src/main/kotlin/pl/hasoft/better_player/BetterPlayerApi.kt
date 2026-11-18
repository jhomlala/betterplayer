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
        fun setScreenCaptureProtection(enabled: Boolean) {
            val act = activity ?: return
            act.runOnUiThread {
                if (enabled) {
                    act.window?.setFlags(
                        android.view.WindowManager.LayoutParams.FLAG_SECURE,
                        android.view.WindowManager.LayoutParams.FLAG_SECURE
                    )
                } else {
                    act.window?.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SECURE)
                }
            }
        }

        // Each player with the registry of the engine that created it.
        private val players = mutableListOf<Pair<BetterPlayer, TextureRegistry>>()

        @Keep
        fun createPlayer(context: Context, callback: BetterPlayerCallback): BetterPlayer? {
            val registry = textureRegistry ?: return null
            val player = BetterPlayer(context, registry.createSurfaceTexture(), callback)
            synchronized(players) { players.add(player to registry) }
            return player
        }

        internal fun onPlayerDisposed(player: BetterPlayer) {
            synchronized(players) { players.removeAll { it.first === player } }
        }

        // Dart can't dispose its players once its engine is gone, so a
        // playing player would keep going after the app is closed. Players
        // from other engines, such as a background messaging engine, stay.
        internal fun disposePlayers(registry: TextureRegistry) {
            val enginePlayers = synchronized(players) {
                players.filter { it.second === registry }.map { it.first }
            }
            enginePlayers.forEach { it.dispose() }
        }
    }
}
