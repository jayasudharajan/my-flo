package com.flotechnologies

import android.os.Bundle

import io.flutter.app.FlutterAppCompatActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainAppCompatActivity: FlutterAppCompatActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)
    flutterView.enableTransparentBackground()
  }
}