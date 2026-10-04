package pl.hasoft.better_player_surfaceview

import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Registers the platform view factory. Playback itself stays in
 * better_player_android; this module only decides where its pixels go.
 */
class BetterPlayerSurfaceViewPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry.registerViewFactory(
            BetterPlayerSurfaceViewFactory.VIEW_TYPE,
            BetterPlayerSurfaceViewFactory(),
        )
    }

    // Views are disposed by Flutter and release their own references; the
    // factory holds no state.
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
