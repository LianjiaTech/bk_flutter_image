package com.example.bk_flutter_image_example;

import android.os.Bundle;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    try {
      Class.forName("dalvik.system.CloseGuard")
          .getMethod("setEnabled", boolean.class)
          .invoke(null, true);
    } catch (ReflectiveOperationException e) {
      throw new RuntimeException(e);
    }
  }
}
