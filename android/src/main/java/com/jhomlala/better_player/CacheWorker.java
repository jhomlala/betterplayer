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

import static com.jhomlala.better_player.BetterPlayer.isHTTP;
import static com.jhomlala.better_player.DataSourceUtils.getDataSourceFactory;
import static com.jhomlala.better_player.DataSourceUtils.getUserAgent;

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
        Data data = getInputData();
        String url = data.getString("url");
        long preCacheSize = data.getLong("preCacheSize", 0);
        long maxCacheSize = data.getLong("maxCacheSize", 0);
        long maxCacheFileSize = data.getLong("maxCacheFileSize", 0);
        Map<String, String> headers = new HashMap<>();
        for (String key : data.getKeyValueMap().keySet()) {
            if (key.contains("header_")) {
                String keySplit = key.split("header_")[0];
                headers.put(keySplit, (String) Objects.requireNonNull(data.getKeyValueMap().get(key)));
            }
        }


        Uri uri = Uri.parse(url);

        if (isHTTP(uri)) {

            String userAgent = getUserAgent(headers);
            DataSource.Factory dataSourceFactory = getDataSourceFactory(userAgent, headers);

            DataSpec dataSpec = new DataSpec(uri, 0, preCacheSize);


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


            try {
                mCacheWriter.cache();
            } catch (Exception e) {
                //we have to catch HttpDataSourceException manually to avoid throwing when the video is actually fully loaded
                //see https://github.com/google/ExoPlayer/issues/7326
                if (e instanceof HttpDataSource.HttpDataSourceException) {
                    return Result.success();
                } else {
                    return Result.failure();
                }
            }

        } else {
            //preCache only possible from remote dataSource
            Log.e(TAG, "Preloading only possible for remote data sources");
            return Result.failure();
        }

        return Result.success();
    }

    @Override
    public void onStopped() {
        mCacheWriter.cancel();
        super.onStopped();
    }
}
