//package com.jhomlala.better_player_example
//
//import android.app.*
//import android.content.Context
//import android.content.Intent
//import android.os.Build
//import android.os.IBinder
//import androidx.annotation.RequiresApi
//import androidx.core.app.NotificationCompat
//import androidx.core.app.NotificationCompat.PRIORITY_MIN
//
//class BetterPlayerService : Service() {
//    companion object {
//        const val notificationId = 20772077
//        const val foregroundNotificationId = 20772078
//        const val channelId = "VideoPlayer"
//        private const val TAG = "BetterPlayer"
//    }
//
//    override fun onBind(intent: Intent?): IBinder? {
//        return null
//    }
//
//    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
//        val channelId =
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                createNotificationChannel(channelId, "Channel")
//            } else {
//                ""
//            }
//        val notificationIntent = Intent(this, MainActivity::class.java)
//        val pendingIntent =
//            PendingIntent.getActivity(
//                this, 0, notificationIntent,
//                PendingIntent.FLAG_IMMUTABLE
//            )
//
//
//        val notificationBuilder = NotificationCompat.Builder(this, channelId)
//            .setContentTitle("[BetterPlayerService]Better Player Notification")
//            .setContentText("Better Player is running")
//            .setSmallIcon(R.mipmap.ic_launcher)
//            .setPriority(PRIORITY_MIN)
//            .setOngoing(true)
//            .setContentIntent(pendingIntent)
//
//        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//            notificationBuilder.setCategory(Notification.CATEGORY_SERVICE);
//        }
//        startForeground(foregroundNotificationId, notificationBuilder.build())
//        return START_NOT_STICKY
//    }
//
//    @RequiresApi(Build.VERSION_CODES.O)
//    private fun createNotificationChannel(channelId: String, channelName: String): String {
//        val chan = NotificationChannel(
//            channelId,
//            channelName, NotificationManager.IMPORTANCE_NONE
//        )
//        val service = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
//        service.createNotificationChannel(chan)
//        return channelId
//    }
//
//    override fun onTaskRemoved(rootIntent: Intent?) {
//        try {
//            val notificationManager =
//                getSystemService(
//                    Context.NOTIFICATION_SERVICE
//                ) as NotificationManager
//            notificationManager.cancel(notificationId)
//        } catch (exception: Exception) {
//
//        } finally {
//            stopSelf()
//        }
//    }
//
////
////    fun setupMediaSession(context: Context?): MediaSessionCompat? {
////        mediaSession?.release()
////        context?.let {
////
////            val mediaButtonIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
////            val pendingIntent = PendingIntent.getBroadcast(
////                context,
////                0, mediaButtonIntent,
////                PendingIntent.FLAG_IMMUTABLE
////            )
////            val mediaSession = MediaSessionCompat(context, TAG, null, pendingIntent) //
//////            mediaSession.setCallback(object : MediaSessionCompat.Callback() {
//////                override fun onSeekTo(pos: Long) {
//////                    sendSeekToEvent(pos)
//////                    super.onSeekTo(pos)
//////                }
//////            })
////            mediaSession.isActive = true
////            val mediaSessionConnector = MediaSessionConnector(mediaSession)
////            mediaSessionConnector.setPlayer(exoPlayer)
////            this.mediaSession = mediaSession
////            return mediaSession
////        }
////        return null
////    }
//}