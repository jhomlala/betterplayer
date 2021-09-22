package com.jhomlala.better_player;

import android.net.Uri;

import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource;

import java.util.Map;

class DataSourceUtils {

    private static final String USER_AGENT = "User-Agent";
    private static final String USER_AGENT_PROPERTY = "http.agent";

    static String getUserAgent(Map<String, String> headers){
        String userAgent = System.getProperty(USER_AGENT_PROPERTY);
        if (headers != null && headers.containsKey(USER_AGENT)) {
            String userAgentHeader = headers.get(USER_AGENT);
            if (userAgentHeader != null) {
                userAgent = userAgentHeader;
            }
        }
        return userAgent;
    }

    static DataSource.Factory getDataSourceFactory(String userAgent, Map<String, String> headers){
        DataSource.Factory dataSourceFactory = new DefaultHttpDataSource.Factory()
                .setUserAgent(userAgent)
                .setAllowCrossProtocolRedirects(true)
                .setConnectTimeoutMs(DefaultHttpDataSource.DEFAULT_CONNECT_TIMEOUT_MILLIS)
                .setReadTimeoutMs(DefaultHttpDataSource.DEFAULT_READ_TIMEOUT_MILLIS);

        if (headers != null) {
            ((DefaultHttpDataSource.Factory) dataSourceFactory).setDefaultRequestProperties(headers);
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
}
