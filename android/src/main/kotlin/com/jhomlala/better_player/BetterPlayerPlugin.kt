// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
package com.jhomlala.better_player

import android.app.Activity
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.Rect
import android.graphics.drawable.Icon
import android.media.MediaMetadata
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.support.v4.media.MediaMetadataCompat
import android.util.Log
import android.util.LongSparseArray
import android.util.Rational
import androidx.annotation.DrawableRes
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.google.android.exoplayer2.Player
import com.jhomlala.better_player.BetterPlayerCache.releaseCache
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.view.TextureRegistry

/**
 * Android platform implementation of the VideoPlayerPlugin.
 */
class BetterPlayerPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private val videoPlayers = LongSparseArray<BetterPlayer>()
    private val dataSources = LongSparseArray<Map<String, Any?>>()
    private var flutterState: FlutterState? = null
    private var currentNotificationTextureId: Long = -1
    private var currentNotificationDataSource: Map<String, Any?>? = null
    private var activity: Activity? = null
    private var pipHandler: Handler? = null
    private var pipRunnable: Runnable? = null
    private var currentPlayer: BetterPlayer? = null
    private var showPictureInPictureAutomatically: Boolean = false
    private val pipRemoteActions: ArrayList<RemoteAction> = ArrayList()
    private var isVideoPlaybackEnded: Boolean = false

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        val loader = FlutterLoader()
        flutterState = FlutterState(
            binding.applicationContext,
            binding.binaryMessenger, object : KeyForAssetFn {
                override fun get(asset: String?): String {
                    return loader.getLookupKeyForAsset(
                        asset!!
                    )
                }

            }, object : KeyForAssetAndPackageName {
                override fun get(asset: String?, packageName: String?): String {
                    return loader.getLookupKeyForAsset(
                        asset!!, packageName!!
                    )
                }
            },
            binding.textureRegistry
        )
        flutterState?.startListening(this)
    }


    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        if (flutterState == null) {
            Log.wtf(TAG, "Detached from the engine before registering to it.")
        }
        disposeAllPlayers()
        releaseCache()
        flutterState?.stopListening()
        flutterState = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        setLifeCycleObserverForPictureInPicture(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        setLifeCycleObserverForPictureInPicture(binding)
    }

    override fun onDetachedFromActivity() {}

    private fun setLifeCycleObserverForPictureInPicture(binding: ActivityPluginBinding) {
        val lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding)
        lifecycle.addObserver(LifecycleEventObserver { _, event ->
            Log.d("LifecycleEvent: ", event.toString())
            // Do enterPictureInPictureMode when can not use setAutoEnterEnabled.
            if (Build.VERSION_CODES.Q <= Build.VERSION.SDK_INT && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
                if (event == Lifecycle.Event.ON_PAUSE)
                    if (this.showPictureInPictureAutomatically && this.activity?.isInPictureInPictureMode != true) {
                        this.activity?.enterPictureInPictureMode(
                            createPictureInPictureParams(
                                pipRemoteActions
                            )
                        )
                    }
            }
            if (event == Lifecycle.Event.ON_DESTROY) {
                unregisterBroadcastReceiverForExternalAction()
                _notificationParameter.value = null
            }
        })
    }

    // To handle action while from outside the app.
    private val broadcastReceiverForExternalAction = object : BroadcastReceiver() {
        // Called when an item is clicked.
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null || intent.action != DW_NFC_BETTER_PLAYER_CUSTOM_ACTION) {
                return
            }
            when (intent.getIntExtra(EXTRA_ACTION_TYPE, 0)) {
                CustomActions.PLAY.rawValue -> {
                    currentPlayer?.tapExternalPlayButton()
                }
                CustomActions.PAUSE.rawValue -> {
                    currentPlayer?.tapExternalPauseButton()
                }
            }
        }
    }

    private fun registerBroadcastReceiverForExternalAction() {
        this.activity?.registerReceiver(
            broadcastReceiverForExternalAction,
            IntentFilter(DW_NFC_BETTER_PLAYER_CUSTOM_ACTION)
        )
    }

    private fun unregisterBroadcastReceiverForExternalAction() {
        try {
            this.activity?.unregisterReceiver(broadcastReceiverForExternalAction)
        } catch (e: Exception) {
            Log.d(TAG, "Error on unregisterReceiver. " + e.localizedMessage)
        }
    }

    private fun removeExternalPlayButton() {
        // Remove button on pip
        pipRemoteActions.clear()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity?.setPictureInPictureParams(createPictureInPictureParams(pipRemoteActions))
        }
        // Remove button on notification
        if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S) {
            currentPlayer?.setAsPlaybackStoppedToMediaSession()
        }
        _notificationActions.value = listOf()
        currentPlayer?.deactivateMediaSession()
    }

    private fun setAsVideoPlaybackEnded() {
        removeExternalPlayButton()
        isVideoPlaybackEnded = true
    }

    // Custom listener for exoPlayer event.
    // To change action in PIP mode or Notification based on playing status.
    private val playerEventListenerForIsPlayingChanged = object : Player.Listener {
        @RequiresApi(Build.VERSION_CODES.O)
        override fun onPlaybackStateChanged(playbackState: Int) {
            super.onPlaybackStateChanged(playbackState)
            if (playbackState == Player.STATE_ENDED) {
                setAsVideoPlaybackEnded()
            }
        }

        @RequiresApi(Build.VERSION_CODES.O)
        override fun onIsPlayingChanged(isPlaying: Boolean) {
            super.onIsPlayingChanged(isPlaying)
            // NOTE: `onIsPlayingChanged()` is executed after `onPlaybackStateChanged() at the end of video`.
            // So skip process when playback was over.
            if (isVideoPlaybackEnded) {
                return
            }
            pipRemoteActions.clear()
            flutterState?.applicationContext?.let { context ->
                val pendingIntent: PendingIntent?
                val buttonImageResourceId: Int?
                if (isPlaying) {
                    pendingIntent = createPendingIntentWithCustomAction(CustomActions.PAUSE)
                    buttonImageResourceId = R.drawable.exo_notification_pause
                } else {
                    pendingIntent = createPendingIntentWithCustomAction(CustomActions.PLAY)
                    buttonImageResourceId = R.drawable.exo_notification_play
                }
                pipRemoteActions.add(
                    createRemoteAction(
                        context,
                        buttonImageResourceId,
                        pendingIntent
                    )
                )
                val notificationAction = NotificationCompat.Action(
                    buttonImageResourceId, "",
                    pendingIntent
                )
                _notificationActions.value = listOf(notificationAction)
            }
            activity?.setPictureInPictureParams(createPictureInPictureParams(pipRemoteActions))
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createPendingIntentWithCustomAction(
        customAction: CustomActions
    ): PendingIntent {
        return PendingIntent.getBroadcast(
            flutterState?.applicationContext,
            customAction.rawValue,
            Intent(DW_NFC_BETTER_PLAYER_CUSTOM_ACTION).putExtra(
                EXTRA_ACTION_TYPE,
                customAction.rawValue
            ),
            PendingIntent.FLAG_IMMUTABLE
        )
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createRemoteAction(
        context: Context,
        @DrawableRes iconResId: Int,
        pendingIntent: PendingIntent
    ): RemoteAction {
        return RemoteAction(
            Icon.createWithResource(context, iconResId),
            "",
            "",
            pendingIntent
        )
    }

    private fun disposeAllPlayers() {
        for (i in 0 until videoPlayers.size()) {
            videoPlayers.valueAt(i).dispose()
        }
        videoPlayers.clear()
        dataSources.clear()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (flutterState == null || flutterState?.textureRegistry == null) {
            result.error("no_activity", "better_player plugin requires a foreground activity", null)
            return
        }
        when (call.method) {
            INIT_METHOD -> disposeAllPlayers()
            CREATE_METHOD -> {
                val handle = flutterState!!.textureRegistry!!.createSurfaceTexture()
                val eventChannel = EventChannel(
                    flutterState?.binaryMessenger, EVENTS_CHANNEL + handle.id()
                )
                var customDefaultLoadControl: CustomDefaultLoadControl? = null
                if (call.hasArgument(MIN_BUFFER_MS) && call.hasArgument(MAX_BUFFER_MS) &&
                    call.hasArgument(BUFFER_FOR_PLAYBACK_MS) &&
                    call.hasArgument(BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS)
                ) {
                    customDefaultLoadControl = CustomDefaultLoadControl(
                        call.argument(MIN_BUFFER_MS),
                        call.argument(MAX_BUFFER_MS),
                        call.argument(BUFFER_FOR_PLAYBACK_MS),
                        call.argument(BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS)
                    )
                }
                val player = BetterPlayer(
                    flutterState?.applicationContext!!, eventChannel, handle,
                    customDefaultLoadControl, result, playerEventListenerForIsPlayingChanged
                )

                videoPlayers.put(handle.id(), player)
                registerBroadcastReceiverForExternalAction()
            }
            PRE_CACHE_METHOD -> preCache(call, result)
            STOP_PRE_CACHE_METHOD -> stopPreCache(call, result)
            CLEAR_CACHE_METHOD -> clearCache(result)
            else -> {
                val textureId = (call.argument<Any>(TEXTURE_ID_PARAMETER) as Number?)!!.toLong()
                val player = videoPlayers[textureId]
                if (player == null) {
                    result.error(
                        "Unknown textureId",
                        "No video player associated with texture id $textureId",
                        null
                    )
                    return
                }
                onMethodCall(call, result, textureId, player)
            }
        }
    }

    private fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result,
        textureId: Long,
        player: BetterPlayer
    ) {
        when (call.method) {
            SET_DATA_SOURCE_METHOD -> {
                setDataSource(call, result, player)
            }
            SET_LOOPING_METHOD -> {
                player.setLooping(call.argument(LOOPING_PARAMETER)!!)
                result.success(null)
            }
            SET_VOLUME_METHOD -> {
                player.setVolume(call.argument(VOLUME_PARAMETER)!!)
                result.success(null)
            }
            PLAY_METHOD -> {
                currentPlayer = player
                isVideoPlaybackEnded = false
                setupNotification(player)
                player.play()
                result.success(null)
            }
            PAUSE_METHOD -> {
                player.pause()
                result.success(null)
            }
            BROADCAST_ENDED -> {
                setAsVideoPlaybackEnded()
                result.success(null)
            }
            SEEK_TO_METHOD -> {
                val location = (call.argument<Any>(LOCATION_PARAMETER) as Number?)!!.toInt()
                player.seekTo(location)
                result.success(null)
            }
            POSITION_METHOD -> {
                result.success(player.position)
                player.sendBufferingUpdate(false)
            }
            ABSOLUTE_POSITION_METHOD -> result.success(player.absolutePosition)
            GET_DVR_DURATION_METHOD -> {
                result.success(player.getDuration())
            }
            SET_SPEED_METHOD -> {
                player.setSpeed(call.argument(SPEED_PARAMETER)!!)
                result.success(null)
            }
            SET_TRACK_PARAMETERS_METHOD -> {
                player.setTrackParameters(
                    call.argument(WIDTH_PARAMETER)!!,
                    call.argument(HEIGHT_PARAMETER)!!,
                    call.argument(BITRATE_PARAMETER)!!
                )
                result.success(null)
            }
            SETUP_AUTOMATIC_PICTURE_IN_PICTURE_TRANSITION -> {
                val willStartPIP = call.argument<Boolean?>(WILL_START_PIP)!!
                setupAutomaticPictureInPictureTransition(willStartPIP)
                result.success(null)
            }
            ENABLE_PICTURE_IN_PICTURE_METHOD -> {
                enablePictureInPicture(player)
                result.success(null)
            }
            DISABLE_PICTURE_IN_PICTURE_METHOD -> {
                disablePictureInPicture(player)
                result.success(null)
            }
            IS_PICTURE_IN_PICTURE_SUPPORTED_METHOD -> result.success(
                isPictureInPictureSupported()
            )
            IS_PICTURE_IN_PICTURE -> result.success(
                activity!!.isInPictureInPictureMode
            )
            SET_AUDIO_TRACK_METHOD -> {
                val name = call.argument<String?>(NAME_PARAMETER)
                val index = call.argument<Int?>(INDEX_PARAMETER)
                if (name != null && index != null) {
                    player.setAudioTrack(name, index)
                }
                result.success(null)
            }
            SET_MIX_WITH_OTHERS_METHOD -> {
                val mixWitOthers = call.argument<Boolean?>(
                    MIX_WITH_OTHERS_PARAMETER
                )
                if (mixWitOthers != null) {
                    player.setMixWithOthers(mixWitOthers)
                }
            }
            DISPOSE_METHOD -> {
                dispose(player, textureId)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun setDataSource(
        call: MethodCall,
        result: MethodChannel.Result,
        player: BetterPlayer
    ) {
        val dataSource = call.argument<Map<String, Any?>>(DATA_SOURCE_PARAMETER)!!
        dataSources.put(getTextureId(player)!!, dataSource)
        val key = getParameter(dataSource, KEY_PARAMETER, "")
        val headers: Map<String, String> = getParameter(dataSource, HEADERS_PARAMETER, HashMap())
        val overriddenDuration: Number = getParameter(dataSource, OVERRIDDEN_DURATION_PARAMETER, 0)
        if (dataSource[ASSET_PARAMETER] != null) {
            val asset = getParameter(dataSource, ASSET_PARAMETER, "")
            val assetLookupKey: String = if (dataSource[PACKAGE_PARAMETER] != null) {
                val packageParameter = getParameter(
                    dataSource,
                    PACKAGE_PARAMETER,
                    ""
                )
                flutterState!!.keyForAssetAndPackageName[asset, packageParameter]
            } else {
                flutterState!!.keyForAsset[asset]
            }
            player.setDataSource(
                flutterState?.applicationContext!!,
                key,
                "asset:///$assetLookupKey",
                null,
                result,
                headers,
                false,
                0L,
                0L,
                overriddenDuration.toLong(),
                null,
                null, null, null
            )
        } else {
            val useCache = getParameter(dataSource, USE_CACHE_PARAMETER, false)
            val maxCacheSizeNumber: Number = getParameter(dataSource, MAX_CACHE_SIZE_PARAMETER, 0)
            val maxCacheFileSizeNumber: Number =
                getParameter(dataSource, MAX_CACHE_FILE_SIZE_PARAMETER, 0)
            val maxCacheSize = maxCacheSizeNumber.toLong()
            val maxCacheFileSize = maxCacheFileSizeNumber.toLong()
            val uri = getParameter(dataSource, URI_PARAMETER, "")
            val cacheKey = getParameter<String?>(dataSource, CACHE_KEY_PARAMETER, null)
            val formatHint = getParameter<String?>(dataSource, FORMAT_HINT_PARAMETER, null)
            val licenseUrl = getParameter<String?>(dataSource, LICENSE_URL_PARAMETER, null)
            val clearKey = getParameter<String?>(dataSource, DRM_CLEARKEY_PARAMETER, null)
            val drmHeaders: Map<String, String> =
                getParameter(dataSource, DRM_HEADERS_PARAMETER, HashMap())
            player.setDataSource(
                flutterState!!.applicationContext,
                key,
                uri,
                formatHint,
                result,
                headers,
                useCache,
                maxCacheSize,
                maxCacheFileSize,
                overriddenDuration.toLong(),
                licenseUrl,
                drmHeaders,
                cacheKey,
                clearKey
            )
        }
    }

    /**
     * Start pre cache of video.
     *
     * @param call   - invoked method data
     * @param result - result which should be updated
     */
    private fun preCache(call: MethodCall, result: MethodChannel.Result) {
        val dataSource = call.argument<Map<String, Any?>>(DATA_SOURCE_PARAMETER)
        if (dataSource != null) {
            val maxCacheSizeNumber: Number =
                getParameter(dataSource, MAX_CACHE_SIZE_PARAMETER, 100 * 1024 * 1024)
            val maxCacheFileSizeNumber: Number =
                getParameter(dataSource, MAX_CACHE_FILE_SIZE_PARAMETER, 10 * 1024 * 1024)
            val maxCacheSize = maxCacheSizeNumber.toLong()
            val maxCacheFileSize = maxCacheFileSizeNumber.toLong()
            val preCacheSizeNumber: Number =
                getParameter(dataSource, PRE_CACHE_SIZE_PARAMETER, 3 * 1024 * 1024)
            val preCacheSize = preCacheSizeNumber.toLong()
            val uri = getParameter(dataSource, URI_PARAMETER, "")
            val cacheKey = getParameter<String?>(dataSource, CACHE_KEY_PARAMETER, null)
            val headers: Map<String, String> =
                getParameter(dataSource, HEADERS_PARAMETER, HashMap())
            BetterPlayer.preCache(
                flutterState?.applicationContext,
                uri,
                preCacheSize,
                maxCacheSize,
                maxCacheFileSize,
                headers,
                cacheKey,
                result
            )
        }
    }

    /**
     * Stop pre cache video process (if exists).
     *
     * @param call   - invoked method data
     * @param result - result which should be updated
     */
    private fun stopPreCache(call: MethodCall, result: MethodChannel.Result) {
        val url = call.argument<String>(URL_PARAMETER)
        BetterPlayer.stopPreCache(flutterState?.applicationContext, url, result)
    }

    private fun clearCache(result: MethodChannel.Result) {
        BetterPlayer.clearCache(flutterState?.applicationContext, result)
    }

    private fun getTextureId(betterPlayer: BetterPlayer): Long? {
        for (index in 0 until videoPlayers.size()) {
            if (betterPlayer === videoPlayers.valueAt(index)) {
                return videoPlayers.keyAt(index)
            }
        }
        return null
    }

    private fun setupNotification(betterPlayer: BetterPlayer) {
        try {
            getTextureId(betterPlayer)?.let { textureId ->
                val dataSource = dataSources[textureId]
                val showNotification = getParameter(dataSource, SHOW_NOTIFICATION_PARAMETER, false)
                if (showNotification) {
                    //Don't setup notification for the same source.
                    if (textureId == currentNotificationTextureId && currentNotificationDataSource != null && dataSource != null && currentNotificationDataSource === dataSource) {
                        // In case replay video after once ended, reactivate media session.
                        betterPlayer.reactivateMediaSessionIfNeeded()
                        return
                    }
                    currentNotificationDataSource = dataSource
                    currentNotificationTextureId = textureId
                    removeOtherNotificationListeners()
                    setupNotificationParameter(dataSource, betterPlayer)
                    // For Android 13 or later.
                    if (Build.VERSION.SDK_INT > Build.VERSION_CODES.S) {
                        // NOTE: Not so sure why but setting call back needs to be done after notification setting.
                        // Otherwise the callback was not called.
                        betterPlayer.setMediaSessionCallback()
                    }
                }
            }
        } catch (exception: Exception) {
            Log.e(TAG, "SetupNotification failed", exception)
        }
    }

    private fun setupNotificationParameter(
        dataSource: Map<String, Any?>,
        betterPlayer: BetterPlayer
    ) {
        flutterState?.applicationContext?.let { context ->
            val title = getParameter(dataSource, TITLE_PARAMETER, "")
            val author = getParameter(dataSource, AUTHOR_PARAMETER, "")
            val mediaSession = betterPlayer.setupMediaSession(context, title = title, author = author)
            mediaSession?.let {
                if (Build.MANUFACTURER.lowercase() == "samsung" && Build.VERSION.SDK_INT == Build.VERSION_CODES.R) {
                    // VOD
                    // Samsung devices with android 11 
                    // https://dw-ml-nfc.atlassian.net/browse/DAF-4294
                    it.setMetadata(
                        MediaMetadataCompat.Builder()
                            .putString(MediaMetadata.METADATA_KEY_ARTIST, author)
                            .putString(MediaMetadata.METADATA_KEY_TITLE, title)
                            .build()
                    )
                }
                _notificationParameter.value = NotificationParameter(
                    title = title,
                    author = author,
                    imageUrl = getParameter(dataSource, IMAGE_URL_PARAMETER, ""),
                    notificationChannelName = getParameter(
                        dataSource,
                        NOTIFICATION_CHANNEL_NAME_PARAMETER,
                        ""
                    ),
                    activityName = getParameter(
                        dataSource,
                        ACTIVITY_NAME_PARAMETER,
                        "MainActivity"
                    ),
                    mediaSessionToken = mediaSession.sessionToken
                )
            }
        }
    }

    private fun removeOtherNotificationListeners() {
        for (index in 0 until videoPlayers.size()) {
            videoPlayers.valueAt(index).disposeRemoteNotifications()
        }
    }

    @Suppress("UNCHECKED_CAST")
    private fun <T> getParameter(parameters: Map<String, Any?>?, key: String, defaultValue: T): T {
        if (parameters?.containsKey(key) == true) {
            val value = parameters[key]
            if (value != null) {
                return value as T
            }
        }
        return defaultValue
    }


    private fun isPictureInPictureSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && activity != null && activity!!.packageManager
            .hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun setupAutomaticPictureInPictureTransition(
        willStartPIP: Boolean,
    ) {
        showPictureInPictureAutomatically = willStartPIP
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            activity?.setPictureInPictureParams(
                createPictureInPictureParams(
                    pipRemoteActions,
                    willStartPIP
                )
            )
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createPictureInPictureParams(
        actions: List<RemoteAction>,
        willAutoEnter: Boolean? = null
    ): PictureInPictureParams {
        val pipParamsBuilder = PictureInPictureParams.Builder()
            .setAspectRatio(PIP_ASPECT_RATIO)
            .setSourceRectHint(Rect())
            .setActions(actions)
        if (willAutoEnter != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // `setAutoEnterEnabled` only available from Build.VERSION_CODES.S(Android12)
            pipParamsBuilder.setAutoEnterEnabled(willAutoEnter)
        }
        return pipParamsBuilder.build()
    }

    private fun enablePictureInPicture(player: BetterPlayer) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            player.setupMediaSession(flutterState!!.applicationContext)
            activity!!.enterPictureInPictureMode(PictureInPictureParams.Builder().build())
            startPictureInPictureListenerTimer(player)
            player.onPictureInPictureStatusChanged(true)
        }
    }

    private fun disablePictureInPicture(player: BetterPlayer) {
        stopPipHandler()
        activity!!.moveTaskToBack(false)
        player.onPictureInPictureStatusChanged(false)
        player.disposeMediaSession()
    }

    private fun startPictureInPictureListenerTimer(player: BetterPlayer) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            pipHandler = Handler(Looper.getMainLooper())
            pipRunnable = Runnable {
                if (activity!!.isInPictureInPictureMode) {
                    pipHandler!!.postDelayed(pipRunnable!!, 100)
                } else {
                    player.onPictureInPictureStatusChanged(false)
                    player.disposeMediaSession()
                    stopPipHandler()
                }
            }
            pipHandler!!.post(pipRunnable!!)
        }
    }

    private fun dispose(player: BetterPlayer, textureId: Long) {
        currentPlayer = null
        _notificationParameter.value = null
        player.dispose()
        videoPlayers.remove(textureId)
        dataSources.remove(textureId)
        setupAutomaticPictureInPictureTransition(false)
        unregisterBroadcastReceiverForExternalAction()
        stopPipHandler()
    }

    private fun stopPipHandler() {
        if (pipHandler != null) {
            pipHandler!!.removeCallbacksAndMessages(null)
            pipHandler = null
        }
        pipRunnable = null
    }

    private interface KeyForAssetFn {
        operator fun get(asset: String?): String
    }

    private interface KeyForAssetAndPackageName {
        operator fun get(asset: String?, packageName: String?): String
    }

    private class FlutterState(
        val applicationContext: Context,
        val binaryMessenger: BinaryMessenger,
        val keyForAsset: KeyForAssetFn,
        val keyForAssetAndPackageName: KeyForAssetAndPackageName,
        val textureRegistry: TextureRegistry?
    ) {
        private val methodChannel: MethodChannel = MethodChannel(binaryMessenger, CHANNEL)

        fun startListening(methodCallHandler: BetterPlayerPlugin?) {
            methodChannel.setMethodCallHandler(methodCallHandler)
        }

        fun stopListening() {
            methodChannel.setMethodCallHandler(null)
        }

    }

    companion object {
        private const val TAG = "BetterPlayerPlugin"
        private const val CHANNEL = "better_player_channel"
        private const val EVENTS_CHANNEL = "better_player_channel/videoEvents"
        private const val DATA_SOURCE_PARAMETER = "dataSource"
        private const val KEY_PARAMETER = "key"
        private const val HEADERS_PARAMETER = "headers"
        private const val USE_CACHE_PARAMETER = "useCache"
        private const val ASSET_PARAMETER = "asset"
        private const val PACKAGE_PARAMETER = "package"
        private const val URI_PARAMETER = "uri"
        private const val FORMAT_HINT_PARAMETER = "formatHint"
        private const val TEXTURE_ID_PARAMETER = "textureId"
        private const val LOOPING_PARAMETER = "looping"
        private const val VOLUME_PARAMETER = "volume"
        private const val LOCATION_PARAMETER = "location"
        private const val SPEED_PARAMETER = "speed"
        private const val WIDTH_PARAMETER = "width"
        private const val HEIGHT_PARAMETER = "height"
        private const val BITRATE_PARAMETER = "bitrate"
        private const val SHOW_NOTIFICATION_PARAMETER = "showNotification"
        private const val OVERRIDDEN_DURATION_PARAMETER = "overriddenDuration"
        private const val NAME_PARAMETER = "name"
        private const val INDEX_PARAMETER = "index"
        private const val LICENSE_URL_PARAMETER = "licenseUrl"
        private const val DRM_HEADERS_PARAMETER = "drmHeaders"
        private const val DRM_CLEARKEY_PARAMETER = "clearKey"
        private const val MIX_WITH_OTHERS_PARAMETER = "mixWithOthers"
        private const val WILL_START_PIP = "willStartPIP"
        const val TITLE_PARAMETER = "title"
        const val AUTHOR_PARAMETER = "author"
        const val IMAGE_URL_PARAMETER = "imageUrl"
        const val NOTIFICATION_CHANNEL_NAME_PARAMETER = "notificationChannelName"
        const val URL_PARAMETER = "url"
        const val PRE_CACHE_SIZE_PARAMETER = "preCacheSize"
        const val MAX_CACHE_SIZE_PARAMETER = "maxCacheSize"
        const val MAX_CACHE_FILE_SIZE_PARAMETER = "maxCacheFileSize"
        const val HEADER_PARAMETER = "header_"
        const val FILE_PATH_PARAMETER = "filePath"
        const val ACTIVITY_NAME_PARAMETER = "activityName"
        const val MIN_BUFFER_MS = "minBufferMs"
        const val MAX_BUFFER_MS = "maxBufferMs"
        const val BUFFER_FOR_PLAYBACK_MS = "bufferForPlaybackMs"
        const val BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS = "bufferForPlaybackAfterRebufferMs"
        const val CACHE_KEY_PARAMETER = "cacheKey"
        const val MEDIA_SESSION_TOKEN_PARAMETER = "mediaSessionToken"
        private const val INIT_METHOD = "init"
        private const val CREATE_METHOD = "create"
        private const val SET_DATA_SOURCE_METHOD = "setDataSource"
        private const val SET_LOOPING_METHOD = "setLooping"
        private const val SET_VOLUME_METHOD = "setVolume"
        private const val PLAY_METHOD = "play"
        private const val PAUSE_METHOD = "pause"
        private const val BROADCAST_ENDED = "broadcastEnded"
        private const val SEEK_TO_METHOD = "seekTo"
        private const val POSITION_METHOD = "position"
        private const val GET_DVR_DURATION_METHOD = "getDvrDuration"
        private const val ABSOLUTE_POSITION_METHOD = "absolutePosition"
        private const val SET_SPEED_METHOD = "setSpeed"
        private const val SET_TRACK_PARAMETERS_METHOD = "setTrackParameters"
        private const val SET_AUDIO_TRACK_METHOD = "setAudioTrack"
        private const val SETUP_AUTOMATIC_PICTURE_IN_PICTURE_TRANSITION =
            "setupAutomaticPictureInPictureTransition"
        private const val ENABLE_PICTURE_IN_PICTURE_METHOD = "enablePictureInPicture"
        private const val DISABLE_PICTURE_IN_PICTURE_METHOD = "disablePictureInPicture"
        private const val IS_PICTURE_IN_PICTURE_SUPPORTED_METHOD = "isPictureInPictureSupported"
        private const val IS_PICTURE_IN_PICTURE = "isPictureInPicture"
        private const val SET_MIX_WITH_OTHERS_METHOD = "setMixWithOthers"
        private const val CLEAR_CACHE_METHOD = "clearCache"
        private const val DISPOSE_METHOD = "dispose"
        private const val PRE_CACHE_METHOD = "preCache"
        private const val STOP_PRE_CACHE_METHOD = "stopPreCache"
        private val PIP_ASPECT_RATIO = Rational(16, 9)

        /** For custom action from outside the app */
        const val DW_NFC_BETTER_PLAYER_CUSTOM_ACTION =
            "better_player.nfc_ch_app/custom_action"
        const val EXTRA_ACTION_TYPE = "extra_action_type"

        enum class CustomActions(val rawValue: Int) {
            PLAY(1),
            PAUSE(2)
        }

        // Will be observed to show notification.
        private var _notificationParameter: MutableLiveData<NotificationParameter?> = MutableLiveData()
        val notificationParameter: LiveData<NotificationParameter?> get() = _notificationParameter
        // Will be observed to update action in notification.
        private var _notificationActions: MutableLiveData<List<NotificationCompat.Action>?> =
            MutableLiveData()
        val notificationActions: LiveData<List<NotificationCompat.Action>?> get() = _notificationActions
    }
}