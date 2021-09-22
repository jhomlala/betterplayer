package com.jhomlala.better_player;

import android.content.Context;
import android.util.Log;

import com.google.android.exoplayer2.database.ExoDatabaseProvider;
import com.google.android.exoplayer2.upstream.cache.LeastRecentlyUsedCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.SimpleCache;

import java.io.File;

public class BetterPlayerCache {
    private static volatile SimpleCache instance;

    public static SimpleCache createCache(Context context, long cacheFileSize) {
        if (instance == null) {
            synchronized (BetterPlayerCache.class) {
                if (instance == null) {
                    instance = new SimpleCache(
                            new File(context.getCacheDir(), "betterPlayerCache"),
                            new LeastRecentlyUsedCacheEvictor(cacheFileSize),
                            new ExoDatabaseProvider(context));
                }
            }
        }
        return instance;
    }

    public static void releaseCache() {
        try {
            if (instance != null) {
                instance.release();
                instance = null;
            }
        } catch (Exception exception) {
            Log.e("BetterPlayerCache", exception.toString());
        }
    }
}
