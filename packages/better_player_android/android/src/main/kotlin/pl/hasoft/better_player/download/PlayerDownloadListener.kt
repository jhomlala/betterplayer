package pl.hasoft.better_player.download

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager

/**
 * Sends the state of each download to the Flutter side.
 *
 * [DownloadManager.Listener] reports state changes only, so
 * [PlayerDownloadManager] also samples the live downloads every second and
 * calls [emitSample]. The events go to the main thread before the channel
 * call, because Flutter requires the platform thread for outbound calls.
 */
@UnstableApi
object PlayerDownloadListener : DownloadManager.Listener {
  private const val TAG = "BPD"

  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onDownloadChanged(
    downloadManager: DownloadManager,
    download: Download,
    finalException: Exception?,
  ) {
    val state = download.state
    val error = finalException?.message
    Log.d(
      TAG,
      "onDownloadChanged state=$state bytes=${download.bytesDownloaded} " +
        "percent=${download.percentDownloaded} error=$error",
    )
    if (state == Download.STATE_REMOVING) {
      Log.d(TAG, "skip removing event url=${download.request.uri}")
      return
    }
    emit(download, error)
  }

  /**
   * Sends one progress sample of [download]. The caller decides the interval.
   */
  fun emitSample(download: Download) {
    emit(download, null)
  }

  private fun emit(download: Download, error: String?) {
    mainHandler.post {
      PlayerDownloadChannel.emit(
        mapOf(
          "url" to download.request.uri.toString(),
          "state" to download.state,
          "bytesDownloaded" to download.bytesDownloaded,
          "totalBytes" to download.contentLength,
          "error" to error,
        ),
      )
    }
  }
}
