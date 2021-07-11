package com.jhomlala.better_player;

import android.content.Context;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.ContextThemeWrapper;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.mediarouter.app.MediaRouteButton;
import androidx.mediarouter.media.MediaRouter;

import com.google.android.gms.cast.framework.SessionManager;
import com.google.android.gms.common.api.PendingResult;
import com.google.android.gms.cast.MediaInfo;
import com.google.android.gms.cast.MediaLoadOptions;
import com.google.android.gms.cast.framework.CastButtonFactory;
import com.google.android.gms.cast.framework.CastContext;
import com.google.android.gms.cast.framework.Session;
import com.google.android.gms.cast.framework.SessionManagerListener;
import com.google.android.gms.common.api.Status;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class ChromeCastController implements PlatformView, MethodChannel.MethodCallHandler {
    final BinaryMessenger binaryMessenger;
    final int viewId;
    final Context context;
    MethodChannel methodChannel;
    MediaRouteButton mediaRouteButton;
    SessionManager sessionManager;

    ChromeCastController(BinaryMessenger binaryMessenger, int viewId, Context context) {
        this.binaryMessenger = binaryMessenger;
        this.viewId = viewId;
        this.context = context;
        methodChannel = new MethodChannel(binaryMessenger, "better_player_cast_" + viewId);
        mediaRouteButton = new MediaRouteButton(context);
        mediaRouteButton.setRemoteIndicatorDrawable(new ColorDrawable(Color.TRANSPARENT));
        sessionManager = CastContext.getSharedInstance().getSessionManager();
        CastButtonFactory.setUpMediaRouteButton(context, mediaRouteButton);
        methodChannel.setMethodCallHandler(this);
    }


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("click")) {
            mediaRouteButton.performClick();
            result.success(null);
        }
    }

    @Override
    public View getView() {
        return mediaRouteButton;
    }

    @Override
    public void onFlutterViewAttached(@NonNull View flutterView) {

    }

    @Override
    public void onFlutterViewDetached() {

    }

    @Override
    public void dispose() {

    }

    @Override
    public void onInputConnectionLocked() {

    }

    @Override
    public void onInputConnectionUnlocked() {

    }
}