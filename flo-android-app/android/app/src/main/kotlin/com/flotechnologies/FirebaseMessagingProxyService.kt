package com.flotechnologies

import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService
import java.lang.reflect.Field
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.Resources
import android.graphics.Color
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.Parcelable
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.annotation.DrawableRes
import androidx.core.content.getSystemService

/**
 * ref. https://github.com/firebase/quickstart-android/blob/master/messaging/app/src/main/java/com/google/firebase/quickstart/fcm/kotlin/MyFirebaseMessagingService.kt
 */
class FirebaseMessagingProxyService : FirebaseMessagingService() {

    companion object {
        const val TITLE = "title"
        const val BODY = "body"
        const val ICON = "icon"
        const val COLOR = "color"
        const val SOUND = "sound"
        const val TAG = "tag"
        const val CLICK_ACTION = "click_action"
        const val BODY_LOC_KEY = "body_loc_key"
        const val TITLE_LOC_KEY = "title_loc_key"
        const val CHANNEL_ID = "channel_id"
        const val TICKER = "ticker"
        const val STICKY = "sticky"
        const val EVENT_TIME = "event_time"
        const val LOCAL_ONLY = "local_only"
        const val NOTIFICATION_PRIORITY = "notification_priority"
        const val DEFAULT_SOUND = "default_sound"
        const val DEFAULT_VIBRATE_TIMINGS = "default_vibrate_timings"
        const val DEFAULT_LIGHT_SETTINGS = "default_light_settings"
        const val VISIBILITY = "visibility"
        const val NOTIFICATION_COUNT = "notification_count"
        const val LIGHT_SETTINGS = "light_settings"
        const val FLUTTER_NOTIFICATION_CLICK = "FLUTTER_NOTIFICATION_CLICK"
    }

    private val messagingServices: List<FirebaseMessagingService> by lazy {
        listOf(FlutterFirebaseMessagingService())
                .onEach { it.injectContext(this) }
    }

    override fun onCreate() {
        super.onCreate()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService<NotificationManager>()

            /*
            mDefaultNotificationChannel = notificationManager?.createNotificationChannel(NotificationChannel(
                    getString(R.string.default_notification_channel_id),
                    getString(R.string.default_notification_channel_name),
                    NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = getString(R.string.default_notification_channel_description)
            })
            */

            val alertsNotificationChannelGroup = NotificationChannelGroup(getString(R.string.alerts_notification_channel_group_id), getString(R.string.alerts_notification_channel_group_name))

            notificationManager?.createNotificationChannelGroup(alertsNotificationChannelGroup)

            notificationManager?.createNotificationChannel(NotificationChannel(
                    getString(R.string.critical_alerts_notification_channel_id),
                    getString(R.string.critical_alerts_notification_channel_name),
                    NotificationManager.IMPORTANCE_HIGH).apply {
                description = getString(R.string.critical_alerts_notification_channel_description)
                setShowBadge(true)
                group = alertsNotificationChannelGroup.id
                enableVibration(true)
            })

            notificationManager?.createNotificationChannel(NotificationChannel(
                    getString(R.string.warning_alerts_notification_channel_id),
                    getString(R.string.warning_alerts_notification_channel_name),
                    NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = getString(R.string.warning_alerts_notification_channel_description)
                setShowBadge(true)
                group = alertsNotificationChannelGroup.id
                enableVibration(false)
            })

            notificationManager?.createNotificationChannel(NotificationChannel(
                    getString(R.string.informative_alerts_notification_channel_id),
                    getString(R.string.informative_alerts_notification_channel_name),
                    NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = getString(R.string.informative_alerts_notification_channel_description)
                setShowBadge(true)
                group = alertsNotificationChannelGroup.id
                enableVibration(false)
            })
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "onNewToken: token")
        messagingServices.forEach { it.onNewToken(token) }
    }

    /**
     * ```
     * {
     *     "title": string,
     *     "body": string,
     *     "icon": string,
     *     "color": string,
     *     "sound": string,
     *     "tag": string,
     *     "click_action": string,
     *     "body_loc_key": string,
     *     "body_loc_args": [
     *         string
     *     ],
     *     "title_loc_key": string,
     *     "title_loc_args": [
     *         string
     *     ],
     *     "channel_id": string,
     *     "ticker": string,
     *     "sticky": boolean,
     *     "event_time": string,
     *     "local_only": boolean,
     *     "notification_priority": enum (notificationpriority),
     *     "default_sound": boolean,
     *     "default_vibrate_timings": boolean,
     *     "default_light_settings": boolean,
     *     "vibrate_timings": [
     *         string
     *     ],
     *     "visibility": enum (visibility),
     *     "notification_count": number,
     *     "light_settings": {
     *         object (lightsettings)
     *     },
     *     "image": string
     * }
     * ```
     *
     * ref. https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#AndroidConfig
     */
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        Log.d(TAG, "from: ${remoteMessage.from}")
        Log.d(TAG, "notification.title: ${remoteMessage.notification?.title}")
        Log.d(TAG, "notification.body: ${remoteMessage.notification?.body}")
        Log.d(TAG, "data: ${remoteMessage.data}")
        // Map.putIfAbsent requires SDK 24
        // remoteMessage.data.putIfAbsent(CLICK_ACTION, FLUTTER_NOTIFICATION_CLICK)
        // the remoteMessage.data should be a mutable reference, we don't need to re-assign
        remoteMessage.data.getOrPut(CLICK_ACTION) { FLUTTER_NOTIFICATION_CLICK }
        Log.d(TAG, "modified data: ${remoteMessage.data}")

        val body = remoteMessage.data[BODY]
        Log.d(TAG, "data.body: ${body}")

        if (body != null) {
            getSystemService<NotificationManager>()?.notify(
                    remoteMessage.data.hashCode(),
                    NotificationCompat.Builder(this, remoteMessage.data[CHANNEL_ID] ?: getNotificationChannelId())
                            .apply {
                                setSmallIcon(getNotificationIcon())
                                remoteMessage.data[COLOR]?.let { try { Color.parseColor(it) } catch (e: IllegalArgumentException) { null } }?.let { setColor(it) }
                                remoteMessage.data[TITLE]?.let { setContentTitle(it) }
                                setContentText(body)
                                setAutoCancel(true)
                                setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION))
                                setContentIntent(PendingIntent.getActivity(this@FirebaseMessagingProxyService,
                                        0,
                                        (remoteMessage.data[CLICK_ACTION]?.let { Intent(it) } ?: Intent(this@FirebaseMessagingProxyService, MainActivity::class.java)).apply {
                                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                                            putExtras(remoteMessage.data.toBundle())
                                        },
                                        PendingIntent.FLAG_ONE_SHOT))
                            }.build())
        }

        messagingServices.forEach { it.onMessageReceived(remoteMessage) }
    }

    override fun onDeletedMessages() {
        super.onDeletedMessages()
        Log.d(TAG, "onDeletedMessages")
        messagingServices.forEach { it.onDeletedMessages() }
    }

    override fun onMessageSent(message: String) {
        super.onMessageSent(message)
        Log.d(TAG, "onMessageSent: ${message}")
        messagingServices.forEach { it.onMessageSent(message) }
    }

    override fun onSendError(message: String, e: Exception) {
        super.onSendError(message, e)
        Log.d(TAG, "onSendError: ${message}", e)
        messagingServices.forEach { it.onSendError(message, e) }
    }
}

@DrawableRes
fun Context.getNotificationIcon(key: String = "com.google.firebase.messaging.default_notification_icon"): Int =
        metaData?.getInt(key)?.let {
            if (it != 0) it else R.drawable.ic_stat_flo_drip_shadow
        } ?: R.drawable.ic_stat_flo_drip_shadow

fun Context.getNotificationChannelId(key: String = "com.google.firebase.messaging.default_notification_channel_id"): String =
        metaData?.getResourceString(this, key) ?: getString(R.string.default_notification_channel_id)

fun Bundle.getResourceString(context: Context, key: String): String? {
    val resId = getInt(key)
    return if (resId != 0) try { context.getString(resId) } catch (e: Resources.NotFoundException) { getString(key) }
    else getString(key)
}


val Context.metaData: Bundle?
    get() {
        return try {
            packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA).metaData
        } catch (e: PackageManager.NameNotFoundException) {
            null
        }
    }

fun <T : Service> T.injectContext(context: T, func: T.() -> Unit = {}) {
    setField("mBase", context)
    func()
}

fun Class<*>.findDeclaredField(name: String): Field? {
    var clazz: Class<*>? = this
    do {
        try {
            return clazz?.getDeclaredField(name)
        } catch (e: Throwable) {}
        clazz = clazz?.superclass
    } while (clazz  != null)
    return null
}

fun Any.setField(name: String, value: Any): Boolean =
        javaClass.findDeclaredField(name)?.let {
            try {
                it.isAccessible = true
                it.set(this, value)
                true
            } catch (e: Throwable) { false }
        } ?: false

val Any.TAG: String
    get() { return javaClass.simpleName }

fun <V> Map<String, V>.toBundle(bundle: Bundle = Bundle()): Bundle = bundle.apply {
    forEach {
        val k = it.key
        when (val v = it.value) {
            is IBinder -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
                putBinder(k, v)
            } else {
                putString(k, v?.toString())
            }
            is Bundle -> putBundle(k, v)
            is Byte -> putByte(k, v)
            is ByteArray -> putByteArray(k, v)
            is Char -> putChar(k, v)
            is CharArray -> putCharArray(k, v)
            is CharSequence -> putCharSequence(k, v)
            is Float -> putFloat(k, v)
            is FloatArray -> putFloatArray(k, v)
            is Parcelable -> putParcelable(k, v)
            //is Serializable -> putSerializable(k, v)
            is Short -> putShort(k, v)
            is ShortArray -> putShortArray(k, v)
            //is Size -> putSize(k, v) //api 21
            //is SizeF -> putSizeF(k, v) //api 21
            //is Array<*> -> TODO()
            //is List<*> -> TODO()
            //else -> throw IllegalArgumentException("$v is of a type that is not currently supported")
            else -> putString(k, v?.toString())
        }
    }
}

/*
@Serializable
data class PushNotification(
        val title: String?,
        val body: String?,
        val data: String?
        )
*/

//@Serializable
//data class PushNotificationData(
//        val title: String?,
//        val body: String?,
//        val data: String?,
//        )
