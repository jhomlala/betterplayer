package com.jhomlala.better_player;

import android.net.Uri;

import androidx.annotation.Nullable;

import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;
import com.google.android.exoplayer2.util.Util;

import java.util.Map;

class DataSourceUtils {
    private static final String USER_AGENT = "User-Agent";
    private static final String USER_AGENT_PROPERTY = "http.agent";

    private static final String FORMAT_SS = "ss";
    private static final String FORMAT_DASH = "dash";
    private static final String FORMAT_HLS = "hls";
    private static final String FORMAT_OTHER = "other";

    static String getUserAgent(Map<String, String> headers) {
        String userAgent = System.getProperty(USER_AGENT_PROPERTY);
        if (headers != null && headers.containsKey(USER_AGENT)) {
            String userAgentHeader = headers.get(USER_AGENT);
            if (userAgentHeader != null) {
                userAgent = userAgentHeader;
            }
        }
        return userAgent;
    }

    static DataSource.Factory getDataSourceFactory(String userAgent, Map<String, String> headers) {
        DefaultHttpDataSource.Factory dataSourceFactory = new DefaultHttpDataSource.Factory()
                .setUserAgent(userAgent)
                .setAllowCrossProtocolRedirects(true)
                .setConnectTimeoutMs(DefaultHttpDataSource.DEFAULT_CONNECT_TIMEOUT_MILLIS)
                .setReadTimeoutMs(DefaultHttpDataSource.DEFAULT_READ_TIMEOUT_MILLIS);

        if (headers != null) {
            dataSourceFactory.setDefaultRequestProperties(headers);
        }
        return dataSourceFactory;
    }

    static boolean isHTTP(Uri uri) {
        if (uri == null || uri.getScheme() == null) {
            return false;
        }
        String scheme = uri.getScheme();
        return scheme.equals("http") || scheme.equals("https");
    }

    static public int getContentType(Uri uri, @Nullable String formatHint) {
        if (formatHint == null) {
            String lastPathSegment = uri.getLastPathSegment();
            if (lastPathSegment == null) {
                lastPathSegment = "";
            }
            return Util.inferContentType(lastPathSegment);
        }

        switch (formatHint) {
            case FORMAT_SS:
                return C.TYPE_SS;
            case FORMAT_DASH:
                return C.TYPE_DASH;
            case FORMAT_HLS:
                return C.TYPE_HLS;
            case FORMAT_OTHER:
                return C.TYPE_OTHER;
            default:
                return -1;
        }
    }

    static public int getContentType(String url, @Nullable String formatHint) {
        return getContentType(Uri.parse(url), formatHint);
    }
}
