package pl.hasoft.better_player

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import pl.hasoft.better_player.BetterPlayerCache.releaseCache

class BetterPlayerPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {
    private var activity: Activity? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        BetterPlayerApi.textureRegistry = binding.textureRegistry
        channel = MethodChannel(binding.binaryMessenger, "better_player_android")
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        BetterPlayerApi.textureRegistry = null
        channel?.setMethodCallHandler(null)
        channel = null
        releaseCache()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        BetterPlayerApi.activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {
        activity = null
        BetterPlayerApi.activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "setScreenCaptureProtection" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val currentActivity = activity
                if (currentActivity != null) {
                    currentActivity.runOnUiThread {
                        if (enabled) {
                            currentActivity.window?.setFlags(
                                WindowManager.LayoutParams.FLAG_SECURE,
                                WindowManager.LayoutParams.FLAG_SECURE
                            )
                        } else {
                            currentActivity.window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                } else {
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
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
