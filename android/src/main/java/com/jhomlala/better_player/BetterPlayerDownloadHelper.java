package com.jhomlala.better_player;

import android.app.Notification;
import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.exoplayer2.DefaultRenderersFactory;
import com.google.android.exoplayer2.Format;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.database.ExoDatabaseProvider;
import com.google.android.exoplayer2.drm.DrmSession;
import com.google.android.exoplayer2.drm.DrmSessionEventListener;
import com.google.android.exoplayer2.drm.OfflineLicenseHelper;
import com.google.android.exoplayer2.offline.Download;
import com.google.android.exoplayer2.offline.DownloadCursor;
import com.google.android.exoplayer2.offline.DownloadHelper;
import com.google.android.exoplayer2.offline.DownloadManager;
import com.google.android.exoplayer2.offline.DownloadRequest;
import com.google.android.exoplayer2.offline.DownloadService;
import com.google.android.exoplayer2.scheduler.PlatformScheduler;
import com.google.android.exoplayer2.source.TrackGroup;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.trackselection.MappingTrackSelector;
import com.google.android.exoplayer2.ui.DownloadNotificationHelper;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.upstream.cache.Cache;
import com.google.android.exoplayer2.upstream.cache.NoOpCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.SimpleCache;
import com.google.android.exoplayer2.util.Assertions;
import com.google.android.exoplayer2.util.Util;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.EventChannel;

public class BetterPlayerDownloadHelper {
    private static final String DOWNLOAD_FOLDER_NAME = "downloads";
    private static final String TAG = "BetterPlayerDownloader";

    @Nullable
    private static DownloadManager downloadManager;
    @Nullable
    private static Cache downloadCache;
    @Nullable
    private static ExoDatabaseProvider databaseProvider;

    @NonNull
    static synchronized DownloadManager getDownloadManager(Context context) {
        if (downloadManager == null) {
            downloadManager = new DownloadManager(
                    context,
                    getDatabaseProvider(context),
                    getDownloadCache(context),
                    new DefaultHttpDataSource.Factory(),
                    Runnable::run);
//            TODO: make configurable?
            downloadManager.setMaxParallelDownloads(3);
        }

        return downloadManager;
    }

    @NonNull
    static synchronized Cache getDownloadCache(Context context) {
        if (downloadCache == null) {
            downloadCache = new SimpleCache(
                    new File(context.getFilesDir(), DOWNLOAD_FOLDER_NAME),
                    new NoOpCacheEvictor(),
                    getDatabaseProvider(context));
        }

        return downloadCache;
    }

    @NonNull
    static synchronized ExoDatabaseProvider getDatabaseProvider(Context context) {
        if (databaseProvider == null) {
            databaseProvider = new ExoDatabaseProvider(context);
        }

        return databaseProvider;
    }

    static void removeDownload(Context context, String url) {
        DownloadService.sendRemoveDownload(
                context,
                BetterPlayerDownloadService.class,
                url,
                false);
    }

    @Nullable
    static Download getDownload(Context context, String url) {
        try {
            return getDownloadManager(context)
                    .getDownloadIndex()
                    .getDownload(url);
        } catch (IOException e) {
            return null;
        }
    }

    @NonNull
    static List<Download> listDownloads(Context context) throws IOException {
        List<Download> downloads = new LinkedList<>();

        DownloadCursor downloadCursor = getDownloadManager(context).getDownloadIndex().getDownloads();
        if (downloadCursor.moveToFirst()) {
            do {
                downloads.add(downloadCursor.getDownload());
            } while (downloadCursor.moveToNext());
        }

        return downloads;
    }

    static void addDownload(Context context, MediaItem mediaItem, EventChannel.EventSink eventSink, String downloadData, @Nullable Runnable onDone) {
        DownloadHelper downloadHelper = DownloadHelper.forMediaItem(context,
                mediaItem,
                new DefaultRenderersFactory(context),
//                TODO: probably want to use DataSourceUtils.getDataSourceFactory?
                new DefaultDataSourceFactory(context));

        downloadHelper.prepare(new DownloadHelper.Callback() {
            @Override
            public void onPrepared(DownloadHelper helper) {
                String url = Assertions.checkNotNull(mediaItem.playbackProperties).uri.toString();
                String licenseUrl = null;
                Map<String, String> drmHeaders = new HashMap<>();
                if (mediaItem.playbackProperties.drmConfiguration != null) {
                    drmHeaders = mediaItem.playbackProperties.drmConfiguration.requestHeaders;
                    if (mediaItem.playbackProperties.drmConfiguration.licenseUri != null) {
                        licenseUrl = mediaItem.playbackProperties.drmConfiguration.licenseUri.toString();
                    }
                }

                DownloadRequest downloadRequest = helper.getDownloadRequest(url, Util.getUtf8Bytes(downloadData));

                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.JELLY_BEAN_MR2) {
                    Log.e(TAG, "Protected content not supported on API levels below 18");
                } else if (licenseUrl != null) {
                    OfflineLicenseHelper offlineLicenseHelper = OfflineLicenseHelper.newWidevineInstance(
                            licenseUrl,
                            false,
                            new DefaultHttpDataSource.Factory().setDefaultRequestProperties(drmHeaders),
                            drmHeaders,
                            new DrmSessionEventListener.EventDispatcher());

                    for (int periodIndex = 0; periodIndex < helper.getPeriodCount(); periodIndex++) {
                        MappingTrackSelector.MappedTrackInfo mappedTrackInfo = helper.getMappedTrackInfo(periodIndex);
                        for (int rendererIndex = 0; rendererIndex < mappedTrackInfo.getRendererCount(); rendererIndex++) {
                            TrackGroupArray trackGroups = mappedTrackInfo.getTrackGroups(rendererIndex);
                            for (int trackGroupIndex = 0; trackGroupIndex < trackGroups.length; trackGroupIndex++) {
                                TrackGroup trackGroup = trackGroups.get(trackGroupIndex);
                                for (int formatIndex = 0; formatIndex < trackGroup.length; formatIndex++) {
                                    Format format = trackGroup.getFormat(formatIndex);
                                    if (format.drmInitData != null) {
                                        try {
                                            byte[] keySetId = offlineLicenseHelper.downloadLicense(format);
                                            downloadRequest = downloadRequest.copyWithKeySetId(keySetId);
                                        } catch (DrmSession.DrmSessionException e) {
                                            Log.e(TAG, "Failed to fetch offline license");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                DownloadService.sendAddDownload(context, BetterPlayerDownloadService.class, downloadRequest, false);

                Handler handler = new Handler(Looper.getMainLooper());

                new Timer().schedule(new TimerTask() {
                    @Override
                    public void run() {
                        Download curr = getDownload(context, url);
                        if (curr != null && curr.state == Download.STATE_COMPLETED) {
                            cancel();
                            handler.post(() -> {
                                eventSink.success(100f);
                                eventSink.endOfStream();
                            });
                        }

                        // getCurrentDownloads is used because it stores much more accurate progress
                        // percentage
                        List<Download> downloads = getDownloadManager(context).getCurrentDownloads();
                        Download download = null;
                        for (Download d : downloads) {
                            if (d.request.id.equals(url)) {
                                download = d;
                                break;
                            }
                        }
                        if (download == null)
                            return;

                        float progress = download.getPercentDownloaded();
                        handler.post(() -> eventSink.success(progress));
                    }
                }, 0, 1000);


                if (onDone != null) {
                    onDone.run();
                }
            }

            @Override
            public void onPrepareError(DownloadHelper helper, IOException e) {
//                TODO: inform about better_player about failure
                Log.e(TAG, "Failed prepare");
            }
        });
    }

    private static class BetterPlayerDownloadService extends DownloadService {

        private static final int JOB_ID = 1;
        private static final int FOREGROUND_NOTIFICATION_ID = 1;
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