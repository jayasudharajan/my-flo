package com.flotechnologies

import io.flutter.app.FlutterApplication
import io.flutter.plugins.GeneratedPluginRegistrant
import android.content.Context
import androidx.multidex.MultiDex;
import io.embrace.android.embracesdk.Embrace
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugins.ActivityPlugin
import io.flutter.plugins.firebase.core.FirebaseCorePlugin
import io.flutter.plugins.firebaseauth.FirebaseAuthPlugin
import io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin
import io.flutter.plugins.firebasemessaging.FlutterFirebaseMessagingService
import com.instabug.instabugflutter.InstabugFlutterPlugin

class App : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {

    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }

    override fun onCreate() {
        super.onCreate()
        Embrace.getInstance().start(this)
        InstabugFlutterPlugin().start(this,
                "05d67f38bd1ad13fed750803dfb9e722",
                arrayListOf(
                        //InstabugFlutterPlugin.INVOCATION_EVENT_NONE,
                        //InstabugFlutterPlugin.INVOCATION_EVENT_SCREENSHOT,
                        //InstabugFlutterPlugin.INVOCATION_EVENT_TWO_FINGER_SWIPE_LEFT,
                        //InstabugFlutterPlugin.INVOCATION_EVENT_FLOATING_BUTTON,
                        InstabugFlutterPlugin.INVOCATION_EVENT_SHAKE
                ));
        FlutterFirebaseMessagingService.setPluginRegistrant(this)
    }

    override fun registerWith(registry: PluginRegistry) {
        try {
            // some of plugins require activity()
            //GeneratedPluginRegistrant.registerWith(registry)
            FirebaseAuthPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebaseauth.FirebaseAuthPlugin"))
            FirebaseCorePlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebase.core.FirebaseCorePlugin"))
            FirebaseMessagingPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"))
        } catch (e: Throwable) {
        }
    }
}