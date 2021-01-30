package com.jhomlala.better_player;

import com.google.android.exoplayer2.DefaultLoadControl;
import com.google.android.exoplayer2.LoadControl;
import com.google.android.exoplayer2.Renderer;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;
import com.google.android.exoplayer2.upstream.Allocator;

public class BetterPlayerLoadControlAdapter implements LoadControl {

    LoadControl defaultLoadControl;
    LoadControl betterPlayerLoadControl;

    private boolean isDefaultMode = true;

    BetterPlayerLoadControlAdapter() {
        defaultLoadControl = new DefaultLoadControl();
        betterPlayerLoadControl = new BetterPlayerLoadControl();
    }

    public void setDefaultMode(boolean isDefault) {
        this.isDefaultMode = isDefault;
    }

    @Override
    public void onPrepared() {
        if (isDefaultMode) {
            defaultLoadControl.onPrepared();
        } else {
            betterPlayerLoadControl.onPrepared();
        }
    }

    @Override
    public void onTracksSelected(Renderer[] renderers, TrackGroupArray trackGroups, TrackSelectionArray trackSelections) {
        if (isDefaultMode) {
            defaultLoadControl.onTracksSelected(renderers, trackGroups, trackSelections);
        } else {
            betterPlayerLoadControl.onTracksSelected(renderers, trackGroups, trackSelections);
        }
    }

    @Override
    public void onStopped() {
        if (isDefaultMode) {
            defaultLoadControl.onStopped();
        } else {
            betterPlayerLoadControl.onStopped();
        }
    }

    @Override
    public void onReleased() {
        if (isDefaultMode) {
            defaultLoadControl.onReleased();
        } else {
            betterPlayerLoadControl.onReleased();
        }
    }

    @Override
    public Allocator getAllocator() {
        if (isDefaultMode) {
            return defaultLoadControl.getAllocator();
        } else {
            return betterPlayerLoadControl.getAllocator();
        }
    }

    @Override
    public long getBackBufferDurationUs() {
        if (isDefaultMode) {
            return defaultLoadControl.getBackBufferDurationUs();
        } else {
            return betterPlayerLoadControl.getBackBufferDurationUs();
        }
    }

    @Override
    public boolean retainBackBufferFromKeyframe() {
        if (isDefaultMode) {
            return defaultLoadControl.retainBackBufferFromKeyframe();
        } else {
            return betterPlayerLoadControl.retainBackBufferFromKeyframe();
        }
    }

    @Override
    public boolean shouldContinueLoading(long playbackPositionUs, long bufferedDurationUs, float playbackSpeed) {
        if (isDefaultMode) {
            return defaultLoadControl.shouldContinueLoading(playbackPositionUs, bufferedDurationUs, playbackSpeed);
        } else {
            return betterPlayerLoadControl.shouldContinueLoading(playbackPositionUs, bufferedDurationUs, playbackSpeed);
        }
    }

    @Override
    public boolean shouldStartPlayback(long bufferedDurationUs, float playbackSpeed, boolean rebuffering) {
        if (isDefaultMode) {
            return defaultLoadControl.shouldStartPlayback(bufferedDurationUs, playbackSpeed, rebuffering);
        } else {
            return betterPlayerLoadControl.shouldStartPlayback(bufferedDurationUs, playbackSpeed, rebuffering);
        }
    }
}
