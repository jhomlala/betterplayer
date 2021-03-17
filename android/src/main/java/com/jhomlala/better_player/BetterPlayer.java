package com.jhomlala.better_player;

import static com.google.android.exoplayer2.Player.REPEAT_MODE_ALL;
import static com.google.android.exoplayer2.Player.REPEAT_MODE_OFF;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;
import android.view.Surface;

import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.ControlDispatcher;
import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.Format;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.Player.EventListener;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.audio.AudioAttributes;
import com.google.android.exoplayer2.drm.DefaultDrmSessionManager;
import com.google.android.exoplayer2.drm.DrmSessionManager;
import com.google.android.exoplayer2.drm.HttpMediaDrmCallback;
import com.google.android.exoplayer2.drm.DummyExoMediaDrm;
import com.google.android.exoplayer2.drm.FrameworkMediaDrm;
import com.google.android.exoplayer2.drm.UnsupportedDrmException;
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector;
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.source.ClippingMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.ProgressiveMediaSource;
import com.google.android.exoplayer2.source.TrackGroup;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.source.dash.DashMediaSource;
import com.google.android.exoplayer2.source.dash.DefaultDashChunkSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.source.smoothstreaming.DefaultSsChunkSource;
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.MappingTrackSelector;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.util.Util;
import com.google.android.exoplayer2.ui.PlayerNotificationManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import androidx.media.session.MediaButtonReceiver;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.TextureRegistry;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import com.google.android.exoplayer2.PlaybackParameters;

final class BetterPlayer {
    private static final String TAG = "BetterPlayer";
    private static final String FORMAT_SS = "ss";
    private static final String FORMAT_DASH = "dash";
    private static final String FORMAT_HLS = "hls";
    private static final String FORMAT_OTHER = "other";
    private static final String DEFAULT_NOTIFICATION_CHANNEL = "BETTER_PLAYER_NOTIFICATION";
    private static final String USER_AGENT = "User-Agent";
    private static final String USER_AGENT_PROPERTY = "http.agent";
    private static final int NOTIFICATION_ID = 20772077;

    private final SimpleExoPlayer exoPlayer;
    private final TextureRegistry.SurfaceTextureEntry textureEntry;
    private final QueuingEventSink eventSink = new QueuingEventSink();
    private final EventChannel eventChannel;
    private final DefaultTrackSelector trackSelector;

    private boolean isInitialized = false;
    private Surface surface;
    private String key;
    private PlayerNotificationManager playerNotificationManager;
    private Handler refreshHandler;
    private Runnable refreshRunnable;
    private EventListener exoPlayerEventListener;
    private Bitmap bitmap;
    private MediaSessionCompat mediaSession;
    private DrmSessionManager drmSessionManager;


    BetterPlayer(
            Context context,
            EventChannel eventChannel,
            TextureRegistry.SurfaceTextureEntry textureEntry,
            Result result) {
        this.eventChannel = eventChannel;
        this.textureEntry = textureEntry;
        trackSelector = new DefaultTrackSelector(context);
        exoPlayer = new SimpleExoPlayer.Builder(context).setTrackSelector(trackSelector).build();

        setupVideoPlayer(eventChannel, textureEntry, result);
    }

    void setDataSource(
            Context context, String key, String dataSource, String formatHint, Result result,
            Map<String, String> headers, boolean useCache, long maxCacheSize, long maxCacheFileSize,
            long overriddenDuration, String licenseUrl, Map<String, String> drmHeaders) {
        this.key = key;
        isInitialized = false;

        Uri uri = Uri.parse(dataSource);
        DataSource.Factory dataSourceFactory;

        String userAgent = System.getProperty(USER_AGENT_PROPERTY);
        if (headers != null && headers.containsKey(USER_AGENT)) {
            String userAgentHeader = headers.get(USER_AGENT);
            if (userAgentHeader != null) {
                userAgent = userAgentHeader;
            }
        }

        if (licenseUrl != null && !licenseUrl.isEmpty()) {
            HttpMediaDrmCallback httpMediaDrmCallback =
                    new HttpMediaDrmCallback(licenseUrl, new DefaultHttpDataSource.Factory());
            if (Util.SDK_INT < 18) {
                Log.e(TAG, "Protected content not supported on API levels below 18");
                drmSessionManager = null;
            } else {
                UUID drmSchemeUuid = Util.getDrmUuid("widevine");
                drmSessionManager =
                        new DefaultDrmSessionManager.Builder()
                                .setUuidAndExoMediaDrmProvider(drmSchemeUuid,
                                        uuid -> {
                                            try {
                                                FrameworkMediaDrm mediaDrm = FrameworkMediaDrm.newInstance(uuid);
                                                // Force L3.
                                                mediaDrm.setPropertyString("securityLevel", "L3");
                                                return mediaDrm;
                                            } catch (UnsupportedDrmException e) {
                                                return new DummyExoMediaDrm();
                                            }
                                        })
                                .setMultiSession(false)
                                .setKeyRequestParameters(drmHeaders)
                                .build(httpMediaDrmCallback);
            }
        } else {
            drmSessionManager = null;
        }

        if (isHTTP(uri)) {
            dataSourceFactory = new DefaultHttpDataSource.Factory()
                    .setUserAgent(userAgent)
                    .setAllowCrossProtocolRedirects(true)
                    .setConnectTimeoutMs(DefaultHttpDataSource.DEFAULT_CONNECT_TIMEOUT_MILLIS)
                    .setReadTimeoutMs(DefaultHttpDataSource.DEFAULT_READ_TIMEOUT_MILLIS);

            if (headers != null) {
                ((DefaultHttpDataSource.Factory) dataSourceFactory).setDefaultRequestProperties(headers);
            }

            if (useCache && maxCacheSize > 0 && maxCacheFileSize > 0) {
                dataSourceFactory =
                        new CacheDataSourceFactory(context, maxCacheSize, maxCacheFileSize, dataSourceFactory);
            }
        } else {
            dataSourceFactory = new DefaultDataSourceFactory(context, userAgent);
        }

        MediaSource mediaSource = buildMediaSource(uri, dataSourceFactory, formatHint, context);
        if (overriddenDuration != 0) {
            ClippingMediaSource clippingMediaSource = new ClippingMediaSource(mediaSource, 0, overriddenDuration * 1000);
            exoPlayer.setMediaSource(clippingMediaSource);
        } else {
            exoPlayer.setMediaSource(mediaSource);
        }
        exoPlayer.prepare();

        result.success(null);
    }

    public void setupPlayerNotification(Context context, String title, String author, String imageUrl, String notificationChannelName) {

        PlayerNotificationManager.MediaDescriptionAdapter mediaDescriptionAdapter
                = new PlayerNotificationManager.MediaDescriptionAdapter() {
            @NonNull
            @Override
            public String getCurrentContentTitle(@NonNull Player player) {
                return title;
            }

            @Nullable
            @Override
            public PendingIntent createCurrentContentIntent(@NonNull Player player) {
                return null;
            }

            @Nullable
            @Override
            public String getCurrentContentText(@NonNull Player player) {
                return author;
            }

            @Nullable
            @Override
            public Bitmap getCurrentLargeIcon(@NonNull Player player,
                                              @NonNull PlayerNotificationManager.BitmapCallback callback) {
                if (imageUrl == null) {
                    return null;
                }
                if (bitmap != null) {
                    return bitmap;
                }
                new Thread(() -> {
                    bitmap = null;
                    if (imageUrl.contains("http")) {
                        bitmap = getBitmapFromExternalURL(imageUrl);
                    } else {
                        bitmap = getBitmapFromInternalURL(imageUrl);
                    }

                    Bitmap finalBitmap = bitmap;
                    new Handler(Looper.getMainLooper()).post(() -> callback.onBitmap(finalBitmap));

                }).start();
                return null;
            }
        };

        String playerNotificationChannelName = notificationChannelName;
        if (notificationChannelName == null) {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                int importance = NotificationManager.IMPORTANCE_LOW;
                NotificationChannel channel = new NotificationChannel(DEFAULT_NOTIFICATION_CHANNEL,
                        DEFAULT_NOTIFICATION_CHANNEL, importance);
                channel.setDescription(DEFAULT_NOTIFICATION_CHANNEL);
                NotificationManager notificationManager = context.getSystemService(NotificationManager.class);
                notificationManager.createNotificationChannel(channel);
                playerNotificationChannelName = DEFAULT_NOTIFICATION_CHANNEL;
            }
        }


        playerNotificationManager = new PlayerNotificationManager(context,
                playerNotificationChannelName,
                NOTIFICATION_ID,
                mediaDescriptionAdapter);
        playerNotificationManager.setPlayer(exoPlayer);
        playerNotificationManager.setUseNextAction(false);
        playerNotificationManager.setUsePreviousAction(false);
        playerNotificationManager.setUseStopAction(false);


        MediaSessionCompat mediaSession = setupMediaSession(context, false);
        playerNotificationManager.setMediaSessionToken(mediaSession.getSessionToken());


        playerNotificationManager.setControlDispatcher(setupControlDispatcher());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            refreshHandler = new Handler();
            refreshRunnable = () -> {
                PlaybackStateCompat playbackState;
                if (exoPlayer.getPlayWhenReady()) {
                    playbackState = new PlaybackStateCompat.Builder()
                            .setActions(PlaybackStateCompat.ACTION_SEEK_TO)
                            .setState(PlaybackStateCompat.STATE_PAUSED, getPosition(), 1.0f)
                            .build();
                } else {
                    playbackState = new PlaybackStateCompat.Builder()
                            .setActions(PlaybackStateCompat.ACTION_SEEK_TO)
                            .setState(PlaybackStateCompat.STATE_PLAYING, getPosition(), 1.0f)
                            .build();
                }

                mediaSession.setPlaybackState(playbackState);
                refreshHandler.postDelayed(refreshRunnable, 1000);
            };
            refreshHandler.postDelayed(refreshRunnable, 0);
        }

        exoPlayerEventListener = new EventListener() {
            @Override
            public void onPlaybackStateChanged(int playbackState) {
                mediaSession.setMetadata(new MediaMetadataCompat.Builder()
                        .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, getDuration())
                        .build());
            }
        };

        exoPlayer.addListener(exoPlayerEventListener);
        exoPlayer.seekTo(0);
    }


    private ControlDispatcher setupControlDispatcher() {
        return new ControlDispatcher() {
            @Override
            public boolean dispatchPrepare(Player player) {
                return false;
            }

            @Override
            public boolean dispatchSetPlayWhenReady(Player player, boolean playWhenReady) {
                if (player.getPlayWhenReady()) {
                    sendEvent("pause");
                } else {
                    sendEvent("play");
                }
                return true;
            }

            @Override
            public boolean dispatchSeekTo(Player player, int windowIndex, long positionMs) {
                sendSeekToEvent(positionMs);
                return true;
            }

            @Override
            public boolean dispatchPrevious(Player player) {
                return false;
            }

            @Override
            public boolean dispatchNext(Player player) {
                return false;
            }

            @Override
            public boolean dispatchRewind(Player player) {
                sendSeekToEvent(player.getCurrentPosition() - 5000);
                return false;
            }

            @Override
            public boolean dispatchFastForward(Player player) {
                sendSeekToEvent(player.getCurrentPosition() + 5000);
                return true;
            }

            @Override
            public boolean dispatchSetRepeatMode(Player player, int repeatMode) {
                return false;
            }

            @Override
            public boolean dispatchSetShuffleModeEnabled(Player player, boolean shuffleModeEnabled) {
                return false;
            }

            @Override
            public boolean dispatchStop(Player player, boolean reset) {
                return false;
            }

            @Override
            public boolean dispatchSetPlaybackParameters(Player player, PlaybackParameters playbackParameters) {
                return false;
            }

            @Override
            public boolean isRewindEnabled() {
                return true;
            }

            @Override
            public boolean isFastForwardEnabled() {
                return true;
            }
        };
    }


    public void disposeRemoteNotifications() {
        exoPlayer.removeListener(exoPlayerEventListener);
        if (refreshHandler != null) {
            refreshHandler.removeCallbacksAndMessages(null);
            refreshHandler = null;
            refreshRunnable = null;
        }
        if (playerNotificationManager != null) {
            playerNotificationManager.setPlayer(null);
        }
        bitmap = null;
    }

    private static Bitmap getBitmapFromInternalURL(String src) {
        try {
            return BitmapFactory.decodeFile(src);
        } catch (Exception exception) {
            return null;
        }
    }

    private static Bitmap getBitmapFromExternalURL(String src) {
        try {
            URL url = new URL(src);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setDoInput(true);
            connection.connect();
            InputStream input = connection.getInputStream();
            return BitmapFactory.decodeStream(input);
        } catch (IOException exception) {
            return null;
        }
    }


    private static boolean isHTTP(Uri uri) {
        if (uri == null || uri.getScheme() == null) {
            return false;
        }
        String scheme = uri.getScheme();
        return scheme.equals("http") || scheme.equals("https");
    }

    private MediaSource buildMediaSource(
            Uri uri, DataSource.Factory mediaDataSourceFactory, String formatHint, Context context) {
        int type;
        if (formatHint == null) {
            String lastPathSegment = uri.getLastPathSegment();
            if (lastPathSegment == null) {
                lastPathSegment = "";
            }
            type = Util.inferContentType(lastPathSegment);
        } else {
            switch (formatHint) {
                case FORMAT_SS:
                    type = C.TYPE_SS;
                    break;
                case FORMAT_DASH:
                    type = C.TYPE_DASH;
                    break;
                case FORMAT_HLS:
                    type = C.TYPE_HLS;
                    break;
                case FORMAT_OTHER:
                    type = C.TYPE_OTHER;
                    break;
                default:
                    type = -1;
                    break;
            }
        }
        switch (type) {
            case C.TYPE_SS:
                return new SsMediaSource.Factory(
                        new DefaultSsChunkSource.Factory(mediaDataSourceFactory),
                        new DefaultDataSourceFactory(context, null, mediaDataSourceFactory))
                        .setDrmSessionManager(drmSessionManager)
                        .createMediaSource(MediaItem.fromUri(uri));
            case C.TYPE_DASH:
                return new DashMediaSource.Factory(
                        new DefaultDashChunkSource.Factory(mediaDataSourceFactory),
                        new DefaultDataSourceFactory(context, null, mediaDataSourceFactory))
                        .setDrmSessionManager(drmSessionManager)
                        .createMediaSource(MediaItem.fromUri(uri));
            case C.TYPE_HLS:
                return new HlsMediaSource.Factory(mediaDataSourceFactory)
                        .setDrmSessionManager(drmSessionManager)
                        .createMediaSource(MediaItem.fromUri(uri));
            case C.TYPE_OTHER:
                return new ProgressiveMediaSource.Factory(mediaDataSourceFactory,
                        new DefaultExtractorsFactory())
                        .setDrmSessionManager(drmSessionManager)
                        .createMediaSource(MediaItem.fromUri(uri));
            default: {
                throw new IllegalStateException("Unsupported type: " + type);
            }
        }
    }

    private void setupVideoPlayer(
            EventChannel eventChannel, TextureRegistry.SurfaceTextureEntry textureEntry, Result result) {

        eventChannel.setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object o, EventChannel.EventSink sink) {
                        eventSink.setDelegate(sink);
                    }

                    @Override
                    public void onCancel(Object o) {
                        eventSink.setDelegate(null);
                    }
                });

        surface = new Surface(textureEntry.surfaceTexture());
        exoPlayer.setVideoSurface(surface);
        setAudioAttributes(exoPlayer, true);

        exoPlayer.addListener(
                new EventListener() {

                    @Override
                    public void onPlaybackStateChanged(int playbackState) {
                        if (playbackState == Player.STATE_BUFFERING) {
                            sendBufferingUpdate();
                            Map<String, Object> event = new HashMap<>();
                            event.put("event", "bufferingStart");
                            eventSink.success(event);
                        } else if (playbackState == Player.STATE_READY) {
                            if (!isInitialized) {
                                isInitialized = true;
                                sendInitialized();
                            }

                            Map<String, Object> event = new HashMap<>();
                            event.put("event", "bufferingEnd");
                            eventSink.success(event);

                        } else if (playbackState == Player.STATE_ENDED) {
                            Map<String, Object> event = new HashMap<>();
                            event.put("event", "completed");
                            event.put("key", key);
                            eventSink.success(event);
                        }
                    }

                    @Override
                    public void onPlayerError(final ExoPlaybackException error) {
                        eventSink.error("VideoError", "Video player had error " + error, null);
                    }
                });

        Map<String, Object> reply = new HashMap<>();
        reply.put("textureId", textureEntry.id());
        result.success(reply);
    }

    void sendBufferingUpdate() {
        Map<String, Object> event = new HashMap<>();
        event.put("event", "bufferingUpdate");
        List<? extends Number> range = Arrays.asList(0, exoPlayer.getBufferedPosition());
        // iOS supports a list of buffered ranges, so here is a list with a single range.
        event.put("values", Collections.singletonList(range));
        eventSink.success(event);
    }

    private void setAudioAttributes(SimpleExoPlayer exoPlayer, Boolean mixWithOthers) {
        Player.AudioComponent audioComponent = exoPlayer.getAudioComponent();
        if (audioComponent == null) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {

            audioComponent.setAudioAttributes(
                    new AudioAttributes.Builder().setContentType(C.CONTENT_TYPE_MOVIE).build(), !mixWithOthers);
        } else {
            audioComponent.setAudioAttributes(
                    new AudioAttributes.Builder().setContentType(C.CONTENT_TYPE_MUSIC).build(), !mixWithOthers);
        }
    }

    void play() {
        exoPlayer.setPlayWhenReady(true);
    }

    void pause() {
        exoPlayer.setPlayWhenReady(false);
    }

    void setLooping(boolean value) {
        exoPlayer.setRepeatMode(value ? REPEAT_MODE_ALL : REPEAT_MODE_OFF);
    }

    void setVolume(double value) {
        float bracketedValue = (float) Math.max(0.0, Math.min(1.0, value));
        exoPlayer.setVolume(bracketedValue);
    }

    void setSpeed(double value) {
        float bracketedValue = (float) value;
        PlaybackParameters playbackParameters = new PlaybackParameters(bracketedValue);
        exoPlayer.setPlaybackParameters(playbackParameters);
    }

    void setTrackParameters(int width, int height, int bitrate) {
        DefaultTrackSelector.ParametersBuilder parametersBuilder = trackSelector.buildUponParameters();
        if (width != 0 && height != 0) {
            parametersBuilder.setMaxVideoSize(width, height);
        }
        if (bitrate != 0) {
            parametersBuilder.setMaxVideoBitrate(bitrate);
        }
        if (width == 0 && height == 0 && bitrate == 0) {
            parametersBuilder.clearVideoSizeConstraints();
            parametersBuilder.setMaxVideoBitrate(Integer.MAX_VALUE);
        }

        trackSelector.setParameters(parametersBuilder);
    }

    void seekTo(int location) {
        exoPlayer.seekTo(location);
    }

    long getPosition() {
        return exoPlayer.getCurrentPosition();
    }

    long getAbsolutePosition() {
        Timeline timeline = exoPlayer.getCurrentTimeline();
        if (!timeline.isEmpty()) {
            long windowStartTimeMs = timeline.getWindow(0, new Timeline.Window()).windowStartTimeMs;
            long pos = exoPlayer.getCurrentPosition();
            return (windowStartTimeMs + pos);
        }
        return exoPlayer.getCurrentPosition();
    }

    @SuppressWarnings("SuspiciousNameCombination")
    private void sendInitialized() {
        if (isInitialized) {
            Map<String, Object> event = new HashMap<>();
            event.put("event", "initialized");
            event.put("key", key);
            event.put("duration", getDuration());

            if (exoPlayer.getVideoFormat() != null) {
                Format videoFormat = exoPlayer.getVideoFormat();
                int width = videoFormat.width;
                int height = videoFormat.height;
                int rotationDegrees = videoFormat.rotationDegrees;
                // Switch the width/height if video was taken in portrait mode
                if (rotationDegrees == 90 || rotationDegrees == 270) {
                    width = exoPlayer.getVideoFormat().height;
                    height = exoPlayer.getVideoFormat().width;
                }
                event.put("width", width);
                event.put("height", height);
            }
            eventSink.success(event);
        }
    }

    private long getDuration() {
        return exoPlayer.getDuration();
    }

    /**
     * Create media session which will be used in notifications, pip mode.
     *
     * @param context                - android context
     * @param setupControlDispatcher - should add control dispatcher to created MediaSession
     * @return - configured MediaSession instance
     */
    public MediaSessionCompat setupMediaSession(Context context, boolean setupControlDispatcher) {
        if (mediaSession != null) {
            mediaSession.release();
        }
        ComponentName mediaButtonReceiver = new ComponentName(context, MediaButtonReceiver.class);
        MediaSessionCompat mediaSession = new MediaSessionCompat(context, "BetterPlayer", mediaButtonReceiver, null);
        mediaSession.setCallback(new MediaSessionCompat.Callback() {
            @Override
            public void onSeekTo(long pos) {
                sendSeekToEvent(pos);
                super.onSeekTo(pos);
            }
        });

        mediaSession.setActive(true);
        MediaSessionConnector mediaSessionConnector =
                new MediaSessionConnector(mediaSession);
        if (setupControlDispatcher) {
            mediaSessionConnector.setControlDispatcher(setupControlDispatcher());
        }
        mediaSessionConnector.setPlayer(exoPlayer);

        Intent mediaButtonIntent = new Intent(Intent.ACTION_MEDIA_BUTTON);
        mediaButtonIntent.setClass(context, MediaButtonReceiver.class);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, 0, mediaButtonIntent, 0);
        mediaSession.setMediaButtonReceiver(pendingIntent);


        this.mediaSession = mediaSession;
        return mediaSession;
    }

    public void onPictureInPictureStatusChanged(boolean inPip) {
        Map<String, Object> event = new HashMap<>();
        event.put("event", inPip ? "pipStart" : "pipStop");
        eventSink.success(event);
    }

    public void disposeMediaSession() {
        if (mediaSession != null) {
            mediaSession.release();
        }
        mediaSession = null;
    }

    private void sendEvent(String eventType) {
        Map<String, Object> event = new HashMap<>();
        event.put("event", eventType);
        eventSink.success(event);
    }

    void setAudioTrack(String name, Integer index) {
        try {
            MappingTrackSelector.MappedTrackInfo mappedTrackInfo =
                    trackSelector.getCurrentMappedTrackInfo();

            if (mappedTrackInfo != null) {
                for (int rendererIndex = 0; rendererIndex < mappedTrackInfo.getRendererCount();
                     rendererIndex++) {
                    if (mappedTrackInfo.getRendererType(rendererIndex) != C.TRACK_TYPE_AUDIO) {
                        continue;
                    }
                    TrackGroupArray trackGroupArray = mappedTrackInfo.getTrackGroups(rendererIndex);
                    boolean hasElementWithoutLabel = false;
                    for (int groupIndex = 0; groupIndex < trackGroupArray.length; groupIndex++) {
                        TrackGroup group = trackGroupArray.get(groupIndex);
                        for (int groupElementIndex = 0; groupElementIndex < group.length; groupElementIndex++) {
                            String label = group.getFormat(groupElementIndex).label;
                            if (label == null) {
                                hasElementWithoutLabel = true;
                                break;
                            }
                        }
                    }

                    for (int groupIndex = 0; groupIndex < trackGroupArray.length; groupIndex++) {
                        TrackGroup group = trackGroupArray.get(groupIndex);
                        for (int groupElementIndex = 0; groupElementIndex < group.length; groupElementIndex++) {
                            String label = group.getFormat(groupElementIndex).label;
                            if (name.equals(label) && index == groupIndex) {
                                setAudioTrack(rendererIndex, groupIndex, groupElementIndex);
                                return;
                            }
                            ///Fallback option
                            if (hasElementWithoutLabel && name.equals(label)) {
                                setAudioTrack(rendererIndex, groupIndex, groupElementIndex);
                                return;
                            }

                        }
                    }
                }
            }
        } catch (Exception exception) {
            Log.e(TAG, "setAudioTrack failed" + exception.toString());
        }
    }

    private void setAudioTrack(int rendererIndex, int groupIndex, int groupElementIndex) {
        MappingTrackSelector.MappedTrackInfo mappedTrackInfo =
                trackSelector.getCurrentMappedTrackInfo();
        if (mappedTrackInfo != null) {
            DefaultTrackSelector.ParametersBuilder builder =
                    trackSelector.getParameters().buildUpon();
            builder.clearSelectionOverrides(rendererIndex)
                    .setRendererDisabled(rendererIndex, false);
            int[] tracks = {groupElementIndex};
            DefaultTrackSelector.SelectionOverride override =
                    new DefaultTrackSelector.SelectionOverride(groupIndex, tracks);
            builder.setSelectionOverride(rendererIndex,
                    mappedTrackInfo.getTrackGroups(rendererIndex), override);
            trackSelector.setParameters(builder);
        }
    }

    private void sendSeekToEvent(long positionMs) {
        exoPlayer.seekTo(positionMs);
        Map<String, Object> event = new HashMap<>();
        event.put("event", "seek");
        event.put("position", positionMs);
        eventSink.success(event);
    }

    public void setMixWithOthers(Boolean mixWithOthers) {
        setAudioAttributes(exoPlayer, mixWithOthers);
    }

    //Clear cache without accessing BetterPlayerCache.
    @SuppressWarnings("ResultOfMethodCallIgnored")
    public void clearCache(Context context) {
        try {
            File file = context.getCacheDir();
            if (file != null) {
                file.delete();
            }
        } catch (Exception exception) {
            Log.e("Cache", exception.toString());
        }
    }

    void dispose() {
        disposeMediaSession();
        disposeRemoteNotifications();
        if (isInitialized) {
            exoPlayer.stop();
        }
        textureEntry.release();
        eventChannel.setStreamHandler(null);
        if (surface != null) {
            surface.release();
        }
        if (exoPlayer != null) {
            exoPlayer.release();
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        BetterPlayer that = (BetterPlayer) o;

        if (exoPlayer != null ? !exoPlayer.equals(that.exoPlayer) : that.exoPlayer != null)
            return false;
        return surface != null ? surface.equals(that.surface) : that.surface == null;
    }

    @Override
    public int hashCode() {
        int result = exoPlayer != null ? exoPlayer.hashCode() : 0;
        result = 31 * result + (surface != null ? surface.hashCode() : 0);
        return result;
    }

}


