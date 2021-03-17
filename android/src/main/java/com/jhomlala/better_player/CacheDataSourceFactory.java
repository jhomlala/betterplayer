package com.jhomlala.better_player;

import android.content.Context;
import android.util.Log;

import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;
import com.google.android.exoplayer2.upstream.FileDataSource;
import com.google.android.exoplayer2.upstream.cache.CacheDataSink;
import com.google.android.exoplayer2.upstream.cache.CacheDataSource;
import com.google.android.exoplayer2.upstream.cache.SimpleCache;

import java.io.File;

class CacheDataSourceFactory implements DataSource.Factory {
    private final Context context;
    private final DefaultDataSourceFactory defaultDatasourceFactory;
    private final long maxFileSize, maxCacheSize;


    CacheDataSourceFactory(
            Context context,
            long maxCacheSize,
            long maxFileSize,
            DataSource.Factory upstreamDataSource) {
        super();
        this.context = context;
        this.maxCacheSize = maxCacheSize;
        this.maxFileSize = maxFileSize;
        DefaultBandwidthMeter bandwidthMeter = new DefaultBandwidthMeter.Builder(context).build();
        defaultDatasourceFactory =
                new DefaultDataSourceFactory(this.context, bandwidthMeter, upstreamDataSource);
    }

    @SuppressWarnings("NullableProblems")
    @Override
    public DataSource createDataSource() {
        SimpleCache betterPlayerCache = BetterPlayerCache.createCache(context, maxCacheSize);
        return new CacheDataSource(
                betterPlayerCache,
                defaultDatasourceFactory.createDataSource(),
                new FileDataSource(),
                new CacheDataSink(betterPlayerCache, maxFileSize),
                CacheDataSource.FLAG_BLOCK_ON_CACHE | CacheDataSource.FLAG_IGNORE_CACHE_ON_ERROR,
                null);
    }
}