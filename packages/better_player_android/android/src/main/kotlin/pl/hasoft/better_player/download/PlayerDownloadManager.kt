package pl.hasoft.better_player.download

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadRequest
import androidx.media3.exoplayer.offline.DownloadService as Media3DownloadService
import java.io.IOException
import java.lang.Exception
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Holds the [DownloadManager] shared by the service and the player.
 *
 * Media3 requires one manager per download index, so the instance lives here.
 */
@UnstableApi
object PlayerDownloadManager {
  private const val TAG = "BPD"
  private const val DOWNLOAD_THREADS = 4
  private const val PROGRESS_INTERVAL_MS = 1000L

  /** Stop reason for a download that the user paused. */
  const val STOP_REASON_USER = 1

  @Volatile
  private var instance: DownloadManager? = null

  @Volatile
  private var executor: ExecutorService? = null

  private val mainHandler = Handler(Looper.getMainLooper())

  /** Last state and byte count sent for each download. */
  private val lastSample = HashMap<String, Pair<Int, Long>>()

  @Volatile
  private var sampling = false

  private val sampleRunnable = object : Runnable {
    override fun run() {
      val manager = instance
      if (manager == null) {
        sampling = false
        return
      }
      val active = manager.currentDownloads.filter { isActive(it) }
      for (download in active) {
        sendSample(download)
      }
      if (active.isEmpty()) {
        sampling = false
        lastSample.clear()
        return
      }
      mainHandler.postDelayed(this, PROGRESS_INTERVAL_MS)
    }
  }

  private fun isActive(download: Download): Boolean =
    download.state == Download.STATE_QUEUED ||
      download.state == Download.STATE_DOWNLOADING

  /**
   * Sends [download] when its state or its byte count changed.
   *
   * The download manager does not report progress, so the samples come from
   * this poll.
   */
  private fun sendSample(download: Download) {
    val url = download.request.uri.toString()
    val sample = download.state to download.bytesDownloaded
    if (lastSample[url] == sample) {
      return
    }
    lastSample[url] = sample
    PlayerDownloadListener.emitSample(download)
  }

  /** Starts the progress poll when a download is active. */
  private fun startSampling() {
    if (sampling) {
      return
    }
    sampling = true
    mainHandler.postDelayed(sampleRunnable, PROGRESS_INTERVAL_MS)
  }

  fun create(context: Context): DownloadManager {
    instance?.let { return it }
    synchronized(PlayerDownloadManager::class.java) {
      instance?.let { return it }
      val appContext = context.applicationContext
      val pool = Executors.newFixedThreadPool(DOWNLOAD_THREADS)
      val created = DownloadManager(
        appContext,
        PlayerDownloadCache.database(appContext),
        PlayerDownloadCache.create(appContext),
        PlayerDownloadHeaders.factory(appContext),
        pool,
      )
      executor = pool
      instance = created
      created.addListener(PlayerDownloadListener)
      startSampling()
      return created
    }
  }

  /**
   * Queues [request]. The download runs in [PlayerDownloadService].
   */
  fun add(context: Context, request: DownloadRequest) {
    Media3DownloadService.sendAddDownload(
      context,
      PlayerDownloadService::class.java,
      request,
      true,
    )
    startSampling()
  }

  /**
   * Removes the download and its files. A running download stops first.
   */
  fun remove(context: Context, id: String) {
    PlayerDownloadHeaders.unregister(id)
    Media3DownloadService.sendRemoveDownload(
      context,
      PlayerDownloadService::class.java,
      id,
      true,
    )
  }

  /**
   * Stops [id] and keeps the downloaded bytes.
   *
   * Media3 has no pause for one download. A stop reason has the same effect.
   */
  fun stop(context: Context, id: String) {
    Media3DownloadService.sendSetStopReason(
      context,
      PlayerDownloadService::class.java,
      id,
      STOP_REASON_USER,
      true,
    )
  }

  /**
   * Resumes [id] after [stop].
   */
  fun resume(context: Context, id: String) {
    Media3DownloadService.sendSetStopReason(
      context,
      PlayerDownloadService::class.java,
      id,
      Download.STOP_REASON_NONE,
      true,
    )
    startSampling()
  }

  /**
   * Returns the stored state of [id], or null when no download has that id.
   */
  fun find(context: Context, id: String): Download? = try {
    create(context).downloadIndex.getDownload(id)
  } catch (exception: IOException) {
    Log.w(TAG, "download lookup failed id=$id", exception)
    null
  } catch (exception: RuntimeException) {
    Log.w(TAG, "download lookup failed id=$id", exception)
    null
  }

  fun release() {
    mainHandler.removeCallbacks(sampleRunnable)
    sampling = false
    lastSample.clear()
    PlayerDownloadHeaders.clear()
    val current = instance
    val pool = executor
    instance = null
    executor = null
    try {
      current?.release()
    } catch (exception: Exception) {
      Log.w(TAG, "download manager release failed", exception)
    }
    pool?.shutdown()
  }
}
