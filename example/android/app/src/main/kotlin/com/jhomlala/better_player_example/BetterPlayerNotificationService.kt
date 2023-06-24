package com.jhomlala.better_player_example

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.IBinder
import android.support.v4.media.session.MediaSessionCompat
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.lifecycle.Observer
import com.google.android.exoplayer2.ui.R
import com.jhomlala.better_player.BetterPlayerPlugin
import com.squareup.picasso.Picasso
import com.squareup.picasso.Target

class BetterPlayerNotificationService: Service() {
    private var notificationBuilder: NotificationCompat.Builder? = null
    private var notificationManager: NotificationManager? = null

    companion object {
        const val NOTIFICATION_ID = 20772077
        const val FOREGROUND_NOTIFICATION_ID = 20772078
        const val SMALL_ICON_RESOURCE_ID = "smallIconResourceId"
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    // Observe update of notification action.
    private val notificationActionListObserver =
        Observer<List<NotificationCompat.Action>?> { actions ->
            actions?.map { action ->
                notificationBuilder?.clearActions()
                notificationBuilder?.addAction(action)
            }
            updateNotification()
        }

    // Load image.
    private var imageDownloadHandler: Target = object : Target {
        override fun onBitmapLoaded(bitmap: Bitmap?, from: Picasso.LoadedFrom?) {
            // Use as setLargeIcon on notification.
            notificationBuilder?.setLargeIcon(bitmap)
            updateNotification()
        }

        override fun onPrepareLoad(placeHolderDrawable: Drawable?) {}

        override fun onBitmapFailed(e: Exception?, errorDrawable: Drawable?) {
            Log.d("NotificationService", "onBitmapFailed e: " + e?.localizedMessage)
        }
    }

    @SuppressLint("PrivateResource")
    @RequiresApi(Build.VERSION_CODES.M)
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val title = intent?.getStringExtra(BetterPlayerPlugin.TITLE_PARAMETER)
        val author = intent?.getStringExtra(BetterPlayerPlugin.AUTHOR_PARAMETER)
        val imageUrl = intent?.getStringExtra(BetterPlayerPlugin.IMAGE_URL_PARAMETER)
        val notificationChannelName = intent?.getStringExtra(BetterPlayerPlugin.NOTIFICATION_CHANNEL_NAME_PARAMETER)
        val activityName = intent?.getStringExtra(BetterPlayerPlugin.ACTIVITY_NAME_PARAMETER)
        val packageName = this.applicationContext.packageName
        val smallIconResourceId = intent?.getIntExtra(SMALL_ICON_RESOURCE_ID, 0)

        val channelId =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && notificationChannelName != null) {
                createNotificationChannel(NOTIFICATION_ID.toString(), notificationChannelName)
            } else {
                ""
            }

        //  set MediaSession's token
        val sessionToken =
            intent?.getParcelableExtra<MediaSessionCompat.Token>(BetterPlayerPlugin.MEDIA_SESSION_TOKEN_PARAMETER)
        val mediaStyle =
            androidx.media.app.NotificationCompat.MediaStyle().setMediaSession(sessionToken)

        val notificationIntent = Intent()
        notificationIntent.setClassName(
            packageName!!,
            "$packageName.$activityName"
        )
        notificationIntent.flags = (Intent.FLAG_ACTIVITY_CLEAR_TOP
                or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        // PAUSE as a Default Action
        val pauseAction: NotificationCompat.Action =
            NotificationCompat.Action.Builder(
                R.drawable.exo_notification_pause,
                "",
                createPendingIntent(BetterPlayerPlugin.Companion.PipActions.PAUSE.rawValue)
            )
                .build()

        Picasso.get().load(imageUrl).into(imageDownloadHandler)

        notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(author)
            .setStyle(mediaStyle)
            .setSmallIcon(smallIconResourceId ?: 0)

            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setContentIntent(pendingIntent)

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.S) {
            notificationBuilder?.addAction(pauseAction)
        }

        mediaStyle.setShowActionsInCompactView(0)
        startForeground(FOREGROUND_NOTIFICATION_ID, notificationBuilder?.build())

        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.S) {
            BetterPlayerPlugin.notificationActions.observeForever(notificationActionListObserver)
        }

        return START_NOT_STICKY
    }

    // Update Notification to reflect actions set in BetterPlayerPlugin based on player status.
    private fun updateNotification() {
        notificationManager?.notify(FOREGROUND_NOTIFICATION_ID, notificationBuilder?.build())
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun createNotificationChannel(channelId: String, channelName: String): String {
        val channel = NotificationChannel(
            channelId, // Should be unique in App
            channelName, // Will be shown in Setting app
            NotificationManager.IMPORTANCE_NONE
        )
        val service = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        service.createNotificationChannel(channel)
        return channelId
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.S) {
            BetterPlayerPlugin.notificationActions.removeObserver(notificationActionListObserver)
        }

        try {
            val notificationManager =
                getSystemService(
                    Context.NOTIFICATION_SERVICE
                ) as NotificationManager
            notificationManager.cancel(FOREGROUND_NOTIFICATION_ID)
        } catch (exception: Exception) {

        } finally {
            stopSelf()
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    private fun createPendingIntent(actionId: Int): PendingIntent {
        return PendingIntent.getBroadcast(
            this,
            actionId,
            Intent(BetterPlayerPlugin.DW_NFC_BETTER_PLAYER_CUSTOM_PIP_ACTION).putExtra(
                BetterPlayerPlugin.EXTRA_ACTION_TYPE,
                actionId
            ),
            PendingIntent.FLAG_IMMUTABLE
        )
    }
}