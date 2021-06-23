package com.jhomlala.better_player;

import android.content.Context;
import android.net.Uri;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Data;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DataSpec;
import com.google.android.exoplayer2.upstream.HttpDataSource;
import com.google.android.exoplayer2.upstream.cache.CacheWriter;

import java.util.HashMap;
import java.util.Map;
import java.util.Objects;


/**
 * Cache worker which download part of video and save in cache for future usage. The cache job
 * will be executed in work manager.
 */
public class CacheWorker extends Worker {
    private static final String TAG = "CacheWorker";
    private Context mContext;
    private CacheWriter mCacheWriter;
    private int mLastCacheReportIndex = 0;

    public CacheWorker(
            @NonNull Context context,
            @NonNull WorkerParameters params) {
        super(context, params);
        this.mContext = context;
    }

    @NonNull
    @Override
    public Result doWork() {
        try {
            Data data = getInputData();
            String url = data.getString(BetterPlayerPlugin.URL_PARAMETER);
            String cacheKey = data.getString(BetterPlayerPlugin.CACHE_KEY_PARAMETER);
            long preCacheSize = data.getLong(BetterPlayerPlugin.PRE_CACHE_SIZE_PARAMETER, 0);
            long maxCacheSize = data.getLong(BetterPlayerPlugin.MAX_CACHE_SIZE_PARAMETER, 0);
            long maxCacheFileSize = data.getLong(BetterPlayerPlugin.MAX_CACHE_FILE_SIZE_PARAMETER, 0);
            Map<String, String> headers = new HashMap<>();
            for (String key : data.getKeyValueMap().keySet()) {
                if (key.contains(BetterPlayerPlugin.HEADER_PARAMETER)) {
                    String keySplit = key.split(BetterPlayerPlugin.HEADER_PARAMETER)[0];
                    headers.put(keySplit, (String) Objects.requireNonNull(data.getKeyValueMap().get(key)));
                }
            }

            Uri uri = Uri.parse(url);
            if (DataSourceUtils.isHTTP(uri)) {
                String userAgent = DataSourceUtils.getUserAgent(headers);
                DataSource.Factory dataSourceFactory = DataSourceUtils.getDataSourceFactory(userAgent, headers);

                DataSpec dataSpec = new DataSpec(uri, 0, preCacheSize);
                if (cacheKey != null && cacheKey.length() > 0) {
                    dataSpec = dataSpec.buildUpon().setKey(cacheKey).build();
                }

                CacheDataSourceFactory cacheDataSourceFactory =
                        new CacheDataSourceFactory(mContext, maxCacheSize, maxCacheFileSize, dataSourceFactory);

                mCacheWriter = new CacheWriter(
                        cacheDataSourceFactory.createDataSource(),
                        dataSpec,
                        true,
                        null,
                        (long requestLength, long bytesCached, long newBytesCached) -> {
                            double completedData = ((bytesCached * 100f) / preCacheSize);
                            if (completedData >= mLastCacheReportIndex * 10) {
                                mLastCacheReportIndex += 1;
                                Log.d(TAG, "Completed pre cache of " + url + ": " + (int) completedData + "%");
                            }
                        });

                mCacheWriter.cache();
            } else {
                Log.e(TAG, "Preloading only possible for remote data sources");
                return Result.failure();
            }
        } catch (Exception exception) {
            Log.e(TAG, exception.toString());
            if (exception instanceof HttpDataSource.HttpDataSourceException) {
                return Result.success();
            } else {
                return Result.failure();
            }
        }
        return Result.success();
    }

    @Override
    public void onStopped() {
        try {
            mCacheWriter.cancel();
            super.onStopped();
        } catch (Exception exception) {
            Log.e(TAG, exception.toString());
        }
    }
}
