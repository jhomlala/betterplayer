// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.jhomlala.better_player;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Handler;
import android.util.Log;
import android.util.LongSparseArray;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.loader.FlutterLoader;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.view.TextureRegistry;

import java.util.HashMap;
import java.util.Map;

/**
 * Android platform implementation of the VideoPlayerPlugin.
 */
public class BetterPlayerPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {
    private static final String TAG = "BetterPlayerPlugin";
    private static final String CHANNEL = "better_player_channel";
    private static final String EVENTS_CHANNEL = "better_player_channel/videoEvents";
    private static final String DATA_SOURCE_PARAMETER = "dataSource";
    private static final String KEY_PARAMETER = "key";
    private static final String HEADERS_PARAMETER = "headers";
    private static final String USE_CACHE_PARAMETER = "useCache";


    private static final String ASSET_PARAMETER = "asset";
    private static final String PACKAGE_PARAMETER = "package";
    private static final String URI_PARAMETER = "uri";
    private static final String FORMAT_HINT_PARAMETER = "formatHint";
    private static final String TEXTURE_ID_PARAMETER = "textureId";
    private static final String LOOPING_PARAMETER = "looping";
    private static final String VOLUME_PARAMETER = "volume";
    private static final String LOCATION_PARAMETER = "location";
    private static final String SPEED_PARAMETER = "speed";
    private static final String WIDTH_PARAMETER = "width";
    private static final String HEIGHT_PARAMETER = "height";
    private static final String BITRATE_PARAMETER = "bitrate";
    private static final String SHOW_NOTIFICATION_PARAMETER = "showNotification";
    private static final String TITLE_PARAMETER = "title";
    private static final String AUTHOR_PARAMETER = "author";
    private static final String IMAGE_URL_PARAMETER = "imageUrl";
    private static final String NOTIFICATION_CHANNEL_NAME_PARAMETER = "notificationChannelName";
    private static final String OVERRIDDEN_DURATION_PARAMETER = "overriddenDuration";
    private static final String NAME_PARAMETER = "name";
    private static final String INDEX_PARAMETER = "index";
    private static final String LICENSE_URL_PARAMETER = "licenseUrl";
    private static final String DRM_HEADERS_PARAMETER = "drmHeaders";
    private static final String MIX_WITH_OTHERS_PARAMETER = "mixWithOthers";
    public static final String URL_PARAMETER = "url";
    public static final String PRE_CACHE_SIZE_PARAMETER = "preCacheSize";
    public static final String MAX_CACHE_SIZE_PARAMETER = "maxCacheSize";
    public static final String MAX_CACHE_FILE_SIZE_PARAMETER = "maxCacheFileSize";
    public static final String HEADER_PARAMETER = "header_";
    public static final String FILE_PATH_PARAMETER = "filePath";
    public static final String ACTIVITY_NAME_PARAMETER = "activityName";
    public static final String CACHE_KEY_PARAMETER = "cacheKey";


    private static final String INIT_METHOD = "init";
    private static final String CREATE_METHOD = "create";
    private static final String SET_DATA_SOURCE_METHOD = "setDataSource";
    private static final String SET_LOOPING_METHOD = "setLooping";
    private static final String SET_VOLUME_METHOD = "setVolume";
    private static final String PLAY_METHOD = "play";
    private static final String PAUSE_METHOD = "pause";
    private static final String SEEK_TO_METHOD = "seekTo";
    private static final String POSITION_METHOD = "position";
    private static final String ABSOLUTE_POSITION_METHOD = "absolutePosition";
    private static final String SET_SPEED_METHOD = "setSpeed";
    private static final String SET_TRACK_PARAMETERS_METHOD = "setTrackParameters";
    private static final String SET_AUDIO_TRACK_METHOD = "setAudioTrack";
    private static final String ENABLE_PICTURE_IN_PICTURE_METHOD = "enablePictureInPicture";
    private static final String DISABLE_PICTURE_IN_PICTURE_METHOD = "disablePictureInPicture";
    private static final String IS_PICTURE_IN_PICTURE_SUPPORTED_METHOD = "isPictureInPictureSupported";
    private static final String SET_MIX_WITH_OTHERS_METHOD = "setMixWithOthers";
    private static final String CLEAR_CACHE_METHOD = "clearCache";
    private static final String DISPOSE_METHOD = "dispose";
    private static final String PRE_CACHE_METHOD = "preCache";
    private static final String STOP_PRE_CACHE_METHOD = "stopPreCache";

    private final LongSparseArray<BetterPlayer> videoPlayers = new LongSparseArray<>();
    private final LongSparseArray<Map<String, Object>> dataSources = new LongSparseArray<>();
    private FlutterState flutterState;
    private long currentNotificationTextureId = -1;
    private Map<String, Object> currentNotificationDataSource;
    private Activity activity;
    private Handler pipHandler;
    private Runnable pipRunnable;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        FlutterLoader loader = new FlutterLoader();
        this.flutterState =
                new FlutterState(
                        binding.getApplicationContext(),
                        binding.getBinaryMessenger(),
                        loader::getLookupKeyForAsset,
                        loader::getLookupKeyForAsset,
                        binding.getTextureRegistry());
        flutterState.startListening(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (flutterState == null) {
            Log.wtf(TAG, "Detached from the engine before registering to it.");
        }
        disposeAllPlayers();
        BetterPlayerCache.releaseCache();
        flutterState.stopListening();
        flutterState = null;
    }

    private void disposeAllPlayers() {
        for (int i = 0; i < videoPlayers.size(); i++) {
            videoPlayers.valueAt(i).dispose();
        }
        videoPlayers.clear();
        dataSources.clear();
    }


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (flutterState == null || flutterState.textureRegistry == null) {
            result.error("no_activity", "better_player plugin requires a foreground activity", null);
            return;
        }


        switch (call.method) {
            case INIT_METHOD:
                disposeAllPlayers();
                break;
            case CREATE_METHOD: {
                TextureRegistry.SurfaceTextureEntry handle =
                        flutterState.textureRegistry.createSurfaceTexture();

                EventChannel eventChannel =
                        new EventChannel(
                                flutterState.binaryMessenger, EVENTS_CHANNEL + handle.id());

                BetterPlayer player =
                        new BetterPlayer(flutterState.applicationContext, eventChannel, handle, result);

                videoPlayers.put(handle.id(), player);
                break;
            }
            case PRE_CACHE_METHOD:
                preCache(call, result);
                break;
            case STOP_PRE_CACHE_METHOD:
                stopPreCache(call, result);
                break;
            case CLEAR_CACHE_METHOD:
                clearCache(result);
                break;
            default: {
                long textureId = ((Number) call.argument(TEXTURE_ID_PARAMETER)).longValue();
                BetterPlayer player = videoPlayers.get(textureId);

                if (player == null) {
                    result.error(
                            "Unknown textureId",
                            "No video player associated with texture id " + textureId,
                            null);
                    return;
                }
                onMethodCall(call, result, textureId, player);
                break;
            }
        }
    }

    private void onMethodCall(MethodCall call, Result result, long textureId, BetterPlayer player) {
        switch (call.method) {
            case SET_DATA_SOURCE_METHOD: {
                setDataSource(call, result, player);
                break;
            }
            case SET_LOOPING_METHOD:
                player.setLooping(call.argument(LOOPING_PARAMETER));
                result.success(null);
                break;
            case SET_VOLUME_METHOD:
                player.setVolume(call.argument(VOLUME_PARAMETER));
                result.success(null);
                break;
            case PLAY_METHOD:
                setupNotification(player);
                player.play();
                result.success(null);
                break;
            case PAUSE_METHOD:
                player.pause();
                result.success(null);
                break;
            case SEEK_TO_METHOD:
                int location = ((Number) call.argument(LOCATION_PARAMETER)).intValue();
                player.seekTo(location);
                result.success(null);
                break;
            case POSITION_METHOD:
                result.success(player.getPosition());
                player.sendBufferingUpdate();
                break;
            case ABSOLUTE_POSITION_METHOD:
                result.success(player.getAbsolutePosition());
                break;
            case SET_SPEED_METHOD:
                player.setSpeed(call.argument(SPEED_PARAMETER));
                result.success(null);
                break;
            case SET_TRACK_PARAMETERS_METHOD:
                player.setTrackParameters(
                        call.argument(WIDTH_PARAMETER),
                        call.argument(HEIGHT_PARAMETER),
                        call.argument(BITRATE_PARAMETER));
                result.success(null);
                break;
            case ENABLE_PICTURE_IN_PICTURE_METHOD:
                enablePictureInPicture(player);
                result.success(null);
                break;

            case DISABLE_PICTURE_IN_PICTURE_METHOD:
                disablePictureInPicture(player);
                result.success(null);
                break;

            case IS_PICTURE_IN_PICTURE_SUPPORTED_METHOD:
                result.success(isPictureInPictureSupported());
                break;

            case SET_AUDIO_TRACK_METHOD:
                player.setAudioTrack(call.argument(NAME_PARAMETER), call.argument(INDEX_PARAMETER));
                result.success(null);
                break;
            case SET_MIX_WITH_OTHERS_METHOD:
                player.setMixWithOthers(call.argument(MIX_WITH_OTHERS_PARAMETER));
                break;
            case DISPOSE_METHOD:
                dispose(player, textureId);
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }


    private void setDataSource(MethodCall call, Result result, BetterPlayer player) {
        Map<String, Object> dataSource = call.argument(DATA_SOURCE_PARAMETER);

        dataSources.put(getTextureId(player), dataSource);
        String key = getParameter(dataSource, KEY_PARAMETER, "");
        Map<String, String> headers = getParameter(dataSource, HEADERS_PARAMETER, new HashMap<>());
        Number overriddenDuration = getParameter(dataSource, OVERRIDDEN_DURATION_PARAMETER, 0);

        if (dataSource.get(ASSET_PARAMETER) != null) {
            String asset = getParameter(dataSource, ASSET_PARAMETER, "");
            String assetLookupKey;
            if (dataSource.get(PACKAGE_PARAMETER) != null) {
                String packageParameter = getParameter(dataSource, PACKAGE_PARAMETER, "");
                assetLookupKey =
                        flutterState.keyForAssetAndPackageName.get(asset, packageParameter);
            } else {
                assetLookupKey = flutterState.keyForAsset.get(asset);
            }

            player.setDataSource(
                    flutterState.applicationContext,
                    key,
                    "asset:///" + assetLookupKey,
                    null,
                    result,
                    headers,
                    false,
                    0L,
                    0L,
                    overriddenDuration.longValue(),
                    null,
                    null, null
            );
        } else {
            boolean useCache = getParameter(dataSource, USE_CACHE_PARAMETER, false);
            Number maxCacheSizeNumber = getParameter(dataSource, MAX_CACHE_SIZE_PARAMETER, 0);
            Number maxCacheFileSizeNumber = getParameter(dataSource, MAX_CACHE_FILE_SIZE_PARAMETER, 0);
            long maxCacheSize = maxCacheSizeNumber.longValue();
            long maxCacheFileSize = maxCacheFileSizeNumber.longValue();
            String uri = getParameter(dataSource, URI_PARAMETER, "");
            String cacheKey = getParameter(dataSource, CACHE_KEY_PARAMETER, null);
            String formatHint = getParameter(dataSource, FORMAT_HINT_PARAMETER, null);
            String licenseUrl = getParameter(dataSource, LICENSE_URL_PARAMETER, null);
            Map<String, String> drmHeaders = getParameter(dataSource, DRM_HEADERS_PARAMETER, new HashMap<>());
            player.setDataSource(
                    flutterState.applicationContext,
                    key,
                    uri,
                    formatHint,
                    result,
                    headers,
                    useCache,
                    maxCacheSize,
                    maxCacheFileSize,
                    overriddenDuration.longValue(),
                    licenseUrl,
                    drmHeaders,
                    cacheKey
            );
        }
    }

    /**
     * Start pre cache of video.
     *
     * @param call   - invoked method data
     * @param result - result which should be updated
     */
    private void preCache(MethodCall call, Result result) {
        Map<String, Object> dataSource = call.argument(DATA_SOURCE_PARAMETER);
        if (dataSource != null) {
            Number maxCacheSizeNumber = getParameter(dataSource, MAX_CACHE_SIZE_PARAMETER, 100 * 1024 * 1024);
            Number maxCacheFileSizeNumber = getParameter(dataSource, MAX_CACHE_FILE_SIZE_PARAMETER, 10 * 1024 * 1024);
            long maxCacheSize = maxCacheSizeNumber.longValue();
            long maxCacheFileSize = maxCacheFileSizeNumber.longValue();
            Number preCacheSizeNumber = getParameter(dataSource, PRE_CACHE_SIZE_PARAMETER, 3 * 1024 * 1024);
            long preCacheSize = preCacheSizeNumber.longValue();
            String uri = getParameter(dataSource, URI_PARAMETER, "");
            String cacheKey = getParameter(dataSource, CACHE_KEY_PARAMETER, null);
            Map<String, String> headers = getParameter(dataSource, HEADERS_PARAMETER, new HashMap<>());

            BetterPlayer.preCache(flutterState.applicationContext,
                    uri,
                    preCacheSize,
                    maxCacheSize,
                    maxCacheFileSize,
                    headers,
                    cacheKey,
                    result
            );
        }
    }

    /**
     * Stop pre cache video process (if exists).
     *
     * @param call   - invoked method data
     * @param result - result which should be updated
     */
    private void stopPreCache(MethodCall call, Result result) {
        String url = call.argument(URL_PARAMETER);
        BetterPlayer.stopPreCache(flutterState.applicationContext, url, result);
    }

    private void clearCache(Result result) {
        BetterPlayer.clearCache(flutterState.applicationContext, result);
    }

    private Long getTextureId(BetterPlayer betterPlayer) {
        for (int index = 0; index < videoPlayers.size(); index++) {
            if (betterPlayer == videoPlayers.valueAt(index)) {
                return videoPlayers.keyAt(index);
            }
        }
        return null;
    }

    private void setupNotification(BetterPlayer betterPlayer) {
        try {
            Long textureId = getTextureId(betterPlayer);
            if (textureId != null) {
                Map<String, Object> dataSource = dataSources.get(textureId);
                //Don't setup notification for the same source.
                if (textureId == currentNotificationTextureId
                        && currentNotificationDataSource != null
                        && dataSource != null
                        && currentNotificationDataSource == dataSource) {
                    return;
                }
                currentNotificationDataSource = dataSource;
                currentNotificationTextureId = textureId;
                removeOtherNotificationListeners();
                boolean showNotification = getParameter(dataSource, SHOW_NOTIFICATION_PARAMETER, false);
                if (showNotification) {
                    String title = getParameter(dataSource, TITLE_PARAMETER, "");
                    String author = getParameter(dataSource, AUTHOR_PARAMETER, "");
                    String imageUrl = getParameter(dataSource, IMAGE_URL_PARAMETER, "");
                    String notificationChannelName = getParameter(dataSource, NOTIFICATION_CHANNEL_NAME_PARAMETER, null);
                    String activityName = getParameter(dataSource, ACTIVITY_NAME_PARAMETER, "MainActivity");
                    betterPlayer.setupPlayerNotification(flutterState.applicationContext,
                            title, author, imageUrl, notificationChannelName, activityName);
                }
            }
        } catch (Exception exception) {
            Log.e(TAG, "SetupNotification failed", exception);
        }
    }

    private void removeOtherNotificationListeners() {
        for (int index = 0; index < videoPlayers.size(); index++) {
            videoPlayers.valueAt(index).disposeRemoteNotifications();
        }
    }

    @SuppressWarnings("unchecked")
    private <T> T getParameter(Map<String, Object> parameters, String key, T defaultValue) {
        if (parameters.containsKey(key)) {
            Object value = parameters.get(key);
            if (value != null) {
                return (T) value;
            }
        }
        return defaultValue;
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    }

    @Override
    public void onDetachedFromActivity() {
    }

    private boolean isPictureInPictureSupported() {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && activity != null
                && activity.getPackageManager()
                .hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE);
    }

    private void enablePictureInPicture(BetterPlayer player) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            player.setupMediaSession(flutterState.applicationContext, true);
            activity.enterPictureInPictureMode(new PictureInPictureParams.Builder().build());
            startPictureInPictureListenerTimer(player);
            player.onPictureInPictureStatusChanged(true);
        }
    }

    private void disablePictureInPicture(BetterPlayer player) {
        stopPipHandler();
        activity.moveTaskToBack(false);
        player.onPictureInPictureStatusChanged(false);
        player.disposeMediaSession();
    }

    private void startPictureInPictureListenerTimer(BetterPlayer player) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            pipHandler = new Handler();
            pipRunnable = () -> {
                if (activity.isInPictureInPictureMode()) {
                    pipHandler.postDelayed(pipRunnable, 100);
                } else {
                    player.onPictureInPictureStatusChanged(false);
                    player.disposeMediaSession();
                    stopPipHandler();
                }
            };
            pipHandler.post(pipRunnable);
        }
    }

    private void dispose(BetterPlayer player, long textureId) {
        player.dispose();
        videoPlayers.remove(textureId);
        dataSources.remove(textureId);
        stopPipHandler();
    }

    private void stopPipHandler() {
        if (pipHandler != null) {
            pipHandler.removeCallbacksAndMessages(null);
            pipHandler = null;
        }
        pipRunnable = null;
    }

    private interface KeyForAssetFn {
        String get(String asset);
    }

    private interface KeyForAssetAndPackageName {
        String get(String asset, String packageName);
    }

    private static final class FlutterState {
        private final Context applicationContext;
        private final BinaryMessenger binaryMessenger;
        private final KeyForAssetFn keyForAsset;
        private final KeyForAssetAndPackageName keyForAssetAndPackageName;
        private final TextureRegistry textureRegistry;
        private final MethodChannel methodChannel;

        FlutterState(
                Context applicationContext,
                BinaryMessenger messenger,
                KeyForAssetFn keyForAsset,
                KeyForAssetAndPackageName keyForAssetAndPackageName,
                TextureRegistry textureRegistry) {
            this.applicationContext = applicationContext;
            this.binaryMessenger = messenger;
            this.keyForAsset = keyForAsset;
            this.keyForAssetAndPackageName = keyForAssetAndPackageName;
            this.textureRegistry = textureRegistry;
            methodChannel = new MethodChannel(messenger, CHANNEL);
        }

        void startListening(BetterPlayerPlugin methodCallHandler) {
            methodChannel.setMethodCallHandler(methodCallHandler);
        }

        void stopListening() {
            methodChannel.setMethodCallHandler(null);
        }
    }
}
