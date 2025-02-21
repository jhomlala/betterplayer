package com.jhomlala.better_player.custom

import android.net.Uri
import com.google.android.exoplayer2.upstream.*
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource.Factory as DefaultFactory

class MyCustomDataSourceFactory(
    private val token: String?,
    private val rewriteMpd: Boolean = false,
    private val otherHeaders: Map<String, String>?,
) : DataSource.Factory {

    override fun createDataSource(): DataSource {
        val baseFactory = DefaultFactory()
            .setUserAgent("BetterPlayerCustom")
            .setConnectTimeoutMs(8000)
            .setReadTimeoutMs(8000)

        val baseDataSource = baseFactory.createDataSource() as DefaultHttpDataSource

        return object : HttpDataSource by baseDataSource {
            override fun open(dataSpec: DataSpec): Long {
                // 1) URIを書き換え
                val newUri = rewriteUriIfNeeded(dataSpec.uri)

                // 2) ヘッダー付与
                baseDataSource.clearAllRequestProperties()

                // Bearer token
                if (!token.isNullOrEmpty()) {
                    baseDataSource.setRequestProperty("Authorization", "Bearer $token")
                }

                otherHeaders?.forEach { (k, v) ->
                    baseDataSource.setRequestProperty(k, v)
                }
                if (newUri.toString().contains(".mpd")) {
                    baseDataSource.setRequestProperty("Accept", "application/dash+xml, application/json, text/json")
                } else {
                    baseDataSource.setRequestProperty("Accept", "video/webm, application/json, text/json")
                }

                val newDataSpec = dataSpec.buildUpon().setUri(newUri).build()
                return baseDataSource.open(newDataSpec)
            }
        }
    }

    private fun rewriteUriIfNeeded(uri: Uri): Uri {
        if (!rewriteMpd) return uri
        var urlStr = uri.toString()
        if (urlStr.contains("mpd")) {
            urlStr = urlStr.replace("mpd", "webm")
        }
        if (urlStr.contains("prepared")) {
            val parts = urlStr.split("/").toMutableList()
            val idx = parts.indexOf("prepared")
            if (idx >= 0) {
                parts.removeAt(idx)
            }
            urlStr = parts.joinToString("/")
        }
        return Uri.parse(urlStr)
    }
}
