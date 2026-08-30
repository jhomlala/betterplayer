package pl.hasoft.better_player

import androidx.annotation.Keep

@Keep
interface BetterPlayerCallback {
    @Keep
    fun onInitialized(durationMs: Long, width: Int, height: Int, key: String?)
    @Keep
    fun onCompleted(key: String?)
    @Keep
    fun onPlay()
    @Keep
    fun onPause()
    @Keep
    fun onSeek(positionMs: Long)
    @Keep
    fun onBufferingStart()
    @Keep
    fun onBufferingEnd()
    @Keep
    fun onBufferingUpdate(bufferedMs: Long)
    @Keep
    fun onPipStart()
    @Keep
    fun onPipStop()
    @Keep
    fun onChangedSize(width: Int, height: Int, key: String?)
    
    @Keep
    fun onError(errorCode: String, errorMessage: String, errorDetails: String)
}
