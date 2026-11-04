package pl.hasoft.better_player.download

import android.content.Context
import android.os.StatFs
import android.util.Log
import androidx.media3.common.util.UnstableApi
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.cache.NoOpCacheEvictor
import androidx.media3.datasource.cache.SimpleCache
import java.io.File
import java.lang.Exception

/**
 * Holds the cache that stores finished downloads.
 *
 * Media3 allows one [SimpleCache] per directory, so the instance lives here.
 * The directory is inside [Context.getFilesDir] because Android deletes
 * cache directories when the device runs out of space. Downloads must survive
 * that cleanup.
 */
@UnstableApi
object PlayerDownloadCache {
  private const val TAG = "BPD"
  private const val DIRECTORY_NAME = "betterPlayerDownloads"

  /** Minimum free space that a download needs to start. */
  private const val MIN_FREE_BYTES = 100L * 1024 * 1024

  @Volatile
  private var instance: SimpleCache? = null

  @Volatile
  private var database: StandaloneDatabaseProvider? = null

  /**
   * Returns the database provider shared by the cache and the download index.
   *
   * Media3 expects one provider per process. Two providers over the same
   * database file lock each other.
   */
  fun database(context: Context): StandaloneDatabaseProvider {
    database?.let { return it }
    synchronized(PlayerDownloadCache::class.java) {
      database?.let { return it }
      val created = StandaloneDatabaseProvider(context.applicationContext)
      database = created
      return created
    }
  }

  fun create(context: Context): SimpleCache {
    instance?.let { return it }
    synchronized(PlayerDownloadCache::class.java) {
      instance?.let { return it }
      val created = SimpleCache(
        directory(context),
        NoOpCacheEvictor(),
        database(context),
      )
      instance = created
      return created
    }
  }

  fun directory(context: Context): File =
    File(context.applicationContext.filesDir, DIRECTORY_NAME)

  /**
   * Returns the free bytes on the volume that stores the downloads.
   */
  fun freeBytes(context: Context): Long {
    val directory = directory(context)
    directory.mkdirs()
    return StatFs(directory.path).availableBytes
  }

  /**
   * Whether the device has enough free space to start a download.
   *
   * The engine does not report the final size of a DASH manifest before the
   * download starts, so the check uses a minimum. A download that starts with
   * less space fails when the disk is full.
   */
  fun hasSpaceForDownload(context: Context): Boolean =
    freeBytes(context) >= MIN_FREE_BYTES

  fun release() {
    val current = instance ?: return
    instance = null
    try {
      current.release()
    } catch (exception: Exception) {
      Log.w(TAG, "download cache release failed", exception)
    }
    database = null
  }
}
