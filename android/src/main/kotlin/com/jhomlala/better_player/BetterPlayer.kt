// File: android/src/main/kotlin/com/jhomlala/better_player/BetterPlayer.kt

package com.jhomlala.better_player

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Surface
import androidx.lifecycle.Observer
import androidx.media.session.MediaButtonReceiver
import androidx.media.MediaMetadataCompat
import androidx.media.session.MediaSessionCompat
import androidx.media.session.PlaybackStateCompat
import androidx.work.Data
import androidx.work.OneTimeWorkRequest
import androidx.work.WorkInfo
import androidx.work.WorkManager
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.DefaultLoadControl
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.LoadControl
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.PlaybackParameters
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.PlaybackException
import com.google.android.exoplayer2.Timeline
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.drm.DefaultDrmSessionManager
import com.google.android.exoplayer2.drm.DrmSessionManager
import com.google.android.exoplayer2.drm.DrmSessionManagerProvider
import com.google.android.exoplayer2.drm.DummyExoMediaDrm
import com.google.android.exoplayer2.drm.FrameworkMediaDrm
import com.google.android.exoplayer2.drm.HttpMediaDrmCallback
import com.google.android.exoplayer2.drm.LocalMediaDrmCallback
import com.google.android.exoplayer2.drm.UnsupportedDrmException
import com.google.android.exoplayer2.ext.mediasession.ForwardingPlayer
import com.google.android.exoplayer2.ext.mediasession.MediaSessionConnector
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory
import com.google.android.exoplayer2.source.ClippingMediaSource
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.source.dash.DashMediaSource
import com.google.android.exoplayer2.source.dash.DefaultDashChunkSource
import com.google.android.exoplayer2.source.hls.HlsMediaSource
import com.google.android.exoplayer2.source.smoothstreaming.DefaultSsChunkSource
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionOverrides
import com.google.android.exoplayer2.ui.PlayerNotificationManager
import com.google.android.exoplayer2.ui.PlayerNotificationManager.BitmapCallback
import com.google.android.exoplayer2.ui.PlayerNotificationManager.MediaDescriptionAdapter
import com.google.android.exoplayer2.upstream.DefaultDataSource
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.util.Util
import com.google.android.exoplayer2.video.VideoSize
import com.jhomlala.better_player.DataSourceUtils.getDataSourceFactory
import com.jhomlala.better_player.DataSourceUtils.getUserAgent
import com.jhomlala.better_player.DataSourceUtils.isHTTP
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import java.io.File
import java.util.*
import kotlin.math.max
import kotlin.math.min

internal class BetterPlayer(
    context: Context,
    private val eventChannel: EventChannel,
    private val textureEntry: SurfaceTextureEntry,
    customDefaultLoadControl: CustomDefaultLoadControl?,
    result: MethodChannel.Result
) {
    // ExoPlayer is never null after we build it in init { … }, so make it non-nullable
    private val exoPlayer: ExoPlayer
    private val eventSink = QueuingEventSink()
    private val trackSelector: DefaultTrackSelector = DefaultTrackSelector(context)
    private val loadControl: LoadControl
    private var isInitialized = false
    private var surface: Surface? = null
    private var key: String? = null
    private var playerNotificationManager: PlayerNotificationManager? = null
    private var refreshHandler: Handler? = null
    private var refreshRunnable: Runnable? = null
    private var exoPlayerEventListener: Player.Listener? = null
    private var bitmap: Bitmap? = null
    private var mediaSession: MediaSessionCompat? = null
    private var drmSessionManager: DrmSessionManager? = null
    private val workManager: WorkManager
    private val workerObserverMap: HashMap<UUID, Observer<WorkInfo?>>
    private val customDefaultLoadControl: CustomDefaultLoadControl =
        customDefaultLoadControl ?: CustomDefaultLoadControl()
    private var lastSendBufferedPosition = 0L
    private var lastReportedWidth = 0
    private var lastReportedHeight = 0

    // Declare and initialize videoSizeListener before init { … }
    private val videoSizeListener = object : Player.Listener {
        override fun onVideoSizeChanged(videoSize: VideoSize) {
            val w = videoSize.width
            val h = videoSize.height
            if (w != lastReportedWidth || h != lastReportedHeight) {
                lastReportedWidth = w
                lastReportedHeight = h
                eventSink.success(
                    mapOf(
                        "event" to "changedResolution",
                        "width" to w,
                        "height" to h
                    )
                )
                Log.d(TAG, "Resolution changed -> ${w}x${h}")
            }
        }
    }

    init {
        // Build a DefaultLoadControl with your CustomDefaultLoadControl settings
        val loadBuilder = DefaultLoadControl.Builder()
        loadBuilder.setBufferDurationsMs(
            this.customDefaultLoadControl.minBufferMs,
            this.customDefaultLoadControl.maxBufferMs,
            this.customDefaultLoadControl.bufferForPlaybackMs,
            this.customDefaultLoadControl.bufferForPlaybackAfterRebufferMs
        )
        loadControl = loadBuilder.build()

        // Construct ExoPlayer once
        exoPlayer = ExoPlayer.Builder(context)
            .setTrackSelector(trackSelector)
            .setLoadControl(loadControl)
            .build()
        // Attach our videoSizeListener immediately
        exoPlayer.addListener(videoSizeListener)

        workManager = WorkManager.getInstance(context)
        workerObserverMap = HashMap()

        setupVideoPlayer(eventChannel, textureEntry, result)
    }

    /**
     * Called from the Flutter plugin to set up the player’s data source (formatHint, caching, DRM, etc.).
     */
    fun setDataSource(
        context: Context,
        key: String?,
        dataSource: String?,
        formatHint: String?,
        result: MethodChannel.Result,
        headers: Map<String, String>?,
        useCache: Boolean,
        maxCacheSize: Long,
        maxCacheFileSize: Long,
        overriddenDuration: Long,
        licenseUrl: String?,
        drmHeaders: Map<String, String>?,
        cacheKey: String?,
        clearKey: String?
    ) {
        this.key = key
        isInitialized = false

        val uri = Uri.parse(dataSource)
        val userAgent = getUserAgent(headers)

        // Build the right DataSource.Factory (HTTP with optional caching, or local)
        val dataSourceFactory: DataSource.Factory = if (isHTTP(uri)) {
            var factory = getDataSourceFactory(userAgent, headers)
            if (useCache && maxCacheSize > 0 && maxCacheFileSize > 0) {
                factory = CacheDataSourceFactory(
                    context,
                    maxCacheSize,
                    maxCacheFileSize,
                    factory
                )
            }
            factory
        } else {
            DefaultDataSource.Factory(context)
        }

        // DRM setup if licenseUrl or clearKey is provided
        if (!licenseUrl.isNullOrEmpty()) {
            val httpDrmCallback = HttpMediaDrmCallback(licenseUrl, DefaultHttpDataSource.Factory())
            drmHeaders?.forEach { (drmKey, drmValue) ->
                httpDrmCallback.setKeyRequestProperty(drmKey, drmValue)
            }
            drmSessionManager = if (Util.SDK_INT < 18) {
                Log.e(TAG, "Protected content not supported on API < 18")
                null
            } else {
                val widevineUuid = Util.getDrmUuid("widevine")
                if (widevineUuid != null) {
                    DefaultDrmSessionManager.Builder()
                        .setUuidAndExoMediaDrmProvider(widevineUuid) { uuid ->
                            try {
                                val mediaDrm = FrameworkMediaDrm.newInstance(uuid!!)
                                mediaDrm.setPropertyString("securityLevel", "L3")
                                mediaDrm
                            } catch (e: UnsupportedDrmException) {
                                DummyExoMediaDrm()
                            }
                        }
                        .setMultiSession(false)
                        .build(httpDrmCallback)
                } else {
                    null
                }
            }
        } else if (!clearKey.isNullOrEmpty()) {
            drmSessionManager = if (Util.SDK_INT < 18) {
                Log.e(TAG, "Protected content not supported on API < 18")
                null
            } else {
                DefaultDrmSessionManager.Builder()
                    .setUuidAndExoMediaDrmProvider(
                        C.CLEARKEY_UUID,
                        FrameworkMediaDrm.DEFAULT_PROVIDER
                    )
                    .build(LocalMediaDrmCallback(clearKey.toByteArray()))
            }
        } else {
            drmSessionManager = null
        }

        // Build the actual MediaSource (HLS, DASH, SmoothStreaming, or “OTHER”)
        val mediaSource = buildMediaSource(uri, dataSourceFactory, formatHint, cacheKey, context)

        // If an overriddenDuration is provided, wrap in ClippingMediaSource
        if (overriddenDuration != 0L) {
            val clippingSource = ClippingMediaSource(mediaSource, 0, overriddenDuration * 1000)
            exoPlayer.setMediaSource(clippingSource)
        } else {
            exoPlayer.setMediaSource(mediaSource)
        }

        exoPlayer.prepare()
        result.success(null)
    }

    /**
     * Public so BetterPlayerPlugin can call it.  Shows the notification & media session controls.
     */
    fun setupPlayerNotification(
        context: Context,
        title: String,
        author: String?,
        imageUrl: String?,
        notificationChannelName: String?,
        activityName: String
    ) {
        val mediaDescriptionAdapter = object : MediaDescriptionAdapter {
            override fun getCurrentContentTitle(player: Player): String {
                return title
            }

            @SuppressLint("UnspecifiedImmutableFlag")
            override fun createCurrentContentIntent(player: Player): PendingIntent? {
                val pkg = context.applicationContext.packageName
                val notificationIntent = Intent().apply {
                    setClassName(pkg, "$pkg.$activityName")
                    flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                return PendingIntent.getActivity(
                    context,
                    0,
                    notificationIntent,
                    PendingIntent.FLAG_IMMUTABLE
                )
            }

            override fun getCurrentContentText(player: Player): String? {
                return author
            }

            override fun getCurrentLargeIcon(
                player: Player,
                callback: BitmapCallback
            ): Bitmap? {
                if (imageUrl.isNullOrEmpty()) return null
                if (bitmap != null) return bitmap

                // Launch a WorkManager job to fetch the image
                val imageWorkRequest = OneTimeWorkRequest.Builder(ImageWorker::class.java)
                    .addTag(imageUrl)
                    .setInputData(
                        Data.Builder()
                            .putString(BetterPlayerPlugin.URL_PARAMETER, imageUrl)
                            .build()
                    )
                    .build()
                workManager.enqueue(imageWorkRequest)

                val observer = Observer<WorkInfo?> { workInfo ->
                    try {
                        if (workInfo != null && workInfo.state == WorkInfo.State.SUCCEEDED) {
                            val filePath =
                                workInfo.outputData.getString(BetterPlayerPlugin.FILE_PATH_PARAMETER)
                            bitmap = BitmapFactory.decodeFile(filePath)
                            bitmap?.let { bmp ->
                                callback.onBitmap(bmp)
                            }
                        }
                        if (workInfo != null &&
                            (workInfo.state == WorkInfo.State.SUCCEEDED ||
                             workInfo.state == WorkInfo.State.CANCELLED ||
                             workInfo.state == WorkInfo.State.FAILED)
                        ) {
                            val uuid = imageWorkRequest.id
                            workerObserverMap.remove(uuid)?.let { obs ->
                                workManager.getWorkInfoByIdLiveData(uuid)
                                    .removeObserver(obs)
                            }
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error fetching image for notification: $e")
                    }
                }
                workManager.getWorkInfoByIdLiveData(imageWorkRequest.id)
                    .observeForever(observer)
                workerObserverMap[imageWorkRequest.id] = observer

                return null
            }
        }

        // Create a notification channel on Oreo+ if none was provided
        var channelName = notificationChannelName
        if (channelName.isNullOrEmpty() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(
                DEFAULT_NOTIFICATION_CHANNEL,
                DEFAULT_NOTIFICATION_CHANNEL,
                importance
            ).apply {
                description = DEFAULT_NOTIFICATION_CHANNEL
            }
            (context.getSystemService(NotificationManager::class.java))
                ?.createNotificationChannel(channel)
            channelName = DEFAULT_NOTIFICATION_CHANNEL
        }

        playerNotificationManager = PlayerNotificationManager.Builder(
            context,
            NOTIFICATION_ID,
            channelName!!
        )
            .setMediaDescriptionAdapter(mediaDescriptionAdapter)
            .build().apply {
                // Wrap ExoPlayer in a ForwardingPlayer to pass into the NotificationManager
                setPlayer(ForwardingPlayer(exoPlayer))
                setUseNextAction(false)
                setUsePreviousAction(false)
                setUseStopAction(false)

                // Attach the MediaSession token
                setupMediaSession(context)?.let { session ->
                    setMediaSessionToken(session.sessionToken)
                }
            }

        // Every second, update the MediaSession’s playback state so the lock-screen controls stay in sync
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            refreshHandler = Handler(Looper.getMainLooper())
            refreshRunnable = object : Runnable {
                override fun run() {
                    val state = if (exoPlayer.isPlaying) {
                        PlaybackStateCompat.Builder()
                            .setActions(PlaybackStateCompat.ACTION_SEEK_TO)
                            .setState(
                                PlaybackStateCompat.STATE_PLAYING,
                                position,
                                1.0f
                            )
                            .build()
                    } else {
                        PlaybackStateCompat.Builder()
                            .setActions(PlaybackStateCompat.ACTION_SEEK_TO)
                            .setState(
                                PlaybackStateCompat.STATE_PAUSED,
                                position,
                                1.0f
                            )
                            .build()
                    }
                    mediaSession?.setPlaybackState(state)
                    refreshHandler?.postDelayed(this, 1_000)
                }
            }
            refreshHandler?.postDelayed(refreshRunnable!!, 0)
        }

        exoPlayerEventListener = object : Player.Listener {
            override fun onPlaybackStateChanged(playbackState: Int) {
                // Update MediaSession metadata (duration) whenever player state changes
                mediaSession?.setMetadata(
                    MediaMetadataCompat.Builder()
                        .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, getDuration())
                        .build()
                )
            }
        }
        exoPlayer.addListener(exoPlayerEventListener!!)
        exoPlayer.seekTo(0)
    }

    fun disposeRemoteNotifications() {
        exoPlayerEventListener?.let { exoPlayer.removeListener(it) }
        refreshHandler?.removeCallbacksAndMessages(null)
        refreshHandler = null
        refreshRunnable = null
        playerNotificationManager?.setPlayer(null)
        bitmap = null
    }

    private fun buildMediaSource(
        uri: Uri,
        mediaDataSourceFactory: DataSource.Factory,
        formatHint: String?,
        cacheKey: String?,
        context: Context
    ): MediaSource {
        val type: Int = if (formatHint.isNullOrEmpty()) {
            Util.inferContentType(uri.lastPathSegment ?: "")
        } else {
            when (formatHint) {
                FORMAT_SS -> C.TYPE_SS
                FORMAT_DASH -> C.TYPE_DASH
                FORMAT_HLS -> C.TYPE_HLS
                FORMAT_OTHER -> C.TYPE_OTHER
                else -> -1
            }
        }

        val mediaItem = MediaItem.Builder()
            .setUri(uri)
            .apply {
                if (!cacheKey.isNullOrEmpty()) {
                    setCustomCacheKey(cacheKey)
                }
            }
            .build()

        // Provide a DrmSessionManagerProvider if DRM was set up above
        val drmProvider: DrmSessionManagerProvider? = drmSessionManager?.let { drm ->
            DrmSessionManagerProvider { drm }
        }

        return when (type) {
            C.TYPE_SS -> SsMediaSource.Factory(
                DefaultSsChunkSource.Factory(mediaDataSourceFactory),
                DefaultDataSource.Factory(context, mediaDataSourceFactory)
            )
                .setDrmSessionManagerProvider(drmProvider)
                .createMediaSource(mediaItem)

            C.TYPE_DASH -> DashMediaSource.Factory(
                DefaultDashChunkSource.Factory(mediaDataSourceFactory),
                DefaultDataSource.Factory(context, mediaDataSourceFactory)
            )
                .setDrmSessionManagerProvider(drmProvider)
                .createMediaSource(mediaItem)

            C.TYPE_HLS -> HlsMediaSource.Factory(mediaDataSourceFactory)
                .setDrmSessionManagerProvider(drmProvider)
                .createMediaSource(mediaItem)

            C.TYPE_OTHER -> ProgressiveMediaSource.Factory(
                mediaDataSourceFactory,
                DefaultExtractorsFactory()
            )
                .setDrmSessionManagerProvider(drmProvider)
                .createMediaSource(mediaItem)

            else -> throw IllegalStateException("Unsupported media type: $type")
        }
    }

    private fun setupVideoPlayer(
        eventChannel: EventChannel,
        textureEntry: SurfaceTextureEntry,
        result: MethodChannel.Result
    ) {
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventSink) {
                eventSink.setDelegate(sink)
            }

            override fun onCancel(args: Any?) {
                eventSink.setDelegate(null)
            }
        })

        surface = Surface(textureEntry.surfaceTexture())
        exoPlayer.setVideoSurface(surface)
        setAudioAttributes(exoPlayer, true)

        exoPlayer.addListener(object : Player.Listener {
            override fun onPlaybackStateChanged(state: Int) {
                when (state) {
                    Player.STATE_BUFFERING -> {
                        sendBufferingUpdate(true)
                        eventSink.success(mapOf("event" to "bufferingStart"))
                    }
                    Player.STATE_READY -> {
                        if (!isInitialized) {
                            isInitialized = true
                            sendInitialized()
                        }
                        eventSink.success(mapOf("event" to "bufferingEnd"))
                    }
                    Player.STATE_ENDED -> {
                        eventSink.success(mapOf("event" to "completed", "key" to key))
                    }
                    Player.STATE_IDLE -> { /* no-op */ }
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                eventSink.error("VideoError", "Video player had error $error", "")
            }
        })

        // Return the textureId back to Flutter
        result.success(mapOf("textureId" to textureEntry.id()))
    }

    fun sendBufferingUpdate(isFromBufferingStart: Boolean) {
        val bufferedPosition = exoPlayer.bufferedPosition
        if (isFromBufferingStart || bufferedPosition != lastSendBufferedPosition) {
            val event: MutableMap<String, Any> = HashMap()
            event["event"] = "bufferingUpdate"
            val range: List<Number> = listOf(0, bufferedPosition)
            event["values"] = listOf(range)
            eventSink.success(event)
            lastSendBufferedPosition = bufferedPosition
        }
    }

    @Suppress("DEPRECATION")
    private fun setAudioAttributes(exo: ExoPlayer, mixWithOthers: Boolean) {
        val audioComponent = exo.audioComponent ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            audioComponent.setAudioAttributes(
                AudioAttributes.Builder().setContentType(C.CONTENT_TYPE_MOVIE).build(),
                !mixWithOthers
            )
        } else {
            audioComponent.setAudioAttributes(
                AudioAttributes.Builder().setContentType(C.CONTENT_TYPE_MUSIC).build(),
                !mixWithOthers
            )
        }
    }

    fun play() {
        exoPlayer.playWhenReady = true
    }

    fun pause() {
        exoPlayer.playWhenReady = false
    }

    fun setLooping(value: Boolean) {
        exoPlayer.repeatMode = if (value) Player.REPEAT_MODE_ALL else Player.REPEAT_MODE_OFF
    }

    fun setVolume(value: Double) {
        exoPlayer.volume = max(0.0, min(1.0, value)).toFloat()
    }

    fun setSpeed(value: Double) {
        exoPlayer.playbackParameters = PlaybackParameters(value.toFloat())
    }

    fun setTrackParameters(width: Int, height: Int, bitrate: Int) {
        val builder = trackSelector.buildUponParameters()
        if (width != 0 && height != 0) {
            builder.setMaxVideoSize(width, height)
        }
        if (bitrate != 0) {
            builder.setMaxVideoBitrate(bitrate)
        }
        if (width == 0 && height == 0 && bitrate == 0) {
            builder.clearVideoSizeConstraints()
            builder.setMaxVideoBitrate(Int.MAX_VALUE)
        }
        trackSelector.setParameters(builder)
    }

    fun seekTo(location: Int) {
        exoPlayer.seekTo(location.toLong())
    }

    val position: Long
        get() = exoPlayer.currentPosition

    val absolutePosition: Long
        get() {
            val timeline = exoPlayer.currentTimeline
            if (!timeline.isEmpty) {
                val windowStartTimeMs = timeline.getWindow(0, Timeline.Window()).windowStartTimeMs
                return windowStartTimeMs + exoPlayer.currentPosition
            }
            return exoPlayer.currentPosition
        }

    private fun sendInitialized() {
        val event: MutableMap<String, Any?> = HashMap()
        event["event"] = "initialized"
        event["key"] = key
        event["duration"] = getDuration()
        val format = exoPlayer.videoFormat
        if (format != null) {
            var w = format.width
            var h = format.height
            val rot = format.rotationDegrees
            if (rot == 90 || rot == 270) {
                w = format.height
                h = format.width
            }
            event["width"] = w
            event["height"] = h
        }
        eventSink.success(event)
    }

    private fun getDuration(): Long = exoPlayer.duration

    @SuppressLint("InlinedApi")
    fun setupMediaSession(context: Context?): MediaSessionCompat? {
        mediaSession?.release()
        context?.let {
            val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                mediaButtonIntent,
                PendingIntent.FLAG_IMMUTABLE
            )
            val session = MediaSessionCompat(context, TAG, null, pendingIntent)
            session.setCallback(object : MediaSessionCompat.Callback() {
                override fun onSeekTo(pos: Long) {
                    super.onSeekTo(pos)
                    sendSeekToEvent(pos)
                }
            })
            session.isActive = true
            MediaSessionConnector(session).setPlayer(exoPlayer)
            mediaSession = session
            return session
        }
        return null
    }

    fun onPictureInPictureStatusChanged(inPip: Boolean) {
        eventSink.success(mapOf("event" to if (inPip) "pipStart" else "pipStop"))
    }

    fun disposeMediaSession() {
        mediaSession?.release()
        mediaSession = null
    }

    fun setAudioTrack(name: String, index: Int) {
        try {
            val mappedTrackInfo = trackSelector.currentMappedTrackInfo ?: return
            for (rendererIndex in 0 until mappedTrackInfo.rendererCount) {
                if (mappedTrackInfo.getRendererType(rendererIndex) != C.TRACK_TYPE_AUDIO) {
                    continue
                }
                val groups = mappedTrackInfo.getTrackGroups(rendererIndex)
                var hasNoLabel = false
                var hasStrange = false
                for (g in 0 until groups.length) {
                    val group = groups[g]
                    for (e in 0 until group.length) {
                        val format = group.getFormat(e)
                        if (format.label == null) hasNoLabel = true
                        if (format.id != null && format.id == "1/15") hasStrange = true
                    }
                }
                for (g in 0 until groups.length) {
                    val group = groups[g]
                    for (e in 0 until group.length) {
                        val label = group.getFormat(e).label
                        if (name == label && index == g) {
                            applyAudioTrack(rendererIndex, g, e)
                            return
                        }
                        if (!hasStrange && hasNoLabel && index == g) {
                            applyAudioTrack(rendererIndex, g, e)
                            return
                        }
                        if (hasStrange && name == label) {
                            applyAudioTrack(rendererIndex, g, e)
                            return
                        }
                    }
                }
            }
        } catch (ex: Exception) {
            Log.e(TAG, "setAudioTrack failed: $ex")
        }
    }

    private fun applyAudioTrack(rendererIndex: Int, groupIndex: Int, elementIndex: Int) {
        val mappedTrackInfo = trackSelector.currentMappedTrackInfo ?: return
        val override = TrackSelectionOverrides.TrackSelectionOverride(
            mappedTrackInfo.getTrackGroups(rendererIndex).get(groupIndex)
        )
        val builder = trackSelector.parameters.buildUpon()
            .setRendererDisabled(rendererIndex, false)
            .setTrackSelectionOverrides(
                TrackSelectionOverrides.Builder()
                    .addOverride(override)
                    .build()
            )
        trackSelector.setParameters(builder)
    }

    private fun sendSeekToEvent(positionMs: Long) {
        exoPlayer.seekTo(positionMs)
        eventSink.success(mapOf("event" to "seek", "position" to positionMs))
    }

    fun setMixWithOthers(mixWithOthers: Boolean) {
        setAudioAttributes(exoPlayer, mixWithOthers)
    }

    fun dispose() {
        disposeMediaSession()
        disposeRemoteNotifications()
        if (isInitialized) {
            exoPlayer.stop()
        }
        textureEntry.release()
        eventChannel.setStreamHandler(null)
        surface?.release()
        exoPlayer.release()
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other == null || javaClass != other.javaClass) return false
        val that = other as BetterPlayer
        if (exoPlayer != that.exoPlayer) return false
        return surface == that.surface
    }

    override fun hashCode(): Int {
        var result = exoPlayer.hashCode()
        result = 31 * result + (surface?.hashCode() ?: 0)
        return result
    }

    companion object {
        private const val TAG = "BetterPlayer"
        private const val FORMAT_SS = "ss"
        private const val FORMAT_DASH = "dash"
        private const val FORMAT_HLS = "hls"
        private const val FORMAT_OTHER = "other"
        private const val DEFAULT_NOTIFICATION_CHANNEL = "BETTER_PLAYER_NOTIFICATION"
        private const val NOTIFICATION_ID = 20772077

        // Clear cache by deleting betterPlayerCache folder
        fun clearCache(context: Context?, result: MethodChannel.Result) {
            try {
                context?.let {
                    val file = File(it.cacheDir, "betterPlayerCache")
                    deleteDirectory(file)
                }
                result.success(null)
            } catch (e: Exception) {
                Log.e(TAG, "Error clearing cache: $e")
                result.error("", "", "")
            }
        }

        private fun deleteDirectory(file: File) {
            if (file.isDirectory) {
                file.listFiles()?.forEach { deleteDirectory(it) }
            }
            if (!file.delete()) {
                Log.e(TAG, "Failed to delete cache directory")
            }
        }

        // Precache (enqueue CacheWorker via WorkManager)
        fun preCache(
            context: Context?,
            dataSource: String?,
            preCacheSize: Long,
            maxCacheSize: Long,
            maxCacheFileSize: Long,
            headers: Map<String, String?>,
            cacheKey: String?,
            result: MethodChannel.Result
        ) {
            val dataBuilder = Data.Builder()
                .putString(BetterPlayerPlugin.URL_PARAMETER, dataSource)
                .putLong(BetterPlayerPlugin.PRE_CACHE_SIZE_PARAMETER, preCacheSize)
                .putLong(BetterPlayerPlugin.MAX_CACHE_SIZE_PARAMETER, maxCacheSize)
                .putLong(BetterPlayerPlugin.MAX_CACHE_FILE_SIZE_PARAMETER, maxCacheFileSize)
            cacheKey?.let { dataBuilder.putString(BetterPlayerPlugin.CACHE_KEY_PARAMETER, it) }
            headers.forEach { (k, v) ->
                dataBuilder.putString(BetterPlayerPlugin.HEADER_PARAMETER + k, v)
            }
            if (!dataSource.isNullOrEmpty() && context != null) {
                val request = OneTimeWorkRequest.Builder(CacheWorker::class.java)
                    .addTag(dataSource)
                    .setInputData(dataBuilder.build())
                    .build()
                WorkManager.getInstance(context).enqueue(request)
            }
            result.success(null)
        }

        // Stop precache (cancel all jobs tagged with the given URL)
        fun stopPreCache(context: Context?, url: String?, result: MethodChannel.Result) {
            if (!url.isNullOrEmpty() && context != null) {
                WorkManager.getInstance(context).cancelAllWorkByTag(url)
            }
            result.success(null)
        }
    }
}
