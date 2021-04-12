package com.jhomlala.better_player;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Data;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import java.io.FileOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class ImageWorker extends Worker {
    private static final String TAG = "ImageWorker";
    private static final String IMAGE_EXTENSION = ".png";
    private static final int DEFAULT_NOTIFICATION_IMAGE_SIZE_PX = 256;

    public ImageWorker(
            @NonNull Context context,
            @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        try {
            String imageUrl = getInputData().getString(BetterPlayerPlugin.URL_PARAMETER);
            if (imageUrl == null) {
                return Result.failure();
            }
            Bitmap bitmap = null;
            if (DataSourceUtils.isHTTP(Uri.parse(imageUrl))) {
                bitmap = getBitmapFromExternalURL(imageUrl);
            } else {
                bitmap = getBitmapFromInternalURL(imageUrl);
            }
            String fileName = imageUrl.hashCode() + IMAGE_EXTENSION;
            String filePath = getApplicationContext().getCacheDir().getAbsolutePath() + fileName;

            if (bitmap == null) {
                return Result.failure();
            }
            FileOutputStream out = new FileOutputStream(filePath);
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, out);
            Data data = new Data.Builder().putString(BetterPlayerPlugin.FILE_PATH_PARAMETER, filePath).build();
            return Result.success(data);
        } catch (Exception e) {
            e.printStackTrace();
            return Result.failure();
        }
    }


    private Bitmap getBitmapFromExternalURL(String src) {
        InputStream inputStream = null;
        try {
            URL url = new URL(src);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            inputStream = connection.getInputStream();

            final BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeStream(inputStream, null, options);
            inputStream.close();
            connection = (HttpURLConnection) url.openConnection();
            inputStream = connection.getInputStream();
            options.inSampleSize = calculateBitmapInSampleSize(
                    options);
            options.inJustDecodeBounds = false;
            return BitmapFactory.decodeStream(inputStream, null, options);

        } catch (Exception exception) {
            Log.e(TAG, "Failed to get bitmap from external url: " + src);
            return null;
        } finally {
            try {
                if (inputStream != null) {
                    inputStream.close();
                }
            } catch (Exception exception) {
                Log.e(TAG, "Failed to close bitmap input stream/");
            }
        }
    }

    private int calculateBitmapInSampleSize(
            BitmapFactory.Options options) {
        final int height = options.outHeight;
        final int width = options.outWidth;
        int inSampleSize = 1;

        if (height > ImageWorker.DEFAULT_NOTIFICATION_IMAGE_SIZE_PX
                || width > ImageWorker.DEFAULT_NOTIFICATION_IMAGE_SIZE_PX) {
            final int halfHeight = height / 2;
            final int halfWidth = width / 2;
            while ((halfHeight / inSampleSize) >= ImageWorker.DEFAULT_NOTIFICATION_IMAGE_SIZE_PX
                    && (halfWidth / inSampleSize) >= ImageWorker.DEFAULT_NOTIFICATION_IMAGE_SIZE_PX) {
                inSampleSize *= 2;
            }
        }
        return inSampleSize;
    }

    private Bitmap getBitmapFromInternalURL(String src) {
        try {
            final BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            options.inSampleSize = calculateBitmapInSampleSize(options
            );
            options.inJustDecodeBounds = false;
            return BitmapFactory.decodeFile(src);
        } catch (Exception exception) {
            Log.e(TAG, "Failed to get bitmap from internal url: " + src);
            return null;
        }
    }

}
