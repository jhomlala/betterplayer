package com.jhomlala.better_player;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class ChromeCastFactoryJava extends PlatformViewFactory{

    public Activity activty;
    BinaryMessenger binaryMessenger;

    public ChromeCastFactoryJava(BinaryMessenger binaryMessenger) {
        super(StandardMessageCodec.INSTANCE);
        this.binaryMessenger = binaryMessenger;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        Log.d("ChromeCast","Create view! " + viewId);
        return new ChromeCastControllerJava(binaryMessenger,viewId,activty);
    }
}