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
        var logLevel: Int = 1 // 0=debug, 1=info, 2=warning, 3=error, 4=none

        @Keep
        fun setupLogger(level: Int) {
            logLevel = level
        }

        fun log(level: Int, tag: String, msg: String) {
            if (logLevel == 4 || level < logLevel) return
            when (level) {
                0 -> android.util.Log.d(tag, msg)
                1 -> android.util.Log.i(tag, msg)
                2 -> android.util.Log.w(tag, msg)
                3 -> android.util.Log.e(tag, msg)
            }
        }
        
        @Keep
        fun createPlayer(context: Context, callback: BetterPlayerCallback): BetterPlayer? {
            val texture = textureRegistry?.createSurfaceTexture() ?: return null
            return BetterPlayer(context, texture, callback)
        }
    }
}
