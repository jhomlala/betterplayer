package pl.hasoft.better_player

import androidx.annotation.Keep

@Keep
interface BetterPlayerLogCallback {
    @Keep
    fun onLog(level: Int, message: String)
}
