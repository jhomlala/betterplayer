package com.jhomlala.better_player;

import android.content.Context;

import com.google.android.exoplayer2.database.ExoDatabaseProvider;
import com.google.android.exoplayer2.upstream.cache.LeastRecentlyUsedCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.NoOpCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.SimpleCache;

import java.io.File;

public class BetterPlayerCache {
    private static SimpleCache sDownloadCache;

    public static void createCache(Context context) {
        if (sDownloadCache == null) {
            sDownloadCache = new SimpleCache(
                    new File(context.getCacheDir(), "betterPlayerCache"),
                    new LeastRecentlyUsedCacheEvictor(100 * 1024 * 1024),
                    new ExoDatabaseProvider(context));
        }
    }

    public static SimpleCache getInstance() {
        return sDownloadCache;
    }

    public static void releaseCache() {
        sDownloadCache.release();
        sDownloadCache = null;
    }
}
