package pl.hasoft.better_player.download

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.TrackSelectionParameters
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.offline.DownloadHelper
import androidx.media3.exoplayer.offline.DownloadRequest
import java.io.IOException

/**
 * Builds a [DownloadRequest] from a manifest.
 *
 * A raw [DownloadRequest] with only a URI lets Media3 download every
 * representation of a DASH or HLS manifest. This factory prepares the manifest
 * and selects one video track, so the download stays at a usable size.
 *
 * The selection uses [TrackSelectionParameters] instead of track indexes. This
 * follows the Media3 API and works with manifests that have several periods.
 */
@UnstableApi
class PlayerDownloadRequestFactory(private val context: Context) {
  private val mainHandler = Handler(Looper.getMainLooper())

  /**
   * Prepares [uri] and calls [onResult] on the main thread.
   *
   * [onResult] receives a request on success. It receives null and an error
   * message on failure.
   */
  fun create(
    id: String,
    uri: Uri,
    mimeType: String?,
    headers: Map<String, String> = emptyMap(),
    maxVideoHeight: Int = DEFAULT_MAX_VIDEO_HEIGHT,
    onResult: (DownloadRequest?, String?) -> Unit,
  ) {
    val builder = MediaItem.Builder().setUri(uri)
    mimeType?.let { builder.setMimeType(it) }
    val mediaItem = builder.build()
    PlayerDownloadHeaders.register(uri.toString(), headers)
    val helper = DownloadHelper.forMediaItem(
      context,
      mediaItem,
      manifestDataSource(context, headers),
    )
    mainHandler.post {
      helper.prepare(
        object : DownloadHelper.Callback {
          override fun onPrepared(helper: DownloadHelper, mediaItemTransitioned: Boolean) {
            val request = buildRequest(helper, id, maxVideoHeight, onResult)
            helper.release()
            request?.let { onResult(it, null) }
          }

          override fun onPrepareError(helper: DownloadHelper, exception: IOException) {
            helper.release()
            onResult(null, exception.message ?: exception.javaClass.simpleName)
          }
        },
      )
    }
  }

  private fun manifestDataSource(
    context: Context,
    headers: Map<String, String>,
  ): DefaultDataSource.Factory {
    val http = DefaultHttpDataSource.Factory()
    if (headers.isNotEmpty()) {
      http.setDefaultRequestProperties(headers)
    }
    return DefaultDataSource.Factory(context, http)
  }

  private fun buildRequest(
    helper: DownloadHelper,
    id: String,
    maxVideoHeight: Int,
    onResult: (DownloadRequest?, String?) -> Unit,
  ): DownloadRequest? = try {
    val selection = TrackSelectionParameters.Builder()
      .setMaxVideoSize(Int.MAX_VALUE, maxVideoHeight)
      .build()
    repeat(helper.periodCount) { period ->
      helper.addTrackSelection(period, selection)
    }
    helper.getDownloadRequest(id, null)
  } catch (exception: RuntimeException) {
    onResult(null, exception.message ?: exception.javaClass.simpleName)
    null
  }

  companion object {
    /**
     * No cap. The selection picks the highest resolution that the device
     * supports, which is one track, not all of them.
     */
    const val DEFAULT_MAX_VIDEO_HEIGHT = Int.MAX_VALUE
  }
}
