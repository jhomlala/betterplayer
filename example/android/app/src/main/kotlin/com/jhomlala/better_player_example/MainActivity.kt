package com.jhomlala.better_player_example

import android.content.Intent
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import androidx.annotation.RequiresApi
import androidx.lifecycle.Observer
import com.jhomlala.better_player.BetterPlayerPlugin
import com.jhomlala.better_player.NotificationParameter
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private lateinit var channel: EventChannel
    var eventSink: EventChannel.EventSink? = null

    @RequiresApi(Build.VERSION_CODES.O)
    private var notificationParameterObserver =
        Observer<NotificationParameter?>
        { parameter ->
            Log.d("NFCDEV", "notificationParameterObserver param: " + parameter.toString())
            if (parameter != null) {
                startNotificationService(parameter)
            } else {
                stopNotificationService()
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            BetterPlayerPlugin.notificationParameter.observeForever(notificationParameterObserver)
        }
    }

    override fun onDestroy() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            BetterPlayerPlugin.notificationParameter.removeObserver(notificationParameterObserver)
        }
        stopNotificationService()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "better_player.nfc_ch_app/pip_status_event_channel"
        )
        channel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun startNotificationService(notificationParameter: NotificationParameter) {
        Log.d("NFCDEV", "MainActivity startNotificationService param: " + parameter.toString())
        val intent = Intent(this, BetterPlayerNotificationService::class.java)
        intent.putExtra(
            BetterPlayerPlugin.TITLE_PARAMETER, notificationParameter.title
        )
        intent.putExtra(
            BetterPlayerPlugin.AUTHOR_PARAMETER, notificationParameter.author
        )
        intent.putExtra(
            BetterPlayerPlugin.IMAGE_URL_PARAMETER,
            notificationParameter.imageUrl
        )
        intent.putExtra(
            BetterPlayerPlugin.NOTIFICATION_CHANNEL_NAME_PARAMETER,
            notificationParameter.notificationChannelName
        )
        intent.putExtra(
            BetterPlayerPlugin.ACTIVITY_NAME_PARAMETER,
            notificationParameter.activityName
        )

        intent.putExtra(
            BetterPlayerPlugin.MEDIA_SESSION_TOKEN_PARAMETER,
            notificationParameter.mediaSessionToken
        )
        intent.putExtra(
            BetterPlayerNotificationService.SMALL_ICON_RESOURCE_ID,
            R.mipmap.ic_launcher
        )
        startForegroundService(intent)
    }

    private fun stopNotificationService() {
        val intent = Intent(this, BetterPlayerNotificationService::class.java)
        stopService(intent)
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        eventSink?.success(isInPictureInPictureMode)
    }

}
