package pl.hasoft.better_player.download

import android.content.Context
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.cache.CacheDataSource
import androidx.media3.exoplayer.offline.Download

/**
 * Reads a completed download during playback.
 *
 * The download cache is separate from the streaming cache. The player reads
 * from it only when the whole media is stored, so a partial download does not
 * change the playback behaviour.
 */
@UnstableApi
object PlayerDownloadPlayback {
  /**
   * Returns true when [url] is stored and plays without network access.
   */
  fun isDownloaded(context: Context, url: String): Boolean =
    PlayerDownloadManager.find(context, url)?.state == Download.STATE_COMPLETED

  /**
   * Wraps [upstream] with a read-only cache that serves the stored segments.
   */
  fun wrap(context: Context, upstream: DataSource.Factory): DataSource.Factory =
    CacheDataSource.Factory()
      .setCache(PlayerDownloadCache.create(context))
      .setUpstreamDataSourceFactory(upstream)
      .setCacheWriteDataSinkFactory(null)
      .setFlags(CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR)
}
