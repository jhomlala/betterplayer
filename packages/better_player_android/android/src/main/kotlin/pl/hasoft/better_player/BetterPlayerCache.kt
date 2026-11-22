package pl.hasoft.better_player

import android.content.Context
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.datasource.cache.LeastRecentlyUsedCacheEvictor
import androidx.media3.database.ExoDatabaseProvider
import java.io.File
import java.lang.Exception

@OptIn(UnstableApi::class)
object BetterPlayerCache {
    const val DEFAULT_MAX_CACHE_SIZE = 100L * 1024L * 1024L
    const val DEFAULT_MAX_CACHE_FILE_SIZE = 10L * 1024L * 1024L
    private const val CACHE_DIR_NAME = "betterPlayerCache"

    @Volatile
    private var instance: SimpleCache? = null

    @Synchronized
    fun createCache(context: Context, cacheFileSize: Long): SimpleCache? {
        if (instance == null) {
            val effectiveCacheSize =
                if (cacheFileSize > 0) cacheFileSize else DEFAULT_MAX_CACHE_SIZE
            val appContext = context.applicationContext ?: context
            instance = SimpleCache(
                File(appContext.cacheDir, CACHE_DIR_NAME),
                LeastRecentlyUsedCacheEvictor(effectiveCacheSize),
                ExoDatabaseProvider(appContext)
            )
        }
        return instance
    }

    @JvmStatic
    @Synchronized
    fun releaseCache() {
        try {
            instance?.release()
            instance = null
        } catch (exception: Exception) {
            Log.e("BetterPlayerCache", "Failed to release cache", exception)
        }
    }

    @JvmOverloads
    @JvmStatic
    @Synchronized
    fun clearCache(context: Context? = null) {
        try {
            val cache = instance
            if (cache != null) {
                for (key in cache.keys.toList()) {
                    cache.removeResource(key)
                }
            } else if (context != null) {
                val cacheDir = File(context.cacheDir, CACHE_DIR_NAME)
                deleteDirectory(cacheDir)
            }
        } catch (exception: Exception) {
            Log.e("BetterPlayerCache", "Failed to clear cache", exception)
        }
    }

    private fun deleteDirectory(file: File) {
        if (file.isDirectory) {
            val entries = file.listFiles()
            if (entries != null) {
                for (entry in entries) {
                    deleteDirectory(entry)
                }
            }
        }
        if (file.exists() && !file.delete()) {
            Log.w("BetterPlayerCache", "Failed to delete cache file: ${file.absolutePath}")
        }
    }
}