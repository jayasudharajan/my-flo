package io.flutter.plugins;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import android.util.Log;

public final class ActivityPlugin implements PluginRegistry.NewIntentListener, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
  @Nullable
  public static ActivityPlugin instance;
  @Nullable
  public static MethodChannel channel;
  @Nullable
  public static EventChannel eventChannel;

  @Nullable
  private BroadcastReceiver eventReceiver;

  private final Activity activity; // for null validation only
  private final PluginRegistry.Registrar registrar;

  public static synchronized void registerWith(@NonNull PluginRegistry.Registrar registrar) {
    if (registrar.activity() == null) {
      return;
    }

    if (ActivityPlugin.instance == null) {
      ActivityPlugin.instance = new ActivityPlugin(registrar, registrar.activity());
    }
  }

  ActivityPlugin(PluginRegistry.Registrar registrar, @NonNull Activity activity) {
    this.activity = activity;
    this.registrar = registrar;
    channel = new MethodChannel(registrar.messenger(), "activity");
    channel.setMethodCallHandler(this);
    eventChannel = new EventChannel(registrar.messenger(), "activity/event");
    eventChannel.setStreamHandler(this);

    registrar.addNewIntentListener(this);
    onIntent(registrar.activity().getIntent());
  }

  @Override
  public boolean onNewIntent(Intent intent) {
    return onIntent(intent);
  }

  /// onCreate() => constructor
  /// onNewIntent()
  public boolean onIntent(Intent intent) {
    if (eventReceiver != null) {
      eventReceiver.onReceive(registrar.context(), intent);
    }
    return false;
  }

  @Override
  public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
    result.notImplemented();
  }

  @Override
  public void onListen(Object o, EventChannel.EventSink eventSink) {
    eventReceiver = newReceiver(eventSink);
    // sends current intent once listens
    onIntent(registrar.activity().getIntent());
  }

  @Override
  public void onCancel(Object o) {
    eventReceiver = null;
  }

  public static BroadcastReceiver newReceiver(final EventChannel.EventSink sink) {
    return new BroadcastReceiver() {
      @Override
      public void onReceive(Context context, Intent intent) {
        Log.d("ActivityPlugin", "eventReceiver: onReceive");
        final Bundle extras = intent.getExtras();
        if (extras != null) {
          final Map<String, Object> map = toMap(extras);
          Log.d("ActivityPlugin", "eventReceiver: " + map);
          try {
            sink.success(map);
          } catch (Throwable e) {
            e.printStackTrace();
          }
        }
      }
    };
  }


  /*
  @RequiresApi(api = Build.VERSION_CODES.KITKAT)
  public static JSONObject toJson(@NonNull Bundle bundle) {
    JSONObject json = new JSONObject();
    Set<String> keys = bundle.keySet();
    for (String key : keys) {
      try {
        json.put(key, JSONObject.wrap(bundle.get(key)));
      } catch (JSONException e) {
          // nothing
      }
    }
    return json;
  }
  */

  public static Map<String, Object> toMap(@NonNull Bundle bundle) {
    Set<String> keys = bundle.keySet();
    Map<String, Object> map = new HashMap<>();
    for (String key : keys) {
      final Object value = bundle.get(key);
      if (value != null) {
        map.put(key, value);
      }
    }
    return map;
  }
}
