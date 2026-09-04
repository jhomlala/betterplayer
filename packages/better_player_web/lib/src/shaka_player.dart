import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

// ─── Shaka namespace ───────────────────────────────────────────────────────

ShakaNamespace get shaka => globalContext['shaka']! as ShakaNamespace;

@JS()
@staticInterop
class ShakaNamespace {}

extension ShakaNamespaceExtension on ShakaNamespace {
  external ShakaPolyfill get polyfill;
  external ShakaUtil get util;
}

@JS()
@staticInterop
class ShakaPolyfill {}

extension ShakaPolyfillExtension on ShakaPolyfill {
  external void installAll();
}

@JS()
@staticInterop
class ShakaUtil {}

// ─── Player ────────────────────────────────────────────────────────────────

@JS('shaka.Player')
@staticInterop
class ShakaPlayer {
  external factory ShakaPlayer(web.HTMLVideoElement element);
}

extension ShakaPlayerExtension on ShakaPlayer {
  external JSPromise<JSAny?> load(JSString url);
  external JSPromise<JSAny?> destroy();
  external void configure(JSObject config);
  external JSBoolean isLive();
  external JSNumber getPlayheadTimeAsDate();
  external JSArray<JSObject> getVariantTracks();
  external JSArray<JSObject> getAudioLanguagesAndRoles();
  external void selectVariantTrack(JSObject track, [JSBoolean clearBuffer]);
  external void selectAudioLanguage(JSString language, [JSString role]);
  external void addEventListener(JSString type, JSFunction listener);
  external void removeEventListener(JSString type, JSFunction listener);
  external JSArray<JSObject> getTextTracks();
  external void selectTextTrack(JSObject track);
  external ShakaNetworkingEngine getNetworkingEngine();
}

// ─── Networking Engine ─────────────────────────────────────────────────────

@JS()
@staticInterop
class ShakaNetworkingEngine {}

extension ShakaNetworkingEngineExtension on ShakaNetworkingEngine {
  external void registerRequestFilter(JSFunction filter);
}
