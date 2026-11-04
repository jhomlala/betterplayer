package pl.hasoft.better_player.download

import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Sends the download events to Flutter over the plugin method channel.
 *
 * The channel needs no binding generation, and it is available as soon as the
 * plugin attaches to the engine.
 */
object PlayerDownloadChannel {
  private const val TAG = "BPD"

  private var channel: MethodChannel? = null

  fun attach(channel: MethodChannel?) {
    this.channel = channel
  }

  fun emit(event: Map<String, Any?>) {
    val current = channel
    if (current == null) {
      Log.w(TAG, "download event without channel url=${event["url"]}")
      return
    }
    Log.d(TAG, "emit event url=${event["url"]} state=${event["state"]}")
    current.invokeMethod("downloadProgress", event)
  }
}
