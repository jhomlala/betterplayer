package pl.hasoft.better_player

import java.util.concurrent.ConcurrentHashMap

/**
 * Live players by [BetterPlayer.playerId]. Lets another module (the
 * better_player_android_surfaceview platform view) find the player a Dart
 * widget refers to. A player removes itself in [BetterPlayer.dispose], so
 * nothing here outlives it.
 */
object BetterPlayerRegistry {
    private val players = ConcurrentHashMap<Long, BetterPlayer>()

    fun get(playerId: Long): BetterPlayer? = players[playerId]

    internal fun register(player: BetterPlayer) {
        players[player.playerId] = player
    }

    internal fun unregister(player: BetterPlayer) {
        players.remove(player.playerId, player)
    }
}
