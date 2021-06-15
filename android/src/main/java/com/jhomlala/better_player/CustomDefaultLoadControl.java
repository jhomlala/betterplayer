package com.jhomlala.better_player;

import com.google.android.exoplayer2.DefaultLoadControl;

class CustomDefaultLoadControl {
    /**
     * The default minimum duration of media that the player will attempt to ensure is buffered
     * at all times, in milliseconds.
     **/
    public final int minBufferMs;

    /**
     * The default maximum duration of media that the player will attempt to buffer, in milliseconds.
     **/
    public final int maxBufferMs;

    /**
     * The default duration of media that must be buffered for playback to start or resume following
     * a user action such as a seek, in milliseconds.
     **/
    public final int bufferForPlaybackMs;

    /**
     * he default duration of media that must be buffered for playback to resume after a rebuffer,
     * in milliseconds. A rebuffer is defined to be caused by buffer depletion rather than a user
     * action.
     **/
    public final int bufferForPlaybackAfterRebufferMs;

    CustomDefaultLoadControl() {
        this.minBufferMs = DefaultLoadControl.DEFAULT_MIN_BUFFER_MS;
        this.maxBufferMs = DefaultLoadControl.DEFAULT_MAX_BUFFER_MS;
        this.bufferForPlaybackMs = DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_MS;
        this.bufferForPlaybackAfterRebufferMs =
                DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS;

    }

    CustomDefaultLoadControl(
            Integer minBufferMs,
            Integer maxBufferMs,
            Integer bufferForPlaybackMs,
            Integer bufferForPlaybackAfterRebufferMs
    ) {
        this.minBufferMs = minBufferMs != null ? minBufferMs : DefaultLoadControl.DEFAULT_MIN_BUFFER_MS;
        this.maxBufferMs = maxBufferMs != null ? maxBufferMs : DefaultLoadControl.DEFAULT_MAX_BUFFER_MS;
        this.bufferForPlaybackMs = bufferForPlaybackMs != null ? bufferForPlaybackMs :
                DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_MS;
        this.bufferForPlaybackAfterRebufferMs = bufferForPlaybackAfterRebufferMs != null ?
                bufferForPlaybackAfterRebufferMs :
                DefaultLoadControl.DEFAULT_BUFFER_FOR_PLAYBACK_AFTER_REBUFFER_MS;
    }
}
