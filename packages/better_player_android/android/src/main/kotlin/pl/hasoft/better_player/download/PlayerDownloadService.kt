package pl.hasoft.better_player.download

import android.app.Notification
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadManager
import androidx.media3.exoplayer.offline.DownloadNotificationHelper
import androidx.media3.exoplayer.offline.DownloadService
import androidx.media3.exoplayer.scheduler.Scheduler
import pl.hasoft.better_player.R

/**
 * Runs downloads in the foreground and keeps them alive when the app leaves
 * the screen.
 *
 * The notification channel comes from the base constructor. A service that
 * calls startForeground without a channel does not process the add request,
 * and Media3 fails without an error.
 */
@UnstableApi
class PlayerDownloadService : DownloadService(
  FOREGROUND_NOTIFICATION_ID,
  DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
  CHANNEL_ID,
  R.string.better_player_download_channel_name,
  R.string.better_player_download_channel_description,
) {
  override fun getDownloadManager(): DownloadManager = PlayerDownloadManager.create(this)

  override fun getScheduler(): Scheduler? = null

  override fun getForegroundNotification(
    downloads: MutableList<Download>,
    notificationUpdateReason: Int,
  ): Notification = DownloadNotificationHelper(this, CHANNEL_ID)
    .buildProgressNotification(
      this,
      android.R.drawable.stat_sys_download,
      null,
      null,
      downloads,
      notificationUpdateReason,
    )

  companion object {
    const val CHANNEL_ID = "better_player_downloads"
    private const val FOREGROUND_NOTIFICATION_ID = 1
  }
}
