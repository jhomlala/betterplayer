package pl.hasoft.better_player

import android.app.Activity
import android.os.Handler
import android.util.Log
import android.util.LongSparseArray
import pl.hasoft.better_player.BetterPlayerCache.releaseCache
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import java.lang.Exception
import java.util.HashMap

class BetterPlayerPlugin : FlutterPlugin, ActivityAware {
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPluginBinding) {
        BetterPlayerApi.textureRegistry = binding.textureRegistry
    }

    override fun onDetachedFromEngine(binding: FlutterPluginBinding) {
        BetterPlayerApi.textureRegistry = null
        releaseCache()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {
        activity = null
    }

    companion object {
        private const val TAG = "BetterPlayerPlugin"
    }
}