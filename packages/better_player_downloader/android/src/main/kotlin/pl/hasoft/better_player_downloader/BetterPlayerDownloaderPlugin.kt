package pl.hasoft.better_player_downloader

import android.content.Context
import android.net.Uri
import android.util.Log
import androidx.annotation.OptIn
import androidx.media3.common.MimeTypes
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.offline.Download
import androidx.media3.exoplayer.offline.DownloadRequest
import androidx.media3.exoplayer.offline.DownloadService as Media3DownloadService
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import kotlin.math.roundToInt

@OptIn(UnstableApi::class)
class BetterPlayerDownloaderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        DownloadService.ensureNotificationChannel(context)
        channel = MethodChannel(binding.binaryMessenger, "better_player_downloader")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val id = call.argument<String>("id")
        when (call.method) {
            "startDownload", "startDownloadNative" -> startDownload(id, call.argument<String>("url"), result)
            "downloadProgress" -> result.success(progressOf(id))
            "deleteDownload" -> deleteDownload(id, result)
            else -> result.notImplemented()
        }
    }

    private fun startDownload(id: String?, url: String?, result: MethodChannel.Result) {
        if (id.isNullOrEmpty() || url.isNullOrEmpty()) {
            result.error("invalid_request", "id and url are required", null)
            return
        }
        val mimeType = mimeTypeOf(url)
        Log.d(LOG_TAG, "startDownload id=$id mime=$mimeType url=$url")
        val request = DownloadRequest.Builder(id, Uri.parse(url))
            .setMimeType(mimeType)
            .build()
        try {
            Media3DownloadService.sendAddDownload(
                context, DownloadService::class.java, request, true)
            DownloadService.manager(context).resumeDownloads()
            Log.d(LOG_TAG, "startDownload queued id=$id")
            result.success(true)
        } catch (error: RuntimeException) {
            Log.e(LOG_TAG, "startDownload failed id=$id", error)
            result.error(
                "download_failed", error.message ?: error.javaClass.simpleName, null)
        }
    }

    private fun deleteDownload(id: String?, result: MethodChannel.Result) {
        if (id.isNullOrEmpty()) {
            result.error("invalid_request", "id is required", null)
            return
        }
        DownloadService.manager(context).removeDownload(id)
        Log.d(LOG_TAG, "deleteDownload id=$id")
        result.success(true)
    }

    private fun progressOf(id: String?): Map<String, Any>? {
        if (id.isNullOrEmpty()) return null
        val download = try {
            DownloadService.manager(context).downloadIndex.getDownload(id)
        } catch (error: IOException) {
            Log.e(LOG_TAG, "progressOf failed id=$id", error)
            null
        } catch (error: RuntimeException) {
            Log.e(LOG_TAG, "progressOf failed id=$id", error)
            null
        }
        Log.d(
            LOG_TAG,
            "progress id=$id found=${download != null} state=${download?.state} " +
                "bytes=${download?.bytesDownloaded}",
        )
        return download?.let {
            mapOf(
                "state" to stateNameOf(it.state),
                "percent" to it.percentDownloaded.roundToInt(),
                "bytesDownloaded" to it.bytesDownloaded,
                "totalBytes" to it.contentLength,
            )
        }
    }

    private fun mimeTypeOf(url: String): String = when {
        url.lowercase().contains(".mpd") -> MimeTypes.APPLICATION_MPD
        url.lowercase().contains(".m3u8") -> MimeTypes.APPLICATION_M3U8
        else -> MimeTypes.VIDEO_MP4
    }

    private fun stateNameOf(state: Int): String = when (state) {
        Download.STATE_COMPLETED -> "completed"
        Download.STATE_DOWNLOADING -> "inProgress"
        Download.STATE_FAILED -> "failed"
        Download.STATE_QUEUED -> "notStarted"
        else -> "notStarted"
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private companion object {
        const val LOG_TAG = "BPD"
    }
}
