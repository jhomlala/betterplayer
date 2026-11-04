package pl.hasoft.better_player.download

import android.content.Context
import android.net.Uri
import androidx.media3.common.util.UnstableApi
import androidx.media3.datasource.DataSource
import androidx.media3.datasource.DefaultDataSource
import androidx.media3.datasource.ResolvingDataSource

/**
 * Request headers of the active download, grouped by host.
 *
 * The download manager fetches the segments after the request is built, so the
 * headers cannot travel inside the request. It reads them from this registry
 * for each request, matched by host.
 */
@UnstableApi
object PlayerDownloadHeaders {
  private val headersByHost = HashMap<String, Map<String, String>>()

  /**
   * Stores [headers] for the host of [url].
   *
   * Does nothing when [headers] is empty.
   */
  fun register(url: String, headers: Map<String, String>) {
    if (headers.isEmpty()) {
      return
    }
    val host = Uri.parse(url).host ?: return
    synchronized(headersByHost) {
      headersByHost[host] = headers
    }
  }

  /** Removes the headers stored for the host of [url]. */
  fun unregister(url: String) {
    val host = Uri.parse(url).host ?: return
    synchronized(headersByHost) {
      headersByHost.remove(host)
    }
  }

  /**
   * Returns a data source factory that adds the stored headers to each
   * request, matched by host.
   */
  fun factory(context: Context): DataSource.Factory {
    val upstream = DefaultDataSource.Factory(context.applicationContext)
    val resolver = ResolvingDataSource.Resolver { spec ->
      val host = spec.uri.host
      val headers = host?.let {
        synchronized(headersByHost) { headersByHost[it] }
      }
      if (headers.isNullOrEmpty()) {
        spec
      } else {
        spec.buildUpon().setHttpRequestHeaders(headers).build()
      }
    }
    return ResolvingDataSource.Factory(upstream, resolver)
  }

  /** Removes every stored header. */
  fun clear() {
    synchronized(headersByHost) {
      headersByHost.clear()
    }
  }
}
