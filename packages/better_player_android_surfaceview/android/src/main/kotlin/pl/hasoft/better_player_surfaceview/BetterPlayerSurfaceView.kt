package pl.hasoft.better_player_surfaceview

import android.content.Context
import android.os.Build
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import androidx.media3.common.util.UnstableApi
import io.flutter.plugin.platform.PlatformView
import pl.hasoft.better_player.BetterPlayer

@UnstableApi
internal class BetterPlayerSurfaceView(
    context: Context,
    player: BetterPlayer?,
) : PlatformView {
    // Cleared in dispose() so a lingering view cannot keep the player (and
    // through it ExoPlayer) reachable.
    private var player: BetterPlayer? = player

    private val surfaceView: SurfaceView = object : SurfaceView(context) {
        // Re-attach when visible again, e.g. after a fullscreen route is
        // closed and the inline view underneath shows up.
        override fun onVisibilityChanged(changedView: View, visibility: Int) {
            super.onVisibilityChanged(changedView, visibility)
            if (visibility == View.VISIBLE && isShown) {
                val surface = holder.surface
                if (surface.isValid) this@BetterPlayerSurfaceView.player?.let {
                    SurfaceStacks.attach(it, surface)
                }
            }
        }
    }

    private val holderCallback = object : SurfaceHolder.Callback {
        override fun surfaceCreated(holder: SurfaceHolder) {
            player?.let { SurfaceStacks.attach(it, holder.surface) }
        }

        override fun surfaceChanged(
            holder: SurfaceHolder, format: Int, width: Int, height: Int
        ) {}

        override fun surfaceDestroyed(holder: SurfaceHolder) {
            player?.let { SurfaceStacks.detach(it, holder.surface) }
        }
    }

    init {
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.N_MR1) {
            // Without this, Android < 8 shows an empty area instead of video.
            surfaceView.setZOrderMediaOverlay(true)
        }
        surfaceView.holder.addCallback(holderCallback)
    }

    override fun getView(): View = surfaceView

    override fun dispose() {
        // Callback first: a surfaceDestroyed() after this must not touch a
        // player we no longer own.
        surfaceView.holder.removeCallback(holderCallback)
        player?.let { SurfaceStacks.detach(it, surfaceView.holder.surface) }
        player = null
    }
}
