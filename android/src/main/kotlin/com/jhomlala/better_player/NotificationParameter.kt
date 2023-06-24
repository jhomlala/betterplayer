package com.jhomlala.better_player

import android.support.v4.media.session.MediaSessionCompat

class NotificationParameter(
    val title: String,
    val author: String,
    val imageUrl: String,
    val notificationChannelName: String,
    val activityName: String,
    val mediaSessionToken: MediaSessionCompat.Token
)