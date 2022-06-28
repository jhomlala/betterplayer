package com.jhomlala.better_player

import android.content.Context
import android.util.LongSparseArray
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


internal class BetterViewFactory(private val videoPlayers: LongSparseArray<BetterPlayer>) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val layout = LinearLayout(context)

        val creationParams = args as Map<String?, Any?>?
        val textureId = (creationParams!!["textureId"] as Int).toLong()
        val player = videoPlayers[textureId]

        val surfaceView = player.getSurfaceView

        if (surfaceView.parent != null) {
            (surfaceView.parent as ViewGroup).removeView(surfaceView)
        }

        layout.addView(surfaceView)

        return BetterPlatformView(layout)
    }
}

internal class BetterPlatformView(private val view: View) :
    PlatformView {
    override fun getView(): View {
        return view
    }

    override fun dispose() {
    }
}
