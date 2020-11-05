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
            case "init":
                disposeAllPlayers();
                break;
            case "create": {
                TextureRegistry.SurfaceTextureEntry handle =
                        flutterState.textureRegistry.createSurfaceTexture();
                EventChannel eventChannel =
                        new EventChannel(
                                flutterState.binaryMessenger, "better_player_channel/videoEvents" + handle.id());

                BetterPlayer player =
                        new BetterPlayer(flutterState.applicationContext, eventChannel, handle, result);

                videoPlayers.put(handle.id(), player);
                break;
            }
            default: {
                long textureId = ((Number) call.argument("textureId")).longValue();
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
            case "setDataSource": {
                setDataSource(call,result,player);
                break;
            }
            case "setLooping":
                player.setLooping(call.argument("looping"));
                result.success(null);
                break;
            case "setVolume":
                player.setVolume(call.argument("volume"));
                result.success(null);
                break;
            case "play":
                player.play();
                result.success(null);
                break;
            case "pause":
                player.pause();
                result.success(null);
                break;
            case "seekTo":
                int location = ((Number) call.argument("location")).intValue();
                player.seekTo(location);
                result.success(null);
                break;
            case "position":
                result.success(player.getPosition());
                player.sendBufferingUpdate();
                break;
            case "setSpeed":
                player.setSpeed((Double) call.argument("speed"));
                result.success(null);
                break;
            case "setTrackParameters":
                player.setTrackParameters(
                        (Integer) call.argument("width"),
                        (Integer) call.argument("height"),
                        (Integer) call.argument("bitrate"));
                result.success(null);
                break;
            case "dispose":
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
        Map<String, Object> dataSource = call.argument("dataSource");


        String key = "";
        if (dataSource.containsKey("key")) {
            Object keyObject = dataSource.get("key");
            if (keyObject != null) {
                key = (String) keyObject;
            }
        }

        Map<String, String> headers = new HashMap();
        if (dataSource.containsKey("headers")) {
            Object headersObject = dataSource.get("headers");
            if (headersObject != null) {
                headers = (Map<String, String>) headersObject;
            }
        }

        Boolean useCache = false;
        if (dataSource.containsKey("useCache")) {
            Object useCacheObject = dataSource.get("useCache");
            if (useCacheObject != null) {
                useCache = (boolean) useCacheObject;
            }
        }
        Long maxCacheSize = 0L;
        if (dataSource.containsKey("maxCacheSize")) {
            Object maxCacheSizeObject = dataSource.get("maxCacheSize");
            if (maxCacheSizeObject != null) {
                maxCacheSize = ((Number) maxCacheSizeObject).longValue();
            }

        }
        Long maxCacheFileSize = 0L;
        if (dataSource.containsKey("maxCacheFileSize")) {
            Object maxCacheFileSizeObject = dataSource.get("maxCacheFileSize");
            if (maxCacheFileSizeObject != null) {
                maxCacheFileSize = ((Number) maxCacheFileSizeObject).longValue();
            }
        }

        Log.d("VIDEO_PLAYER_ANDROID", "CACHE CONFIGURATION:");
        Log.d("VIDEO_PLAYER_ANDROID", "useCache: " + useCache);
        Log.d("VIDEO_PLAYER_ANDROID", "maxCacheSize: " + maxCacheSize);
        Log.d("VIDEO_PLAYER_ANDROID", "maxCacheFileSize: " + maxCacheFileSize);


        if (dataSource.get("asset") != null) {
            String assetLookupKey;
            if (dataSource.get("package") != null) {
                assetLookupKey =
                        flutterState.keyForAssetAndPackageName.get(
                                (String) dataSource.get("asset"), (String) dataSource.get("package"));
            } else {
                assetLookupKey = flutterState.keyForAsset.get((String) dataSource.get("asset"));
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
            Log.d("VIDEO_PLAYER_ANDROID", "USE DATASOURCE WITH CACHE");
            player.setDataSource(
                    flutterState.applicationContext,
                    key,
                    (String) dataSource.get("uri"),
                    (String) dataSource.get("formatHint"),
                    result,
                    headers,
                    useCache,
                    maxCacheSize,
                    maxCacheFileSize);
        }
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
            methodChannel = new MethodChannel(messenger, "better_player_channel");
        }

        void startListening(BetterPlayerPlugin methodCallHandler) {
            methodChannel.setMethodCallHandler(methodCallHandler);
        }

        void stopListening() {
            methodChannel.setMethodCallHandler(null);
        }
    }
}
