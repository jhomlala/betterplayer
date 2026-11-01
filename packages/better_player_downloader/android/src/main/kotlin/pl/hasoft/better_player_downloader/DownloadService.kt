package pl.hasoft.better_player_downloader

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.database.StandaloneDatabaseProvider
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.datasource.cache.SimpleCache
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadNotificationHelper
import androidx.media3.exoplayer.offline.DownloadService as Media3DownloadService
import androidx.media3.exoplayer.scheduler.Scheduler
import pl.hasoft.better_player.BetterPlayerCache
import java.util.concurrent.Executors

@OptIn(UnstableApi::class)
class DownloadService : Media3DownloadService(
    FOREGROUND_NOTIFICATION_ID,
    DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
    CHANNEL_ID,
    R.string.better_player_downloader_channel_name,
    R.string.better_player_downloader_channel_description,
) {
    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel(this)
    }

    override fun getDownloadManager(): DownloadManager = manager(applicationContext)

    override fun getScheduler(): Scheduler? = null

    override fun getForegroundNotification(
        downloads: MutableList<Download>,
        notMetRequirements: Int,
    ): Notification = notificationHelper(applicationContext).buildProgressNotification(
        this,
        R.drawable.better_player_downloader_icon,
        null,
        null,
        downloads,
        notMetRequirements,
    )

    companion object {
        const val CHANNEL_ID = "better_player_downloads"

        /**
         * Budget of the cache shared with the player. The first component that
         * creates the cache sets the evictor, so keep this value equal to the
         * `preCacheSize` used by [pl.hasoft.better_player.BetterPlayerCache].
         */
        const val CACHE_BUDGET_BYTES = 3L * 1024 * 1024 * 1024

        private const val FOREGROUND_NOTIFICATION_ID = 1

        /** Media3 needs the channel before the first `startForeground` call. */
        fun ensureNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL_ID) != null) return
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    context.getString(R.string.better_player_downloader_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description =
                        context.getString(R.string.better_player_downloader_channel_description)
                },
            )
        }

        @Volatile
        private var downloadManager: DownloadManager? = null

        @Volatile
        private var helper: DownloadNotificationHelper? = null

        /**
         * Returns the cache used by the player. Downloads must land in the same
         * folder, because a segment is playable offline only when the player
         * reads it from the cache it already knows.
         */
        fun cache(context: Context): SimpleCache {
            val applicationContext = context.applicationContext
            return BetterPlayerCache.createCache(applicationContext, CACHE_BUDGET_BYTES)
                ?: error("Better player cache is not available")
        }

        fun manager(context: Context): DownloadManager = downloadManager ?: synchronized(this) {
            downloadManager ?: DownloadManager(
                context,
                StandaloneDatabaseProvider(context),
                cache(context),
                DefaultHttpDataSource.Factory(),
                Executors.newFixedThreadPool(4),
            ).also {
                it.maxParallelDownloads = 3
                it.resumeDownloads()
                downloadManager = it
            }
        }

        fun notificationHelper(context: Context): DownloadNotificationHelper =
            helper ?: synchronized(this) {
                helper ?: DownloadNotificationHelper(context, CHANNEL_ID).also { helper = it }
            }
    }
}
