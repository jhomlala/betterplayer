package pl.hasoft.better_player

import androidx.annotation.Keep

@Keep
interface BetterPlayerCallback {
    @Keep
    fun onEvent(event: String, parameters: String) // Using JSON string or similar for parameters to avoid complex JNI Map bindings
    
    @Keep
    fun onError(errorCode: String, errorMessage: String, errorDetails: String)
}
