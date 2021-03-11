package com.bk.flutter.bk_texture_image;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.MethodCall;

public class BkCallArgs {

  MethodCall call;
  String url;
  int width;
  int height;
  int imageFitMode;
  boolean autoResize;

  long textureId;

  public BkCallArgs(@NonNull MethodCall call) {
    this.call = call;
    this.url = call.argument("url");

    if (call.argument("width") != null) {
      double w = call.argument("width");
      this.width = (int) w;
    }

    if (call.argument("height") != null) {
      double h = call.argument("height");
      this.height = (int) h;
    }

    if (call.argument("imageFitMode") != null) {
      this.imageFitMode = call.argument("imageFitMode");
    }

    if (call.argument("autoResize") != null) {
      this.autoResize = call.argument("autoResize");
    }

  }

  public long getTextureId() {
    return textureId;
  }

  public void setTextureId(long textureId) {
    this.textureId = textureId;
  }

  public String uniqueKey() {
    return String.valueOf(url);
  }

  @Override
  public String toString() {
    return "CallArgs{" +
        "url='" + url + '\'' +
        ", width=" + width +
        ", height=" + height +
        ", imageFitMode=" + imageFitMode +
        ", autoResize=" + autoResize +
        ", textureId=" + textureId +
        '}';
  }
}
