package pl.hasoft.better_player

import android.content.Context
import android.net.Uri
import android.util.Log
import pl.hasoft.better_player.DataSourceUtils.isHTTP
import pl.hasoft.better_player.DataSourceUtils.getUserAgent
import pl.hasoft.better_player.DataSourceUtils.getDataSourceFactory
import androidx.work.WorkerParameters
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.cache.CacheWriter
import androidx.work.Worker
import androidx.media3.datasource.DataSpec
import androidx.media3.datasource.HttpDataSource.HttpDataSourceException
import java.lang.Exception
import java.util.*

/**
 * Cache worker which download part of video and save in cache for future usage. The cache job
 * will be executed in work manager.
 */
@OptIn(UnstableApi::class)
class CacheWorker(
    private val context: Context,
    params: WorkerParameters
) : Worker(context, params) {
    private var cacheWriter: CacheWriter? = null
    private var lastCacheReportIndex = 0
    override fun doWork(): Result {
        try {
            val data = inputData
            val url = data.getString(BetterPlayerPlugin.URL_PARAMETER)
            val cacheKey = data.getString(BetterPlayerPlugin.CACHE_KEY_PARAMETER)
            val preCacheSize = data.getLong(BetterPlayerPlugin.PRE_CACHE_SIZE_PARAMETER, 0)
            val maxCacheSize = data.getLong(BetterPlayerPlugin.MAX_CACHE_SIZE_PARAMETER, 0)
            val maxCacheFileSize = data.getLong(BetterPlayerPlugin.MAX_CACHE_FILE_SIZE_PARAMETER, 0)
            if (url == null || url.contains(".m3u8", ignoreCase = true) ||
                url.contains(".m3u", ignoreCase = true) ||
                url.contains(".mpd", ignoreCase = true)
            ) {
                BetterPlayerPlugin.log(Log.WARN, TAG, "Pre-caching HLS and DASH streams is not supported.")
                return Result.success()
            }
            val headers: MutableMap<String, String> = HashMap()
            for (key in data.keyValueMap.keys) {
                if (key.contains(BetterPlayerPlugin.HEADER_PARAMETER)) {
                    val keySplit = key.split(BetterPlayerPlugin.HEADER_PARAMETER).toTypedArray()[1]
                    headers[keySplit] = data.keyValueMap[key] as String
                }
            }
            val uri = Uri.parse(url)
            if (isHTTP(uri)) {
                val userAgent = getUserAgent(headers)
                val dataSourceFactory = getDataSourceFactory(userAgent, headers)
                var dataSpec = androidx.media3.datasource.DataSpec(uri, 0, preCacheSize)
                if (cacheKey != null && cacheKey.isNotEmpty()) {
                    dataSpec = dataSpec.buildUpon().setKey(cacheKey).build()
                }
                val cacheDataSourceFactory = CacheDataSourceFactory(
                    context,
                    maxCacheSize,
                    maxCacheFileSize,
                    dataSourceFactory
                )
                var lastReportedBytes = 0L
                cacheWriter = CacheWriter(
                    cacheDataSourceFactory.createDataSource(),
                    dataSpec,
                    null
                ) { _: Long, bytesCached: Long, _: Long ->
                    val completedFraction = if (preCacheSize > 0) {
                        (bytesCached.toDouble() / preCacheSize.toDouble()).coerceIn(0.0, 1.0)
                    } else {
                        0.0
                    }
                    val completedData = (completedFraction * 100.0)

                    val throttleThreshold = (preCacheSize / 100).coerceAtLeast(1L)
                    if (bytesCached - lastReportedBytes >= throttleThreshold || bytesCached >= preCacheSize) {
                        lastReportedBytes = bytesCached
                        BetterPlayerApi.reportPreCacheProgress(
                            url ?: "",
                            cacheKey,
                            completedFraction,
                            bytesCached,
                            preCacheSize
                        )
                    }

                    if (completedData >= lastCacheReportIndex * 10) {
                        lastCacheReportIndex += 1
                        Log.d(TAG, "Completed pre cache of $url: ${lastCacheReportIndex * 10}%")
                    }
                }
                cacheWriter?.cache()
            } else {
                return Result.failure()
            }
        } catch (exception: Exception) {
            Log.e(TAG, "Pre cache exception", exception)
            // If it's HttpDataSourceException or EOFException (file smaller than preCacheSize) we can consider it success
            return if (exception is HttpDataSourceException || exception is java.io.EOFException) {
                Result.success()
            } else {
                Result.failure()
            }
        }
        return Result.success()
    }

    override fun onStopped() {
        try {
            cacheWriter?.cancel()
            super.onStopped()
        } catch (exception: Exception) {
        }
    }

    companion object {
        private const val TAG = "CacheWorker"
    }
}