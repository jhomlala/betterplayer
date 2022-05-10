package com.jhomlala.better_player

import android.widget.TextView
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.ui.TrackNameProvider
import android.content.Context
import com.google.android.exoplayer2.util.DebugTextViewHelper
import com.google.android.exoplayer2.analytics.AnalyticsListener
import java.lang.Runnable
import com.google.android.exoplayer2.analytics.AnalyticsListener.EventTime
import com.google.android.exoplayer2.source.LoadEventInfo
import com.google.android.exoplayer2.source.MediaLoadData
import java.io.IOException
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.Player
import com.google.android.exoplayer2.C
import android.media.AudioManager
import android.os.Handler
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.decoder.DecoderCounters
import java.util.HashMap

class NerdStatHelper(
    private val exoPlayer: ExoPlayer,
    textView: TextView?,
    private val eventSink: QueuingEventSink,
    private var trackSelections: TrackSelectionArray,
    private val trackNameProvider: TrackNameProvider,
    private val context: Context
) : DebugTextViewHelper(exoPlayer, textView!!), AnalyticsListener {
    /// nerd stats variables
    private var totalBufferedDs = 0.0
    private var bitrateEstimateValue: Long = 0
    private var bytesDownloaded = 0.0
    private var currentBytesDownloaded = 0.0
    private var audioTrackName = ""
    private var videoTrackName = ""
    private val statsHandler = Handler()
    private val statsRunnable: Runnable = object : Runnable {
        override fun run() {
            videoString
            statsHandler.removeCallbacks(this)
            statsHandler.postDelayed(this, 1000)
        }
    }

    fun init() {
        exoPlayer.addAnalyticsListener(this)
        start()
        statsHandler.postDelayed(statsRunnable, 1000)
    }

    fun onStop() {
        stop()
        exoPlayer.removeAnalyticsListener(this)
        statsHandler.removeCallbacks(statsRunnable)
    }

    override fun onBandwidthEstimate(
        eventTime: EventTime,
        totalLoadTimeMs: Int,
        totalBytesLoaded: Long,
        bitrateEstimate: Long
    ) {
        totalBufferedDs = eventTime.totalBufferedDurationMs.toDouble()
        bitrateEstimateValue = bitrateEstimate
        currentBytesDownloaded = totalBytesLoaded.toDouble()
        bytesDownloaded = totalBytesLoaded.toDouble()
    }

    override fun onLoadCompleted(
        eventTime: EventTime,
        loadEventInfo: LoadEventInfo,
        mediaLoadData: MediaLoadData
    ) {
        bytesDownloaded = 0.0
    }

    override fun onLoadStarted(
        eventTime: EventTime,
        loadEventInfo: LoadEventInfo,
        mediaLoadData: MediaLoadData
    ) {
        bytesDownloaded = currentBytesDownloaded
    }

    override fun onLoadError(
        eventTime: EventTime,
        loadEventInfo: LoadEventInfo,
        mediaLoadData: MediaLoadData,
        error: IOException,
        wasCanceled: Boolean
    ) {
        bytesDownloaded = 0.0
        bitrateEstimateValue = 0
    }

    override fun onTracksChanged(
        trackGroups: TrackGroupArray,
        trackSelections: TrackSelectionArray
    ) {
        this.trackSelections = trackSelections
    }

    override fun onPlaybackStateChanged(eventTime: EventTime, state: Int) {
        if (Player.STATE_READY == state) {
//            statsHandler.postDelayed(statsRunnable, 1000)
        }
    }

    override fun getDebugString(): String {
        return super.getDebugString()
    }

    override fun getVideoString(): String {
        if (trackSelections[C.TRACK_TYPE_AUDIO] != null) {
            audioTrackName = trackNameProvider.getTrackName(
                trackSelections[C.TRACK_TYPE_AUDIO]!!.getFormat(0)
            )
        }
        if (trackSelections[C.TRACK_TYPE_DEFAULT] != null) {
            videoTrackName = trackNameProvider.getTrackName(
                trackSelections[C.TRACK_TYPE_DEFAULT]!!.getFormat(0)
            )
        }
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
        val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        var currentVolumePercentage = 0
        if (maxVolume != 0) currentVolumePercentage = 100 * currentVolume / maxVolume
        val format = exoPlayer.videoFormat
        val decoderCounters = exoPlayer.videoDecoderCounters
        val buffer =
            DemoUtil.getFormattedDouble(exoPlayer.totalBufferedDuration / Math.pow(10.0, 3.0), 1)
        val brEstimateFloat =
            DemoUtil.getFormattedDouble(bitrateEstimateValue / Math.pow(10.0, 3.0), 1)
        if (format == null) return ""
        if (exoPlayer.audioFormat == null) return ""
        if (format != null || decoderCounters != null) {
            val data = """Buffer Health: $buffer s
Conn Speed: """ + DemoUtil.humanReadableByteCount(
                bitrateEstimateValue, true, true
            ) + "ps" + "\n" +
                    "Video: " + format.width + "x" + format.height + " / " + format.sampleMimeType!!.replace(
                "video/",
                ""
            ) + "\n" +
                    "Audio: " + currentVolumePercentage + "% / " + exoPlayer.audioFormat!!.sampleMimeType!!.replace(
                "audio/",
                ""
            ) + "\n" +
                    "Current: " + videoTrackName + " / " + audioTrackName + "\n" +
                    "Frames: " + getDecoderCountersBufferCountString(decoderCounters)
            val event: MutableMap<String, Any> = HashMap()
            event["event"] = "nerdStat"
            event["values"] = data
            eventSink.success(event)
        } else if (format == null || decoderCounters == null) {
            val event: MutableMap<String, Any> = HashMap()
            event["event"] = "nerdStat"
            event["values"] = ""
            eventSink.success(event)
            return ""
        } else {
            val data = """Buffer Health: $buffer s
Conn Speed: """ + DemoUtil.humanReadableByteCount(
                bitrateEstimateValue, true, true
            ) + "ps" + "\n" +
                    "Video: " + format.width + "x" + format.height + " / " + format.sampleMimeType!!.replace(
                "video/",
                ""
            ) + "\n" +
                    "Audio: " + currentVolumePercentage + "% / " + exoPlayer.audioFormat!!.sampleMimeType!!.replace(
                "audio/",
                ""
            ) + "\n" +
                    "Current: " + videoTrackName + " / " + audioTrackName + "\n" +
                    "Frames: " + getDecoderCountersBufferCountString(decoderCounters)
            val event: MutableMap<String, Any> = HashMap<String, Any>()
            event["event"] = "nerdStat"
            event["values"] = data
            eventSink.success(event)
            return data
        }
        return super.getVideoString()
    }

    private fun getDecoderCountersBufferCountString(counters: DecoderCounters?): String {
        if (counters == null) {
            return ""
        }
        counters.ensureUpdated()
        return counters.droppedBufferCount.toString() + " dropped of " + counters.renderedOutputBufferCount
    }
}