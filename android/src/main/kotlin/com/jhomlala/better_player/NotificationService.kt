package com.jhomlala.better_player

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.IBinder
import android.support.v4.media.session.MediaSessionCompat
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationCompat.PRIORITY_MIN
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Observer
import com.google.android.exoplayer2.ui.R
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.ACTIVITY_NAME_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.AUTHOR_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.IMAGE_URL_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.MEDIA_SESSION_TOKEN_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.NOTIFICATION_CHANNEL_NAME_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.TITLE_PARAMETER
import com.squareup.picasso.Picasso
import com.squareup.picasso.Target

class NotificationService : Service() {
    private var notificationBuilder: NotificationCompat.Builder? = null

//    @SuppressLint("RestrictedApi")
//    fun NotificationCompat.Builder.clearActions() {
//        mActions.clear()
//    }

    companion object {
        var notificationBuilderInNotificationService: MutableLiveData<NotificationCompat.Builder?> =
            MutableLiveData()
        const val notificationId = 20772077
        const val foregroundNotificationId = 20772078
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    // Observe update of notification action.
    private val notificationActionListObserver =
        Observer<List<NotificationCompat.Action>?> { actions ->
            actions?.map {
                notificationBuilder?.clearActions()
                notificationBuilder?.addAction(it)
            }
            notificationBuilderInNotificationService.value = notificationBuilder
        }

    // Load image.
    private var imageDownloadHandler: Target = object : Target {
        override fun onBitmapLoaded(bitmap: Bitmap?, from: Picasso.LoadedFrom?) {
            // Use as setLargeIcon on notification.
            notificationBuilder?.setLargeIcon(bitmap)
            notificationBuilderInNotificationService.value = notificationBuilder
        }

        override fun onPrepareLoad(placeHolderDrawable: Drawable?) {}

        override fun onBitmapFailed(e: Exception?, errorDrawable: Drawable?) {}
    }

    @SuppressLint("PrivateResource")
    @RequiresApi(Build.VERSION_CODES.M)
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(TITLE_PARAMETER)
        val author = intent?.getStringExtra(AUTHOR_PARAMETER)
        val imageUrl = intent?.getStringExtra(IMAGE_URL_PARAMETER)
        val notificationChannelName = intent?.getStringExtra(NOTIFICATION_CHANNEL_NAME_PARAMETER)
        val activityName = intent?.getStringExtra(ACTIVITY_NAME_PARAMETER)
        val packageName = this.applicationContext.packageName

        BetterPlayerPlugin.pendingActions.observeForever(notificationActionListObserver)

        val channelId =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && notificationChannelName != null) {
                createNotificationChannel(notificationId.toString(), notificationChannelName)
            } else {
                ""
            }

        //  set MediaSession's token
        val sessionToken =
            intent?.getParcelableExtra<MediaSessionCompat.Token>(MEDIA_SESSION_TOKEN_PARAMETER)
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

        val notificationBuilder2 = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(author)
            .setStyle(mediaStyle)
            .addAction(pauseAction)
            .setSmallIcon(R.drawable.exo_notification_small_icon) // TODO: Use app icon
            .setPriority(PRIORITY_MIN)
            .setContentIntent(pendingIntent)
        mediaStyle.setShowActionsInCompactView(0)

        notificationBuilder = notificationBuilder2
        startForeground(foregroundNotificationId, notificationBuilder?.build())

        return START_NOT_STICKY
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
        BetterPlayerPlugin.pendingActions.removeObserver(notificationActionListObserver)
        try {
            val notificationManager =
                getSystemService(
                    Context.NOTIFICATION_SERVICE
                ) as NotificationManager
            notificationManager.cancel(foregroundNotificationId)
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