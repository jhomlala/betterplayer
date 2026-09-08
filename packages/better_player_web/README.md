# better_player_web

The official web implementation of the `better_player` plugin, utilizing Shaka Player for advanced playback, HLS, and DASH support. 

You should not depend on this package directly. Simply depend on `better_player` and the web implementation will be automatically used when compiling for web platforms.

## Setup

To use `better_player` on the web, you must include the Shaka Player library in your `web/index.html` file before the closing `</body>` tag:

```html
<script src="https://cdn.jsdelivr.net/npm/shaka-player@4/dist/shaka-player.compiled.js"></script>
```

Alternatively, you can download the script and host it locally.
