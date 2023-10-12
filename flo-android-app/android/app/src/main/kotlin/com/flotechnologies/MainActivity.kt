package com.flotechnologies

import android.os.Bundle

import io.flutter.app.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant
import com.amazonaws.auth.AWSCredentialsProvider
import com.amazonaws.mobile.client.AWSMobileClient
import com.amazonaws.mobile.client.UserStateDetails
import com.amazonaws.mobile.config.AWSConfiguration
import com.amazonaws.mobileconnectors.pinpoint.PinpointConfiguration
import com.amazonaws.mobileconnectors.pinpoint.PinpointManager
import com.google.firebase.iid.FirebaseInstanceId
import android.util.Log
import android.content.Context
import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.ActivityPlugin
import io.flutter.view.FlutterView
import java.util.HashMap

class MainActivity: FlutterActivity() {

  override fun onNewIntent(intent: Intent?) {
    super.onNewIntent(intent)

    // onIntent(intent)

    ActivityPlugin.instance?.onIntent(intent);
  }

  fun onIntent(intent: Intent?) {
    val action = (intent?.action ?: intent?.extras?.getString("action"))
    val data = (intent?.extras?.getString("data") ?: intent?.extras?.getString("FloAlarmNotification"))
    val type = intent?.type

    Log.d("MainActivity", "onResume $action $data $type")

    ActivityPlugin.channel?.invokeMethod("onNewIntent", hashMapOf<String, String?>(
            "action" to action,
            "data" to data,
            "type" to type
    ))

    ActivityPlugin.instance?.onIntent(intent);
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    GeneratedPluginRegistrant.registerWith(this)
    ActivityPlugin.registerWith(registrarFor(ActivityPlugin::class.java.canonicalName))

    val awsConfig: AWSConfiguration = AWSConfiguration(this)

    AWSMobileClient.getInstance().initialize(this, awsConfig) {
      onResult {
        Log.d("MainActivity", "${it.userState}")
      }
      onError { e ->
        e.printStackTrace()
      }
    }
    val pinpoint = PinpointManager(PinpointConfiguration(
            this,
            AWSMobileClient.getInstance(),
            awsConfig))


    FirebaseInstanceId.getInstance().instanceId.addOnCompleteListener { task ->
      if (task.isSuccessful) {
        val token = task.result?.token
        Log.d("MainActivity", "Registering push notifications token: ${token}")
        token?.let { pinpoint.notificationClient.registerDeviceToken(token) }
      } else {
        Log.w("MainActivity", "getInstanceId failed", task.exception)
      }
    }

    flutterView.enableTransparentBackground()

    ActivityPlugin.instance?.onIntent(intent);
    //onIntent(intent)
  }

  override fun onResume() {
    super.onResume()

    //onIntent(intent)
  }
}

fun AWSMobileClient.initialize(context: Context, config: AWSConfiguration, init: Callbacks<UserStateDetails>.() -> Unit) : AWSCredentialsProvider {
  val callbacks = Callbacks<UserStateDetails>()
  callbacks.init()
  this.initialize(context, config, callbacks)
  return this
}

class Callbacks<T> : com.amazonaws.mobile.client.Callback<T> {
  var onResultFunc: (T) -> Unit = {}
  var onErrorFunc: (Throwable) -> Unit = {}

  override fun onResult(result: T) {
      onResultFunc(result)
  }

  fun onResult(onResult: (T) -> Unit) {
      this.onResultFunc = onResult
  }

  override fun onError(e: Exception?) {
      onErrorFunc(e ?: Exception())
  }

  fun onError(onError: (Throwable) -> Unit) {
      this.onErrorFunc = onError
  }
}
