package com.bk.flutter.bk_texture_image;

import io.flutter.Log;

public final class BkLogger {
  private static final String TAG = "TextureImageLogger";
  private static final boolean DEVELOP = true;

  public static void i(Object msg) {
    if (DEVELOP) {
      android.util.Log.i(TAG, String.valueOf(msg));
    } else {
      Log.i(TAG, String.valueOf(msg));
    }
  }

  public static void d(Object msg) {
    if (DEVELOP) {
      android.util.Log.d(TAG, String.valueOf(msg));
    } else {
      Log.d(TAG, String.valueOf(msg));
    }
  }

  public static void v(Object msg) {
    if (DEVELOP) {
      android.util.Log.v(TAG, String.valueOf(msg));
    } else {
      Log.v(TAG, String.valueOf(msg));
    }
  }

  public static void e(Object msg) {
    if (DEVELOP) {
      android.util.Log.e(TAG, String.valueOf(msg));
    } else {
      Log.e(TAG, String.valueOf(msg));
    }
  }

}
