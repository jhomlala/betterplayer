package com.jhomlala.better_player_example

import android.app.NotificationManager
import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Observer
import com.jhomlala.better_player.NotificationService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private lateinit var channel: EventChannel
    var eventSink: EventChannel.EventSink? = null
    private var notificationManager: NotificationManager? = null

    // Observe update of notification action.
    private val notificationBuilderObserver =
        Observer<NotificationCompat.Builder?> {
            it?.let {
                updateNotification(it)
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        NotificationService.notificationBuilder.observeForever(notificationBuilderObserver)
    }

    override fun onDestroy() {
        NotificationService.notificationBuilder.removeObserver(notificationBuilderObserver)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "better_player.nfc_ch_app/pip_status_event_channel")
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

    // Update Notification to reflect actions set in BetterPlayerPlugin based on player status.
    private fun updateNotification(notificationBuilder: NotificationCompat.Builder) {
        // Set small icon because available in app side.
        notificationBuilder.setSmallIcon(R.mipmap.ic_launcher)
        notificationManager?.notify(NotificationService.foregroundNotificationId, notificationBuilder.build())
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        eventSink?.success(isInPictureInPictureMode)
    }

}
