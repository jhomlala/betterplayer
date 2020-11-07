package com.jhomlala.better_player;

import android.content.Context;

import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;
import com.google.android.exoplayer2.upstream.FileDataSource;
import com.google.android.exoplayer2.upstream.cache.CacheDataSink;
import com.google.android.exoplayer2.upstream.cache.CacheDataSource;
import com.google.android.exoplayer2.upstream.cache.LeastRecentlyUsedCacheEvictor;
import com.google.android.exoplayer2.upstream.cache.SimpleCache;

import java.io.File;

class CacheDataSourceFactory implements DataSource.Factory {
    private final Context context;
    private final DefaultDataSourceFactory defaultDatasourceFactory;
    private final long maxFileSize, maxCacheSize;
    private static SimpleCache downloadCache;

    CacheDataSourceFactory(
            Context context,
            long maxCacheSize,
            long maxFileSize,
            DataSource.Factory upstreamDataSource) {
        super();
        this.context = context;
        this.maxCacheSize = maxCacheSize;
        this.maxFileSize = maxFileSize;
        DefaultBandwidthMeter bandwidthMeter = new DefaultBandwidthMeter();
        defaultDatasourceFactory =
                new DefaultDataSourceFactory(this.context, bandwidthMeter, upstreamDataSource);
    }

    @Override
    public DataSource createDataSource() {
        LeastRecentlyUsedCacheEvictor evictor = new LeastRecentlyUsedCacheEvictor(maxCacheSize);

        if (downloadCache == null) {
            downloadCache = new SimpleCache(new File(context.getCacheDir(), "video"), evictor);
        }

        return new CacheDataSource(
                downloadCache,
                defaultDatasourceFactory.createDataSource(),
                new FileDataSource(),
                new CacheDataSink(downloadCache, maxFileSize),
                CacheDataSource.FLAG_BLOCK_ON_CACHE | CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR,
                null);
    }
}