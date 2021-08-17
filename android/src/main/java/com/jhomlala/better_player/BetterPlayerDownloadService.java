package com.jhomlala.better_player;

import android.app.Notification;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.exoplayer2.database.ExoDatabaseProvider;
import com.google.android.exoplayer2.offline.Download;
import com.google.android.exoplayer2.offline.DownloadManager;
import com.google.android.exoplayer2.offline.DownloadService;
import com.google.android.exoplayer2.scheduler.PlatformScheduler;
import com.google.android.exoplayer2.ui.DownloadNotificationHelper;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSourceFactory;
import com.google.android.exoplayer2.upstream.cache.Cache;
import com.google.android.exoplayer2.upstream.cache.LeastRecentlyUsedCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.NoOpCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.SimpleCache;
import com.google.android.exoplayer2.util.NotificationUtil;
import com.google.android.exoplayer2.util.Util;

import java.io.File;
import java.util.LinkedList;
import java.util.List;
import java.util.concurrent.Executor;

/**
 * A service for downloading media.
 */
public class BetterPlayerDownloadService extends DownloadService {

    private static final int JOB_ID = 1;
    private static final int FOREGROUND_NOTIFICATION_ID = 1;

    private static DownloadManager downloadManager;
    private static Cache downloadCache;
    private static ExoDatabaseProvider databaseProvider;

    public BetterPlayerDownloadService() {
        super(
                FOREGROUND_NOTIFICATION_ID,
                DEFAULT_FOREGROUND_NOTIFICATION_UPDATE_INTERVAL,
                "better_player_download_channel",
                R.string.exo_download_notification_channel_name,
                /* channelDescriptionResourceId= */ 0);
    }

    @Override
    @NonNull
    protected DownloadManager getDownloadManager() {
        return getDownloadManager(this);
    }

    @Override
    protected PlatformScheduler getScheduler() {
        return null;
//        return Util.SDK_INT >= 21 ? new PlatformScheduler(this, JOB_ID) : null;
    }

    @Override
    @NonNull
    protected Notification getForegroundNotification(@NonNull List<Download> downloads) {
        return new DownloadNotificationHelper(this, "better_player_download_channel").buildProgressNotification(this,
                R.drawable.exo_notification_small_icon,
                null,
                "whatever" ,
                downloads);
    }

    static DownloadManager getDownloadManager(Context context) {
        if(downloadManager == null) {
            downloadManager = new DownloadManager(
                    context,
                    getDatabaseProvider(context),
                    getDownloadCache(context),
                    new DefaultHttpDataSource.Factory(),
                    Runnable::run);
            downloadManager.setMaxParallelDownloads(3);
        }

        return downloadManager;
    }

    static Cache getDownloadCache(Context context) {
        if(downloadCache == null) {
            downloadCache = new SimpleCache(
//                TODO: change to a non cache dir
                    new File(context.getCacheDir(), "BetterPlayerDownloads"),
                    new NoOpCacheEvictor(),
                    getDatabaseProvider(context));
        }

        return downloadCache;
    }

    static ExoDatabaseProvider getDatabaseProvider(Context context) {
        if(databaseProvider == null) {
           databaseProvider = new ExoDatabaseProvider(context);
        }

        return databaseProvider;
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
}
