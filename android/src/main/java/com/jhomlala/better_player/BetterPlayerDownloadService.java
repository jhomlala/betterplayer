package com.jhomlala.better_player;

import android.app.Notification;

import androidx.annotation.NonNull;

import com.google.android.exoplayer2.offline.Download;
import com.google.android.exoplayer2.offline.DownloadManager;
import com.google.android.exoplayer2.offline.DownloadService;
import com.google.android.exoplayer2.scheduler.PlatformScheduler;
import com.google.android.exoplayer2.ui.DownloadNotificationHelper;

import java.util.List;

public class BetterPlayerDownloadService extends DownloadService {

    private static final int JOB_ID = 1;
    private static final int FOREGROUND_NOTIFICATION_ID = 20772078;
    private static final String DOWNLOAD_CHANNEL_NAME = "better_player_download_channel";


    public BetterPlayerDownloadService() {
        super(
                FOREGROUND_NOTIFICATION_ID,
                DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
                DOWNLOAD_CHANNEL_NAME,
                R.string.exo_download_notification_channel_name,
                0);
    }

    @Override
    @NonNull
    protected DownloadManager getDownloadManager() {
        return BetterPlayerDownloadHelper.getDownloadManager(this);
    }

    @Override
    protected PlatformScheduler getScheduler() {
        return null;
//        TODO: figure out what PlatformScheduler actually does
//        return Util.SDK_INT >= 21 ? new PlatformScheduler(this, JOB_ID) : null;
    }

    @Override
    @NonNull
    protected Notification getForegroundNotification(@NonNull List<Download> downloads) {
        return new DownloadNotificationHelper(this, DOWNLOAD_CHANNEL_NAME).buildProgressNotification(this,
                android.R.drawable.stat_sys_download_done,
                null,
//                TODO: accept custom message?
                null,
                downloads);
    }
}


//    /**
//     * Creates and displays notifications for downloads when they complete or fail.
//     *
//     * <p>This helper will outlive the lifespan of a single instance of {@link DemoDownloadService}.
//     * It is static to avoid leaking the first {@link DemoDownloadService} instance.
//     */
//    private static final class TerminalStateNotificationHelper implements DownloadManager.Listener {
//
//        private final Context context;
//        private final DownloadNotificationHelper notificationHelper;
//
//        private int nextNotificationId;
//
//        public TerminalStateNotificationHelper(
//                Context context, DownloadNotificationHelper notificationHelper, int firstNotificationId) {
//            this.context = context.getApplicationContext();
//            this.notificationHelper = notificationHelper;
//            nextNotificationId = firstNotificationId;
//        }
//
//        @Override
//        public void onDownloadChanged(
//                DownloadManager downloadManager, Download download, @Nullable Exception finalException) {
////            Notification notification;
////            if (download.state == Download.STATE_COMPLETED) {
////                notification =
////                        notificationHelper.buildDownloadCompletedNotification(
////                                context,
////                                R.drawable.ic_download_done,
////                                /* contentIntent= */ null,
////                                Util.fromUtf8Bytes(download.request.data));
////            } else if (download.state == Download.STATE_FAILED) {
////                notification =
////                        notificationHelper.buildDownloadFailedNotification(
////                                context,
////                                R.drawable.ic_download_done,
////                                /* contentIntent= */ null,
////                                Util.fromUtf8Bytes(download.request.data));
////            } else {
////                return;
////            }
////            NotificationUtil.setNotification(context, nextNotificationId++, notification);
//        }
//    }