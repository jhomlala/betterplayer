package pl.hasoft.better_player_surfaceview

import android.content.Context
import androidx.media3.common.util.UnstableApi
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import pl.hasoft.better_player.BetterPlayerRegistry

@UnstableApi
internal class BetterPlayerSurfaceViewFactory :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val playerId = ((args as? Map<*, *>)?.get("playerId") as? Number)?.toLong()
        // A missing player (already disposed) yields an empty view rather
        // than an exception on the platform thread.
        val player = playerId?.let { BetterPlayerRegistry.get(it) }
        return BetterPlayerSurfaceView(context, player)
    }

    companion object {
        // Must match `surfaceViewType` in surface_video_view.dart.
        const val VIEW_TYPE = "better_player_android_surfaceview/video"
    }
}
