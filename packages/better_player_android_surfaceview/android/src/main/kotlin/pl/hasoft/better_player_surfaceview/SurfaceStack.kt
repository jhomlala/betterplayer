package pl.hasoft.better_player_surfaceview

import android.view.Surface
import androidx.media3.common.util.UnstableApi
import java.util.WeakHashMap
import pl.hasoft.better_player.BetterPlayer

/**
 * The SurfaceViews currently showing one player, newest last. A player can be
 * on screen twice at once (inline view plus the fullscreen route above it);
 * the newest valid surface wins, and when it goes away the one below takes
 * over again.
 *
 * Main thread only — every caller is a view or surface callback.
 */
@UnstableApi
internal object SurfaceStacks {
    // Weak keys: a disposed player must not be kept alive by this map. The
    // stacks themselves never reference the player.
    private val stacks = WeakHashMap<BetterPlayer, ArrayList<Surface>>()

    fun attach(player: BetterPlayer, surface: Surface) {
        val stack = stacks.getOrPut(player) { ArrayList() }
        stack.remove(surface)
        stack.add(surface)
        apply(player, stack)
    }

    fun detach(player: BetterPlayer, surface: Surface) {
        val stack = stacks[player] ?: return
        if (!stack.remove(surface)) return
        apply(player, stack)
        // Drop the entry with its last surface so nothing lingers.
        if (stack.isEmpty()) stacks.remove(player)
    }

    private fun apply(player: BetterPlayer, stack: List<Surface>) {
        // BetterPlayer ignores the call once released, and drops equal
        // surfaces cheaply, so no bookkeeping of "current" is needed here.
        player.setVideoSurface(stack.lastOrNull { it.isValid })
    }
}
