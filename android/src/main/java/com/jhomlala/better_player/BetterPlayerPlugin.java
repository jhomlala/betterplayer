// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package com.jhomlala.better_player;

import android.content.Context;
import android.util.Log;
import android.util.LongSparseArray;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterMain;
import io.flutter.view.TextureRegistry;

import java.util.HashMap;
import java.util.Map;

/**
 * Android platform implementation of the VideoPlayerPlugin.
 */
public class BetterPlayerPlugin implements MethodCallHandler, FlutterPlugin {
    private static final String TAG = "BetterPlayerPlugin";
    private static final String CHANNEL = "better_player_channel";
    private static final String EVENTS_CHANNEL = "better_player_channel/videoEvents";
    private static final String DATA_SOURCE_PARAMETER = "dataSource";
    private static final String KEY_PARAMETER = "key";
    private static final String HEADERS_PARAMETER = "headers";
    private static final String USE_CACHE_PARAMETER = "useCache";
    private static final String MAX_CACHE_SIZE_PARAMETER = "maxCacheSize";
    private static final String MAX_CACHE_FILE_SIZE_PARAMETER = "maxCacheFileSize";
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

    private static final String INIT_METHOD = "init";
    private static final String CREATE_METHOD = "create";
    private static final String SET_DATA_SOURCE_METHOD = "setDataSource";
    private static final String SET_LOOPING_METHOD = "setLooping";
    private static final String SET_VOLUME_METHOD = "setVolume";
    private static final String PLAY_METHOD = "play";
    private static final String PAUSE_METHOD = "pause";
    private static final String SEEK_TO_METHOD = "seekTo";
    private static final String POSITION_METHOD = "position";
    private static final String SET_SPEED_METHOD = "setSpeed";
    private static final String SET_TRACK_PARAMETERS_METHOD = "setTrackParameters";
    private static final String DISPOSE_METHOD = "dispose";

    private final LongSparseArray<BetterPlayer> videoPlayers = new LongSparseArray<>();
    private FlutterState flutterState;

    /**
     * Register this with the v2 embedding for the plugin to respond to lifecycle callbacks.
     */
    public BetterPlayerPlugin() {
    }

    private BetterPlayerPlugin(Registrar registrar) {
        this.flutterState =
                new FlutterState(
                        registrar.context(),
                        registrar.messenger(),
                        registrar::lookupKeyForAsset,
                        registrar::lookupKeyForAsset,
                        registrar.textures());
        flutterState.startListening(this);
    }

    /**
     * Registers this with the stable v1 embedding. Will not respond to lifecycle events.
     */
    public static void registerWith(Registrar registrar) {
        final BetterPlayerPlugin plugin = new BetterPlayerPlugin(registrar);
        registrar.addViewDestroyListener(
                view -> {
                    plugin.onDestroy();
                    return false; // We are not interested in assuming ownership of the NativeView.
                });
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        this.flutterState =
                new FlutterState(
                        binding.getApplicationContext(),
                        binding.getBinaryMessenger(),
                        FlutterMain::getLookupKeyForAsset,
                        FlutterMain::getLookupKeyForAsset,
                        binding.getFlutterEngine().getRenderer());
        flutterState.startListening(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        if (flutterState == null) {
            Log.wtf(TAG, "Detached from the engine before registering to it.");
        }
        flutterState.stopListening();
        flutterState = null;
    }

    private void disposeAllPlayers() {
        for (int i = 0; i < videoPlayers.size(); i++) {
            videoPlayers.valueAt(i).dispose();
        }
        videoPlayers.clear();
    }

    private void onDestroy() {
        // The whole FlutterView is being destroyed. Here we release resources acquired for all
        // instances
        // of VideoPlayer. Once https://github.com/flutter/flutter/issues/19358 is resolved this may
        // be replaced with just asserting that videoPlayers.isEmpty().
        // https://github.com/flutter/flutter/issues/20989 tracks this.
        disposeAllPlayers();
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
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
            case SET_SPEED_METHOD:
                player.setSpeed((Double) call.argument(SPEED_PARAMETER));
                result.success(null);
                break;
            case SET_TRACK_PARAMETERS_METHOD:
                player.setTrackParameters(
                        (Integer) call.argument(WIDTH_PARAMETER),
                        (Integer) call.argument(HEIGHT_PARAMETER),
                        (Integer) call.argument(BITRATE_PARAMETER));
                result.success(null);
                break;
            case DISPOSE_METHOD:
                player.dispose();
                videoPlayers.remove(textureId);
                result.success(null);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void setDataSource(MethodCall call, Result result, BetterPlayer player) {
        Map<String, Object> dataSource = call.argument(DATA_SOURCE_PARAMETER);

        String key = getParameter(dataSource, KEY_PARAMETER, "");
        Map<String, String> headers = getParameter(dataSource, HEADERS_PARAMETER, new HashMap<>());

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
                    0L);
        } else {
            boolean useCache = getParameter(dataSource, USE_CACHE_PARAMETER, false);
            Number maxCacheSizeNumber = getParameter(dataSource, MAX_CACHE_SIZE_PARAMETER, 0);
            Number maxCacheFileSizeNumber = getParameter(dataSource, MAX_CACHE_FILE_SIZE_PARAMETER, 0);
            long maxCacheSize = maxCacheSizeNumber.longValue();
            long maxCacheFileSize = maxCacheFileSizeNumber.longValue();
            String uri = getParameter(dataSource, URI_PARAMETER, "");
            String formatHint = getParameter(dataSource, FORMAT_HINT_PARAMETER, null);
            player.setDataSource(
                    flutterState.applicationContext,
                    key,
                    uri,
                    formatHint,
                    result,
                    headers,
                    useCache,
                    maxCacheSize,
                    maxCacheFileSize);
        }
    }

    private <T> T getParameter(Map<String, Object> parameters, Object key, T defaultValue) {
        if (parameters.containsKey(key)) {
            Object value = parameters.get(key);
            if (value != null) {
                return (T) value;
            }
        }
        return defaultValue;
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
