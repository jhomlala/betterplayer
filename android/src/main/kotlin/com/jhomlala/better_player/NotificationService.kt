package com.jhomlala.better_player

import android.annotation.SuppressLint
import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.support.v4.media.session.MediaSessionCompat
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationCompat.PRIORITY_MIN
import com.google.android.exoplayer2.ui.R.drawable.exo_notification_pause
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.ACTIVITY_NAME_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.AUTHOR_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.IMAGE_URL_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.MEDIA_SESSION_TOKEN_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.NOTIFICATION_CHANNEL_NAME_PARAMETER
import com.jhomlala.better_player.BetterPlayerPlugin.Companion.TITLE_PARAMETER
import com.jhomlala.better_player.R.drawable.exo_notification_play

class NotificationService : Service() {
//    private var notificationManager: NotificationManager? = null

    companion object {
        const val notificationId = 20772077
        const val foregroundNotificationId = 20772078
        private const val TAG = "BetterPlayer"
//        enum class NotificationActions(val rawValue: androidx.core.app.NotificationCompat.Action) {
//            PLAY_ACTION(
//                androidx.core.app.NotificationCompat.Action.Builder(
//                    R.drawable.better_player_play_arrow_24dp,
//                    "",
//                    PendingIntent.getBroadcast(
//                        this, // context があるので定数にはできない
//                        BetterPlayerPlugin.Companion.PipActions.PLAY.rawValue,
//                        Intent(BetterPlayerPlugin.DW_NFC_BETTER_PLAYER_CUSTOM_PIP_ACTION).putExtra(
//                            BetterPlayerPlugin.EXTRA_ACTION_TYPE,
//                            BetterPlayerPlugin.Companion.PipActions.PLAY.rawValue
//                        ),
//                        PendingIntent.FLAG_IMMUTABLE
//                    )
//                ).build()
//            ),
//            PAUSE_ACTION(
//                androidx.core.app.NotificationCompat.Action.Builder(
//                    R.drawable.better_player_pause_24dp,
//                    "",
//                    PendingIntent.getBroadcast(
//                        this,
//                        BetterPlayerPlugin.Companion.PipActions.PAUSE.rawValue,
//                        Intent(BetterPlayerPlugin.DW_NFC_BETTER_PLAYER_CUSTOM_PIP_ACTION).putExtra(
//                            BetterPlayerPlugin.EXTRA_ACTION_TYPE,
//                            BetterPlayerPlugin.Companion.PipActions.PAUSE.rawValue
//                        ),
//                        PendingIntent.FLAG_IMMUTABLE
//                    )
//                ).build()
//            )
//        }
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    @SuppressLint("PrivateResource")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        val title = intent?.getStringExtra(TITLE_PARAMETER)
        val auther = intent?.getStringExtra(AUTHOR_PARAMETER)
        val imageUrl = intent?.getStringExtra(IMAGE_URL_PARAMETER)
        val notificationChannelName = intent?.getStringExtra(NOTIFICATION_CHANNEL_NAME_PARAMETER)
        val activityName = intent?.getStringExtra(ACTIVITY_NAME_PARAMETER)
        val packageName = this.applicationContext.packageName
//        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

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

        val pauseAction: NotificationCompat.Action =
            NotificationCompat.Action.Builder(
                exo_notification_pause,
                "",
                createPendingIntent(BetterPlayerPlugin.Companion.PipActions.PAUSE.rawValue)
            )
                .build()

        val playAction: NotificationCompat.Action =
            NotificationCompat.Action.Builder(
                exo_notification_play,
                "",
                createPendingIntent(BetterPlayerPlugin.Companion.PipActions.PLAY.rawValue)
            )
                .build()

//        val imageBitmap = Picasso.get().load(imageUrl).into(object: com.squareup.picasso.Target() {
//            override fun onPrepareLoad(placeHolderDrawable: Drawable?) {
//                Log.d(TAG, "Getting ready to get the image")
//                //Here you should place a loading gif in the ImageView
//                //while image is being obtained.
//            }
//
//            override fun onBitmapFailed(e: Exception?, errorDrawable: Drawable?) {
//                Log.e(TAG, "The image was not obtained");
//            }
//
//            override fun onBitmapLoaded(bitmap: Bitmap?, from: Picasso.LoadedFrom?) {
//                Log.d(TAG, "The image was obtained correctly");
//            }
//        })

        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
//            .setContentTitle("At service " + LocalDateTime.now().toString()) // TODO: Delete
            .setContentText(auther)
            .setStyle(mediaStyle)
            .addAction(playAction)
            .addAction(pauseAction)
//            .setLargeIcon(imageBitmap.) // TODO:
            .setSmallIcon(R.drawable.exo_media_action_repeat_all) // TODO: Use app icon

            .setPriority(PRIORITY_MIN)
//            .setOngoing(true)
            .setContentIntent(pendingIntent)
        mediaStyle.setShowActionsInCompactView(0)

        startForeground(foregroundNotificationId, notificationBuilder.build())
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