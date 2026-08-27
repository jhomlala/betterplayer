package pl.hasoft.better_player

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
        fun createPlayer(context: Context, callback: BetterPlayerCallback): BetterPlayer? {
            val texture = textureRegistry?.createSurfaceTexture() ?: return null
            return BetterPlayer(context, texture, callback)
        }
    }
}
