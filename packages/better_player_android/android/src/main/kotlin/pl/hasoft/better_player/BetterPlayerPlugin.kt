package pl.hasoft.better_player

import android.app.Activity
import android.content.Context
import android.net.Uri
import android.util.Log
import android.view.WindowManager
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.offline.Download
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import pl.hasoft.better_player.BetterPlayerCache.releaseCache
import pl.hasoft.better_player.download.PlayerDownloadCache
import pl.hasoft.better_player.download.PlayerDownloadChannel
import pl.hasoft.better_player.download.PlayerDownloadManager
import pl.hasoft.better_player.download.PlayerDownloadRequestFactory

@UnstableApi
class BetterPlayerPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private var activity: Activity? = null
    private var context: Context? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        BetterPlayerApi.textureRegistry = binding.textureRegistry
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "better_player_android")
        channel?.setMethodCallHandler(this)
        PlayerDownloadChannel.attach(channel)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        BetterPlayerApi.textureRegistry = null
        PlayerDownloadChannel.attach(null)
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
        releaseCache()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        BetterPlayerApi.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        BetterPlayerApi.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        BetterPlayerApi.activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        BetterPlayerApi.activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startDownload" -> startDownload(call, result)
            "stopDownload" -> stopDownload(call, result)
            "deleteDownload" -> deleteDownload(call, result)
            "setScreenCaptureProtection" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                BetterPlayerApi.setScreenCaptureProtection(enabled)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startDownload(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        val appContext = context
        if (url.isNullOrEmpty() || appContext == null) {
            result.error("invalid_request", "url is required", null)
            return
        }
        val existing = PlayerDownloadManager.find(appContext, url)
        Log.d(TAG, "startDownload url=$url existing=${existing?.state}")
        if (existing?.state == Download.STATE_COMPLETED) {
            result.success(true)
            return
        }
        if (existing != null) {
            if (!hasDownloadSpace(appContext, result)) {
                return
            }
            PlayerDownloadManager.resume(appContext, url)
            result.success(true)
            return
        }
        if (!hasDownloadSpace(appContext, result)) {
            return
        }
        val maxVideoHeight = call.argument<Int>("maxVideoHeight")
            ?: PlayerDownloadRequestFactory.DEFAULT_MAX_VIDEO_HEIGHT
        val headers = call.argument<Map<String, String>>("headers") ?: emptyMap()
        PlayerDownloadRequestFactory(appContext).create(
            id = url,
            uri = Uri.parse(url),
            mimeType = mimeTypeOf(url),
            headers = headers,
            maxVideoHeight = maxVideoHeight,
        ) { request, error ->
            if (request == null) {
                result.error("download_failed", error ?: "Unknown error", null)
                return@create
            }
            Log.d(TAG, "startDownload request ready id=${request.id}")
            PlayerDownloadManager.add(appContext, request)
            result.success(true)
        }
    }

    private fun stopDownload(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        val appContext = context
        if (url.isNullOrEmpty() || appContext == null) {
            result.error("invalid_request", "url is required", null)
            return
        }
        PlayerDownloadManager.stop(appContext, url)
        result.success(true)
    }

    private fun deleteDownload(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")
        val appContext = context
        if (url.isNullOrEmpty() || appContext == null) {
            result.error("invalid_request", "url is required", null)
            return
        }
        PlayerDownloadManager.remove(appContext, url)
        result.success(true)
    }

    private fun hasDownloadSpace(appContext: Context, result: Result): Boolean {
        if (PlayerDownloadCache.hasSpaceForDownload(appContext)) {
            return true
        }
        result.error(
            "download_no_space",
            appContext.getString(R.string.better_player_download_no_space),
            null,
        )
        return false
    }

    private fun mimeTypeOf(url: String): String? = when {
        url.contains(".mpd") -> MimeTypes.APPLICATION_MPD
        url.contains(".m3u8") -> MimeTypes.APPLICATION_M3U8
        else -> null
    }

    companion object {
        private const val TAG = "BetterPlayerPlugin"
        const val URL_PARAMETER = "url"
        const val FILE_PATH_PARAMETER = "filePath"
        const val PRE_CACHE_SIZE_PARAMETER = "preCacheSize"
        const val MAX_CACHE_SIZE_PARAMETER = "maxCacheSize"
        const val MAX_CACHE_FILE_SIZE_PARAMETER = "maxCacheFileSize"
        const val CACHE_KEY_PARAMETER = "cacheKey"
        const val HEADER_PARAMETER = "header_"
    }
}
