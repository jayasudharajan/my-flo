package com.flotechnologies

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.plugins.ActivityPlugin
import androidx.appcompat.app.AppCompatActivity

class IncidentActivity: AppCompatActivity() {
  override fun onNewIntent(intent: Intent?) {
    super.onNewIntent(intent)

    ActivityPlugin.channel?.invokeMethod("onNewIntent", hashMapOf<String, String?>(
            "action" to (intent?.action ?: intent?.extras?.getString("action")),
            "data" to (intent?.extras?.getString("data") ?: intent?.extras?.getString("FloAlarmNotification")),
            "type" to intent?.type
    ))

    val action = (intent?.action ?: intent?.extras?.getString("action"))
    val data = (intent?.extras?.getString("data") ?: intent?.extras?.getString("FloAlarmNotification"))
    val type = intent?.type

    println("IncidentActivity $action $data $type")

    startActivityIfNeeded(Intent(this, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
      putExtra("action", action)
      putExtra("FloAlarmNotification", data)
      putExtra("data", data)
    }, 0)
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    val action = (intent?.action ?: intent?.extras?.getString("action"))
    val data = (intent?.extras?.getString("data") ?: intent?.extras?.getString("FloAlarmNotification"))
    val type = intent?.type

    println("IncidentActivity $action $data $type")

    ActivityPlugin.channel?.invokeMethod("onNewIntent", hashMapOf<String, String?>(
            "action" to action,
            "data" to data,
            "type" to type
    ))


    startActivityIfNeeded(Intent(this, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
      putExtra("action", action)
      putExtra("FloAlarmNotification", data)
      putExtra("data", data)
    }, 0)
    finish()
  }
}
